#include "ppm.h"
#include "platform.h"

int ppmInit(ppm_ctx_t* ctx, u8* ppm, int len)
{
	u8* start = ppm;
	
	if (len < sizeof(ppm_header_t))
		return 0;

	memcpy(&ctx->hdr, ppm, sizeof(ppm_header_t));
	ppm += sizeof(ppm_header_t);
	
	if (strncmp(ctx->hdr.magic, "PARA", 4) != 0)
	{
		pd_log("Invalid PPM magic");
		return 1;
	}

	if (ppm - start + sizeof(ctx->thumbnail) >= len)
	{
		pd_log("PPM too small for thumbnail data size");
		return 2;
	}

	memcpy(ctx->thumbnail, ppm, sizeof(ctx->thumbnail));
	ppm += sizeof(ctx->thumbnail);
	
	if (ppm - start + sizeof(ppm_animation_header_t) >= len)
	{
		pd_log("PPM too small for expected animation header");
		return 3;
	}
	
	memcpy(&ctx->animHdr, ppm, sizeof(ppm_animation_header_t));
	ppm += sizeof(ppm_animation_header_t);

	ctx->hdr.numFrames++;

	if (ppm - start + (sizeof(u32) * ctx->hdr.numFrames) >= len)
	{
		pd_log("PPM too small for expected frame table size");
		return 4;
	}

	ctx->videoOffsets = pd_malloc(sizeof(u32) * ctx->hdr.numFrames);
	memcpy(ctx->videoOffsets, ppm, sizeof(u32) * ctx->hdr.numFrames);
	ppm += sizeof(u32) * ctx->hdr.numFrames;
	
	if (ppm - start + ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames) >= len)
	{
		pd_free(ctx->videoOffsets);	
		pd_log("PPM too small for expected frame data size");
		return 5;
	}
	
	ctx->videoData = pd_malloc(ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames));
	memcpy(ctx->videoData, ppm, ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames));
	ppm += ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames);

	if (ppm - start + ctx->hdr.numFrames >= len)
	{
		pd_free(ctx->videoOffsets);
		pd_free(ctx->videoData);	
		pd_log("PPM too small for expected sound effect flag data size");
		return 6;
	}
	
	ctx->audioFrames = pd_malloc(ctx->hdr.numFrames);
	memcpy(ctx->audioFrames, ppm, ctx->hdr.numFrames);
	ppm += ctx->hdr.numFrames;

	ppm = (u8*)ROUND_UP_4((long int)ppm);

	if (ppm - start + sizeof(ppm_sound_header_t) >= len)
	{
		pd_free(ctx->videoOffsets);
		pd_free(ctx->videoData);
		pd_free(ctx->audioFrames);
		pd_log("PPM too small for sound header size");
		return 7;
	}

	memcpy(&ctx->sndHdr, ppm, sizeof(ppm_sound_header_t));
	ppm += sizeof(ppm_sound_header_t);

	if (ppm - start + ctx->sndHdr.bgmLength >= len)
	{
		pd_free(ctx->videoOffsets);
		pd_free(ctx->videoData);
		pd_free(ctx->audioFrames);
		pd_log("PPM too small for expected bgm data size");
		return 8;
	}
	
	ctx->bgmData = pd_malloc(ctx->sndHdr.bgmLength);
	memcpy(ctx->bgmData, ppm, ctx->sndHdr.bgmLength);

	if (ppm - start + ctx->sndHdr.seLength[0] + ctx->sndHdr.seLength[1] + ctx->sndHdr.seLength[2] >= len)
	{
		pd_free(ctx->videoOffsets);
		pd_free(ctx->videoData);
		pd_free(ctx->audioFrames);
		pd_free(ctx->bgmData);
		pd_log("PPM too small for expected sound effect data size");
		return 9;
	}

	for (u8 i = 0; i < PPM_SE_CHANNELS; i++)
	{
		ctx->seData[i] = pd_malloc(ctx->sndHdr.seLength[i]);
		memcpy(ctx->seData[i], ppm, ctx->sndHdr.seLength[i]);
	}

	for (u8 i = 0; i < PPM_LAYERS; i++)
	{
		ctx->layers[i]     = pd_calloc(PPM_BUFFER_SIZE, 1);
		ctx->prevLayers[i] = pd_calloc(PPM_BUFFER_SIZE, 1);
	}

	ctx->prevFrame = -1;

	ctx->frameRate    = speedTable[8 - ctx->sndHdr.playbackSpeed];
	ctx->bgmFrameRate = speedTable[8 - ctx->sndHdr.recordedSpeed];
	
	return -1;
}

// char* fsidFromStr(u8 fsid[8])
// {
// 	static char str[32];
// 	memset(str, 0, 32);
	
// 	for(int i = 7; i >= 0; i--)
// 		sprintf(str, "%s%02X", str, (fsid[i] & 0xFF));

// 	return str;
// }

void ppmDone(ppm_ctx_t* ctx)
{
	pd_free(ctx->audioFrames);

	pd_free(ctx->videoOffsets);

	pd_free(ctx->bgmData);

	for (u8 i = 0; i < PPM_SE_CHANNELS; i++)
		pd_free(ctx->seData[i]);

	pd_free(ctx->videoData);

	for (u8 i = 0; i < PPM_LAYERS; i++)
	{
		pd_free(ctx->layers[i]);
		pd_free(ctx->prevLayers[i]);
	}
}