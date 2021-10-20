#include "ppm_video.h"

// seems to be a tiny bit faster than memcpy for filling layer buffers
static void setChunks(void* ptr, u32 c, size_t n)
{
	u32* p = ptr;
	while(n > 0) 
	{
		*p++ = c;
		n -= 4;
	}
}

void ppmVideoDecodeFrame(ppm_ctx_t *ctx, u16 frame)
{
	u8 *data;
	s8 moveByX, moveByY;
	u32 lineFlags, offset;
	u8 layerLines[LAYERS][SCREEN_HEIGHT];
	ppm_frame_header_t hdr;

	if (ctx->prevFrame == frame)
		return;

	/* If seeking backwards, decode previous frames until a keyframe is reached. */
	if (frame && ctx->prevFrame != frame - 1 &&
		!(*(ppm_frame_header_t *)&ctx->videoData[ctx->videoOffsets[frame]]).isKeyFrame)
		ppmVideoDecodeFrame(ctx, frame - 1);

	/* Copy the last decoded layer to the last, last decoded one. */
	for (u8 layer = 0; layer < LAYERS; layer++)
	{
		// swap layer buffer pointers instead of using memcpy
		u8* tmp = ctx->prevLayers[layer];
		ctx->prevLayers[layer] = ctx->layers[layer];
		ctx->layers[layer] = tmp;
		// zero-fill current layer buffers
		setChunks(ctx->layers[layer], 0, SCREEN_SIZE);
	}

	ctx->prevFrame = frame;

	data = &ctx->videoData[ctx->videoOffsets[frame]];

	hdr = *(ppm_frame_header_t *)&data[0];

	/* Do we move the frame? If so, read X and Y. */
	moveByX = hdr.doMove ? data[1] : 0;
	moveByY = hdr.doMove ? data[2] : 0;

	ctx->paperColour = hdr.paperColour;

	ctx->layerColours[0] = hdr.layer1Colour;
	ctx->layerColours[1] = hdr.layer2Colour;

	/* If 1, the pen's colour is opposite to the paper's. */
	/* Not needed, handled elsewhere when frame is drawn */
	// for (u8 layer = 0; layer < LAYERS; layer++)
	// {
	// 	if (ctx->layerColours[layer] == 1)
	// 		ctx->layerColours[layer] = !hdr.paperColour;
	// }

	data += hdr.doMove ? 3 : 1;

	/* Get 2-bit line flags. */
	for (u8 layer = 0; layer < LAYERS; layer++)
	{
		for (u8 byte = 0; byte < 48; byte++)
		{
			layerLines[layer][(byte * 4) + 0] = (data[byte] >> 0) & 3;
			layerLines[layer][(byte * 4) + 1] = (data[byte] >> 2) & 3;
			layerLines[layer][(byte * 4) + 2] = (data[byte] >> 4) & 3;
			layerLines[layer][(byte * 4) + 3] = (data[byte] >> 6) & 3;
		}

		data += 48;
	}

	/* Main decoding loop. */
	for (u8 layer = 0; layer < LAYERS;        layer++)
	for (u8 line  = 0; line  < SCREEN_HEIGHT; line++)
	{
		u8* layerBuffer = ctx->layers[layer];
		offset = line * SCREEN_WIDTH;

		switch (layerLines[layer][line])
		{
			case 2: /* Fill entire line with colour, then decompress. */
				setChunks(&layerBuffer[offset], 0x01010101, SCREEN_WIDTH);
			case 1: /* Decompress line. */
				lineFlags = __builtin_bswap32(*(u32 *)data);
				data += sizeof(u32);

				for (; lineFlags; lineFlags <<= 1)
				{
					if (lineFlags & 0x80000000)
					{
						layerBuffer[offset + 0] = (*data >> 0) & 1;
						layerBuffer[offset + 1] = (*data >> 1) & 1;
						layerBuffer[offset + 2] = (*data >> 2) & 1;
						layerBuffer[offset + 3] = (*data >> 3) & 1;
						layerBuffer[offset + 4] = (*data >> 4) & 1;
						layerBuffer[offset + 5] = (*data >> 5) & 1;
						layerBuffer[offset + 6] = (*data >> 6) & 1;
						layerBuffer[offset + 7] = (*data >> 7) & 1;
						data++;
					}

					offset += 8;
				}

				break;

			case 3: /* Not compressed, read raw 1-bit line. */
				while (offset < (line + 1u) * SCREEN_WIDTH)
				{
					layerBuffer[offset + 0] = (*data >> 0) & 1;
					layerBuffer[offset + 1] = (*data >> 1) & 1;
					layerBuffer[offset + 2] = (*data >> 2) & 1;
					layerBuffer[offset + 3] = (*data >> 3) & 1;
					layerBuffer[offset + 4] = (*data >> 4) & 1;
					layerBuffer[offset + 5] = (*data >> 5) & 1;
					layerBuffer[offset + 6] = (*data >> 6) & 1;
					layerBuffer[offset + 7] = (*data >> 7) & 1;
					data++;
					offset += 8;
				}

				break;
		}
	}

	/* If this frame isn't a keyframe, XOR with the previously decoded frame to fill in the missing pixels. */

	/* Faster branch for if the frame isn't translated, XOR multiple pixels at once,
	   interestingly doing u64 XORs seems to be slightly faster than u32, even though the playdate is 32-bit!
	 */
	if (!hdr.isKeyFrame && moveByY == 0 && moveByX == 0)
	{
		u64* layerA = (u64*)ctx->layers[0];
		u64* layerB = (u64*)ctx->layers[1];
		u64* prevLayerA = (u64*)ctx->prevLayers[0];
		u64* prevLayerB = (u64*)ctx->prevLayers[1];
		for (u16 i = 0; i < SCREEN_SIZE / sizeof(u64); i++)
		{
			layerA[i] ^= prevLayerA[i];
			layerB[i] ^= prevLayerB[i];
		}
	}
	/* 
	   Otherwise the frame is translated and we need to take that into account
	   This is a bit ugly, but the gist here is to try to reduce the amount of calculations happening per pixel, since this was causing a lot of slowdown
	 */
	else if (!hdr.isKeyFrame)
	{
		u8* layerA = ctx->layers[0];
		u8* layerB = ctx->layers[1];
		u8* prevLayerA = ctx->prevLayers[0];
		u8* prevLayerB = ctx->prevLayers[1];
		int src = 0;
		int dst = 0;
		for (u16 y = 0; y < SCREEN_HEIGHT; y++)
		{
			/* Vertical bounds check. */
			if (y - moveByY < 0) continue;
			if (y - moveByY >= SCREEN_HEIGHT) break;

			for (u16 x = 0; x < SCREEN_WIDTH; x++)
			{
				/* Horizontal bounds check. */
				if (x - moveByX < 0) continue;
				if (x - moveByX >= SCREEN_WIDTH) break;
				dst = PIXEL(x, y);
				src = dst - PIXEL(moveByX, moveByY);
				layerA[dst] ^= prevLayerA[src];
				layerB[dst] ^= prevLayerB[src];
			}
		}
	}
	// TODO: replace above with faster code once issues with brainslice test note are resolved
	// else if (!hdr.isKeyFrame)
	// {
	// 	u8* layerA = ctx->layers[0];
	// 	u8* layerB = ctx->layers[1];
	// 	u8* prevLayerA = ctx->prevLayers[0];
	// 	u8* prevLayerB = ctx->prevLayers[1];
	// 	u16 src = 0;
	// 	// translation offset is constant
	// 	u16 offs = PIXEL(moveByX, moveByY);
	// 	// pre calc x range, so we don't need to do it for each pixel
	// 	u16 xMin = MAX(moveByX, 0);
	// 	// u16 xMax = MIN(SCREEN_WIDTH - moveByX, SCREEN_WIDTH);

	// 	for (u16 y = MAX(moveByY, 0); y < SCREEN_HEIGHT; y++)
	// 	{
	// 		if (y - moveByY >= SCREEN_HEIGHT) break;
	// 		src = PIXEL(xMin, y);
	// 		for (u16 x = xMin; x < SCREEN_WIDTH; x++)
	// 		{
	// 			if (x - moveByX >= SCREEN_WIDTH) break;
	// 			layerA[src] ^= prevLayerA[src - offs];
	// 			layerB[src] ^= prevLayerB[src - offs];
	// 			src++;
	// 		}
	// 	}
	// }
}

int ppmVideoRenderFrame(ppm_ctx_t *ctx, u32 *out, u16 frame)
{
	if (frame >= ctx->hdr.numFrames)
		return 0;
	
	ppmVideoDecodeFrame(ctx, frame);

	for (u16 px = 0; px < SCREEN_SIZE; px++)
	{
		out[px] = ctx->paperColour;

		if (ctx->layers[1][px])
			out[px] = ctx->layerColours[1];

		if (ctx->layers[0][px])
			out[px] = ctx->layerColours[0];
	}
	
	return 1;
}