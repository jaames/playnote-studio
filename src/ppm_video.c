#include "ppm_video.h"

// seems to be a tiny bit faster than memcpy for filling layer buffers
static void setChunks(void* ptr, u32 c, size_t n)
{
	u32* p = ptr;
	while(n > 0) {
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

	ctx->paperColour = ppmPaperPalette[hdr.paperColour];

	ctx->layerColours[0] = ppmPenPalette[hdr.layer1Colour];
	ctx->layerColours[1] = ppmPenPalette[hdr.layer2Colour];

	/* If 1, the pen's colour is opposite to the paper's. */
	for (u8 layer = 0; layer < LAYERS; layer++)
	{
		if (ctx->layerColours[layer] == 1)
			ctx->layerColours[layer] = ppmPaperPalette[!hdr.paperColour];
	}

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
						for (u8 px = 0; px < 8; px++)
							ctx->layers[layer][px + offset] = (*data >> px) & 1;

						data++;
					}

					offset += 8;
				}

				break;

			case 3: /* Not compressed, read raw 1-bit line. */
				while (offset < (line + 1u) * SCREEN_WIDTH)
				{
					for (u8 px = 0; px < 8; px++)
						ctx->layers[layer][px + offset] = (*data >> px) & 1;

					data++;
					offset += 8;
				}

				break;
		}
	}

	/* If this frame isn't a keyframe, XOR with the previously decoded frame to fill in the missing pixels.
	   This also supports the ability to move frames to a different position if that flag is set. */
	if (!hdr.isKeyFrame)
	{
		register int src = 0;
		register int dst =  0;
		int yMin = MAX(0, moveByY);
		int yMax = MIN(SCREEN_HEIGHT - moveByY, SCREEN_HEIGHT);
		int xMin = MAX(0, moveByX);
		int xMax = MIN(SCREEN_WIDTH - moveByX, SCREEN_WIDTH);
		u8* layerA = ctx->layers[0];
		u8* layerB = ctx->layers[1];
		u8* layerAPrev = ctx->prevLayers[0];
		u8* layerBPrev = ctx->prevLayers[1];

		for (u16 y = yMin; y < yMax; y++)
		{
			for (u16 x = xMin; x < xMax; x++)
			{
				dst = PIXEL(x, y);
				src = dst - PIXEL(moveByX, moveByY);
				layerA[src] ^= layerAPrev[dst];
				layerB[src] ^= layerBPrev[dst];
			}
		}
	}
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