#include "audio.h"
#include "platform.h"

/* 
	Builds diffTable for all possible stepIndex and sample combinations,
	seems to help improve load times on the Playdate quite a bit!
	This should only be called when registering the ppm libray
*/
void ppmAudioRegister()
{
	s16 step;
	int diff;
	for (u16 stepIndex = 0; stepIndex < 89; stepIndex++)
	{
		step = stepTable[stepIndex];
		for (u16 sample = 0; sample < 16; sample++)
		{
			diff = step >> 3;
			if (sample & 1) diff += step >> 2;
			if (sample & 2) diff += step >> 1;
			if (sample & 4) diff += step;
			if (sample & 8) diff = -diff;
			diffTable[stepIndex][sample] = diff;
		}
	}
}

/* Decodes an IMA-ADPCM sample to a PCM-16 one. */
static s16 ppmAudioDecodeSample(u8 sample)
{
	predictor += diffTable[stepIndex][sample];
	CLAMP(predictor, -32768, 32767);

	stepIndex += indexTable[sample & 7];
	CLAMP(stepIndex, 0, 88);

	return (s16)predictor;
}

/* Decodes a raw IMA-ADPCM buffer to PCM-16. */
void ppmAudioDecodeBuffer(const u8* in, s16* out, u32 length)
{
	predictor = 0;
	stepIndex = 0;

	while (length--)
	{
		*out++ = ppmAudioDecodeSample(*in  & 0xF);
		*out++ = ppmAudioDecodeSample(*in++ >> 4);
	}
}

/* Zero-order hold interpolation + volume adjustment. */
void ppmAudioProcess(const s16* in, s16* out, u32 samples, u32 srcFreq, int add)
{
	const u32 adjFreq = (srcFreq << 8) / OUTPUT_SAMPLE_RATE;

	for (u32 n = 0; n < samples; n++)
	{
		/* Find closest sample match and halve its volume. */
		s32 samp = in[(n * adjFreq) >> 8] / 2;

		/* If specified, add to the sample instead of replacing it. */
		if (add)
			samp += out[n];

		/* Clip output to lessen distortion. */
		CLAMP(samp, -32768, 32767);
		
		out[n] = samp;
	}
}

u32 ppmAudioNumSamples(ppm_ctx_t* ctx)
{
	return ctx->hdr.numFrames * (u32)round(SAMPLE_RATE / ctx->frameRate) * 4;
}

void ppmAudioRender(ppm_ctx_t* ctx, s16* out, int maxSize)
{
	u32 samplesPerFrame, bgmSampleRate;
	u32 trackLengths[4];
	s16* bgm, *se[3];

	/* Calculate the number of audio samples to render per frame. */
	samplesPerFrame = (u32)round(SAMPLE_RATE / ctx->frameRate);

	/* Calculate adjusted sample rate for BGM track. */
	bgmSampleRate   = (u32)round((ctx->frameRate / ctx->bgmFrameRate) * SAMPLE_RATE);

	/* 4-bit -> 16-bit, so multiply by 4. */
	trackLengths[0] = ctx->sndHdr.bgmLength   * 4;
	trackLengths[1] = ctx->sndHdr.seLength[0] * 4;
	trackLengths[2] = ctx->sndHdr.seLength[1] * 4;
	trackLengths[3] = ctx->sndHdr.seLength[2] * 4;

	/* Allocate memory for decoded PCM. */
	bgm   = pd_malloc(trackLengths[0]);
	se[0] = pd_malloc(trackLengths[1]);
	se[1] = pd_malloc(trackLengths[2]);
	se[2] = pd_malloc(trackLengths[3]);
	memset(bgm, 0, trackLengths[0]);
	memset(se[0], 0, trackLengths[1]);
	memset(se[1], 0, trackLengths[2]);
	memset(se[2], 0, trackLengths[3]);

	/* Decode all ADPCM buffers into PCM. */
	ppmAudioDecodeBuffer(ctx->bgmData,   bgm,   ctx->sndHdr.bgmLength);
	ppmAudioDecodeBuffer(ctx->seData[0], se[0], ctx->sndHdr.seLength[0]);
	ppmAudioDecodeBuffer(ctx->seData[1], se[1], ctx->sndHdr.seLength[1]);
	ppmAudioDecodeBuffer(ctx->seData[2], se[2], ctx->sndHdr.seLength[2]);

	/* Render BGM, interpolate to 32,768Hz. */
	if (ctx->sndHdr.bgmLength)
	{
		/* TODO: Make this less disgusting. */
		ppmAudioProcess(
			bgm,
			out,
			min(ppmAudioNumSamples(ctx), (u32)((trackLengths[0] / 2) * ((float)OUTPUT_SAMPLE_RATE / (float)bgmSampleRate))),
			bgmSampleRate,
			0
		);
	}

	/* We don't need this anymore. */
	pd_free(bgm);

	/* Render all sound effects. */
	for (u16 frame = 0; frame < ctx->hdr.numFrames; frame++)
	{
		int soundOffset = samplesPerFrame * frame * 4;
		// don't allow sound effects to be written after maxSize
		if (soundOffset >= maxSize)
			break;

		for (u8 ch = 0; ch < PPM_SE_CHANNELS; ch++)
		{
			if ((ctx->audioFrames[frame] >> ch) & 1)
			{
				ppmAudioProcess(
					se[ch],
					out + soundOffset,
					min(samplesPerFrame * (ctx->hdr.numFrames - frame) * 4, (trackLengths[ch + 1] / sizeof(s16)) * 4),
					SAMPLE_RATE,
					1
				);
			}
		}
	}

	/* We don't need these anymore either. */
	pd_free(se[0]);
	pd_free(se[1]);
	pd_free(se[2]);
}