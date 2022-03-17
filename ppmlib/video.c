#include "video.h"
#include "platform.h"

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

void ppmVideoDecodeFrame(ppm_ctx_t* ctx, u16 frame, int preventDecodingPrev)
{
	u8* data;
	s8 moveByX, moveByY;
	u32 lineFlags, offset;
	u8 layerLines[PPM_LAYERS][PPM_SCREEN_HEIGHT];
	ppm_frame_header_t hdr;

	if (ctx->prevFrame == frame)
		return;

	/* 
		If seeking backwards, decode previous frames until a keyframe is reached.

		I would normally do this recursively, but that was causing a stack overflow on the Playdate,
		doing a loop back to the most recent keyframe and then decoding forward from there seems to work!
	 */
	if (preventDecodingPrev == 0 && ctx->prevFrame != frame - 1)
	{
		int backFrame = frame;
		
		while (frame && !(*(ppm_frame_header_t*)&ctx->videoData[ctx->videoOffsets[backFrame]]).isKeyFrame)
			backFrame--;
		
		for(; backFrame < frame; backFrame++)
			ppmVideoDecodeFrame(ctx, backFrame, 1);
	}

	/* Copy the last decoded layer to the last, last decoded one. */
	for (u8 layer = 0; layer < PPM_LAYERS; layer++)
	{
		/* swap layer buffer pointers instead of using memcpy */
		u8* tmp = ctx->prevLayers[layer];
		ctx->prevLayers[layer] = ctx->layers[layer];
		ctx->layers[layer] = tmp;
		/* zero-fill current layer buffers */
		setChunks(ctx->layers[layer], 0, PPM_BUFFER_SIZE);
	}

	ctx->prevFrame = frame;

	data = &ctx->videoData[ctx->videoOffsets[frame]];

	hdr = *(ppm_frame_header_t* )&data[0];

	/* Do we move the frame? If so, read X and Y. */
	moveByX = hdr.doMove ? data[1] : 0;
	moveByY = hdr.doMove ? data[2] : 0;

	ctx->paperColour = hdr.paperColour;

	ctx->layerColours[0] = hdr.layer1Colour;
	ctx->layerColours[1] = hdr.layer2Colour;

	data += hdr.doMove ? 3 : 1;

	/* Get 2-bit line flags. */
	for (u8 layer = 0; layer < PPM_LAYERS; layer++)
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
	for (u8 layer = 0; layer < PPM_LAYERS;        layer++)
	for (u8 line  = 0; line  < PPM_SCREEN_HEIGHT; line++)
	{
		u8* layerBuffer = ctx->layers[layer];
		offset = line * 32;

		switch (layerLines[layer][line])
		{
			case 2: /* Fill entire line with colour, then decompress as type 1. */
				setChunks(&layerBuffer[offset], 0xFFFFFFFF, PPM_BUFFER_STRIDE);

			case 1: /* Decompress line. */
				lineFlags = __builtin_bswap32(*(u32 *)data);
				data += sizeof(u32);

				for (; lineFlags; lineFlags <<= 1)
				{
					if (lineFlags & 0x80000000)
					{
						layerBuffer[offset] = *data;
						data++;
					}
					offset++;
				}
				break;

			case 3: /* Not compressed, read raw 1-bit line. */
				while (offset < (line + 1u) * PPM_BUFFER_STRIDE)
				{
					layerBuffer[offset++] = *data;
					data++;
				}
				break;
		}
	}

	/* 
		If this frame isn't a keyframe, it must be combined with the prev frame by XORing each pixel.
		Since the Flipnote devs decided that sometimes translating the previous frame by arbitrary
		(x, y) values makes sense for some reason, some gnarly bitwise stuff has to be involved. 
		This is by far the largest performance bottleneck, so there's multiple combination routines to try
		to do the least amount of work depending on the translation needed.

		I promise that the performance benefits of keeping 1-bit pixel buffers all the way through are 
		absolutely worth it, decoding is some 2x faster on Playdate hardware, at least!

		Additionally, I'd like to formally apologize for the absolutely insulting code that you are 
		about to whitness - please do not judge Simon by it, for I am the one culpable.
		I shall carry the shame to my deathbed.
	*/
	if (!hdr.isKeyFrame)
	{
		/*
			If the x axis hasn't been translated, it's easy to XOR a series of pixels at once
			interestingly doing u64 XORs seems to be slightly faster than u32, even though the playdate is 32-bit?
		*/
		if (moveByX == 0)
		{
			u64* layerA = (u64*)ctx->layers[0];
			u64* layerB = (u64*)ctx->layers[1];
			u64* prevLayerA = (u64*)ctx->prevLayers[0];
			u64* prevLayerB = (u64*)ctx->prevLayers[1];
			/* 
				If the frame isn't translated at all, which is the most common case, do a simple loop
			*/
			if (moveByY == 0)
			{
				for (u16 i = 0; i < PPM_BUFFER_SIZE / sizeof(u64); i++)
				{
					layerA[i] ^= prevLayerA[i];
					layerB[i] ^= prevLayerB[i];
				}
			}
			/* 
				Otherwise swap rows and just do those 64 pixels at a time
			*/
			else
			{
				int startY = MAX(moveByY, 0);
				int endY = MIN(PPM_SCREEN_HEIGHT + moveByY, PPM_SCREEN_HEIGHT);
				int stride = PPM_BUFFER_STRIDE / sizeof(u64);
				int src = 0;
				int dst = 0;
				for (u16 y = startY; y < endY; y++)
				{
					dst = y * stride;
					src = (y - moveByY) * stride;
					for (u8 c = 0; c < stride; c++)
					{
						layerA[dst] ^= prevLayerA[src];
						layerB[dst] ^= prevLayerB[src];
						dst++;
						src++;
					}
				}
			}
		}
		/* 
			If we're moving right on the X axis, with an arbitrary Y translation
		*/
		else if (moveByX > 0)
		{
			u8* layerA = ctx->layers[0];
			u8* layerB = ctx->layers[1];
			u8* prevLayerA = ctx->prevLayers[0];
			u8* prevLayerB = ctx->prevLayers[1];
			int startY = moveByY;
			int endY = MIN(PPM_SCREEN_HEIGHT + moveByY, PPM_SCREEN_HEIGHT);
			int lineStart = moveByX / 8;
			int lineEnd = MIN(PPM_BUFFER_STRIDE + lineStart, PPM_BUFFER_STRIDE);
			int xMod = moveByX % 8;
			int src = 0;
			int dst = 0;
			/* subtract this from dst to get the value for src */
			int shift = moveByY * PPM_BUFFER_STRIDE + lineStart;
			for (u16 y = startY; y < endY; y++)
			{
				/* prevent wrapping to the other side of the frame if we're at the left edge */
				if (lineStart == 0)
				{
					dst = y * PPM_BUFFER_STRIDE;
					src = dst - shift;
					layerA[dst] ^= (prevLayerA[src] << xMod);
					layerB[dst] ^= (prevLayerB[src] << xMod);
				}
				/*
				 shift everything one spot to the right
				 we need to check two bytes from the prev layer buffer and do some bit wrangling,
				 since translation values are not guaranteed to be multiples of 8
				*/
				for (u8 c = lineStart + 1; c < lineEnd; c++)
				{
					dst = y * PPM_BUFFER_STRIDE + c;
					src = dst - shift;
					layerA[dst] ^= (prevLayerA[src] << xMod) | (prevLayerA[src - 1] >> (8 - xMod));
					layerB[dst] ^= (prevLayerB[src] << xMod) | (prevLayerB[src - 1] >> (8 - xMod));
				}
			}
		}
		/* 
			If we're moving left on the X axis, with an arbitrary Y translation

			TODO: test this
		*/
		else if (moveByX < 0)
		{
			pd_log("HEY! untested x left-shift on frame (%d)", frame + 1);
			u8* layerA = ctx->layers[0];
			u8* layerB = ctx->layers[1];
			u8* prevLayerA = ctx->prevLayers[0];
			u8* prevLayerB = ctx->prevLayers[1];
			int startY = MAX(moveByY, 0);
			int endY = PPM_SCREEN_HEIGHT + moveByY;
			int lineStart = MAX(moveByX / 8, 0);
			int lineEnd = PPM_BUFFER_STRIDE + lineStart;
			int xMod = moveByX % 8;
			int src = 0;
			int dst = 0;
			/* subtract this from dst to get the value for src */
			int shift = moveByY * PPM_BUFFER_STRIDE + lineStart;
			for (u16 y = startY; y < endY; y++)
			{
				for (u8 c = lineStart; c < lineEnd - 1; c++)
				{
					dst = y * PPM_BUFFER_STRIDE + c;
					src = dst - shift;
					layerA[dst] ^= (prevLayerA[src] >> xMod) | (prevLayerA[src + 1] << (8 - xMod));
					layerB[dst] ^= (prevLayerB[src] >> xMod) | (prevLayerB[src + 1] << (8 - xMod));
				}
				/* prevent wrapping to the other side of the frame if we're at the right edge */
				if (lineEnd == PPM_BUFFER_STRIDE - 1)
				{
					dst = y * PPM_BUFFER_STRIDE;
					src = dst - shift;
					layerA[dst] ^= (prevLayerA[src] >> xMod);
					layerB[dst] ^= (prevLayerB[src] >> xMod);
				}
			}
		}
	}
}