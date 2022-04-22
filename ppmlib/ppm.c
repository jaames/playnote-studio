#include "ppm.h"
#include "platform.h"

ppm_ctx_t* ppmNew()
{
	ppm_ctx_t* ctx = pd_malloc(sizeof(ppm_ctx_t));

	ctx->videoOffsets = NULL;
	ctx->videoData = NULL;
	ctx->audioFrames = NULL;
	ctx->bgmData = NULL;

	for (u8 i = 0; i < PPM_SE_CHANNELS; i++)
		ctx->seData[i] = NULL;

	for (u8 i = 0; i < PPM_LAYERS; i++)
	{
		ctx->layers[i]     = pd_calloc(PPM_BUFFER_SIZE, 1);
		ctx->prevLayers[i] = pd_calloc(PPM_BUFFER_SIZE, 1);
	}

	ctx->prevFrame = -1;

	return ctx;
}

int ppmOpen(ppm_ctx_t* ctx, const char* filePath)
{
	SDFile* file;
	int readResult;

	ctx->file = file;
	ctx->filePath = filePath;

	file = pd->file->open(filePath, kFileRead | kFileReadData);
	if (file == NULL)
	{
		const char* err = pd->file->geterr();
		pd_error("Error opening %s: %s", filePath, err);
		pd->lua->pushNil();
		return 0;
	}

	readResult = pd->file->read(file, &ctx->hdr, sizeof(ppm_header_t));
	ctx->hdr.numFrames++;
	if (readResult < 1)
	{
		if (readResult == -1) {
			const char* err = pd->file->geterr();
			pd_error("Error reading header %s: %s", filePath, err);
			pd->lua->pushNil();
			return 1;
		}
		pd->lua->pushNil();
		return 2;
	}
	if (strncmp(ctx->hdr.magic, "PARA", 4) != 0)
	{
		pd_error("Invalid PPM magic");
		pd->lua->pushNil();
		return 3;
	}

	readResult = pd->file->read(file, ctx->thumbnail, sizeof(ctx->thumbnail));
	if (readResult < 1)
	{
		if (readResult == -1) {
			const char* err = pd->file->geterr();
			pd_error("Error reading thumbnail %s: %s", filePath, err);
			pd->lua->pushNil();
			return 4;
		}
		pd->lua->pushNil();
		return 5;
	}

	readResult = pd->file->read(file, &ctx->animHdr, sizeof(ppm_animation_header_t));
	if (readResult < 1)
	{
		if (readResult == -1) {
			const char* err = pd->file->geterr();
			pd_error("Error reading animation header %s: %s", filePath, err);
			pd->lua->pushNil();
			return 6;
		}
		pd->lua->pushNil();
		return 7;
	}

	ctx->videoOffsets = pd_malloc(sizeof(u32) * ctx->hdr.numFrames);
	readResult = pd->file->read(file, ctx->videoOffsets, sizeof(u32) * ctx->hdr.numFrames);
	if (readResult < 1)
	{
		pd_free(ctx->videoOffsets);
		if (readResult == -1) {
			const char* err = pd->file->geterr();
			pd_error("Error reading animation frame offsets %s: %s", filePath, err);
			pd->lua->pushNil();
			return 8;
		}
		pd->lua->pushNil();
		return 9;
	}

	ctx->videoData = pd_malloc(ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames));
	readResult = pd->file->read(file, ctx->videoData, ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames));
	if (readResult < 1)
	{
		ppmDone(ctx);
		if (readResult == -1) {
			const char* err = pd->file->geterr();
			pd_error("Error reading animation frame data %s: %s", filePath, err);
			pd->lua->pushNil();
			return 10;
		}
		pd->lua->pushNil();
		return 11;
	}

	ctx->audioFrames = pd_malloc(ctx->hdr.numFrames);
	readResult = pd->file->read(file, ctx->audioFrames, ctx->hdr.numFrames);
	if (readResult < 1)
	{
		ppmDone(ctx);
		if (readResult == -1) {
			const char* err = pd->file->geterr();
			pd_error("Error reading sound effect flags %s: %s", filePath, err);
			pd->lua->pushNil();
			return 12;
		}
		pd->lua->pushNil();
		return 13;
	}

	pd->file->seek(file, ROUND_UP_4(pd->file->tell(file)), SEEK_SET);

	readResult = pd->file->read(file, &ctx->sndHdr, sizeof(ppm_sound_header_t));
	if (readResult < 1)
	{
		ppmDone(ctx);
		if (readResult == -1) {
			const char* err = pd->file->geterr();
			pd_error("Error reading sound headers %s: %s", filePath, err);
			pd->lua->pushNil();
			return 14;
		}
		pd->lua->pushNil();
		return 15;
	}
	
	ctx->bgmData = pd_malloc(ctx->sndHdr.bgmLength);
	readResult = pd->file->read(file, ctx->bgmData, ctx->sndHdr.bgmLength);
	if (readResult < 0 || readResult != ctx->sndHdr.bgmLength)
	{
		ppmDone(ctx);
		const char* err = pd->file->geterr();
		pd_error("Error reading bgm data %s: %s", filePath, err);
		pd->lua->pushNil();
		return 16;
	}

	for (u8 i = 0; i < PPM_SE_CHANNELS; i++)
	{
		ctx->seData[i] = pd_malloc(ctx->sndHdr.seLength[i]);
		readResult = pd->file->read(file, ctx->seData[i], ctx->sndHdr.seLength[i]);
		if (readResult < 0 || readResult != ctx->sndHdr.seLength[i])	break;
	}
	if (readResult < 0)
	{
		ppmDone(ctx);
		const char* err = pd->file->geterr();
		pd_error("Error reading sound effect data %s: %s", filePath, err);
		pd->lua->pushNil();
		return 17;
	}

	ctx->frameRate    = speedTable[8 - ctx->sndHdr.playbackSpeed];
	ctx->bgmFrameRate = speedTable[8 - ctx->sndHdr.recordedSpeed];

	pd->file->close(file);
	ctx->file = NULL;
	ctx->filePath = NULL;
	
	return -1;
}

// char* ppmFormatId(u8 fsid[8])
// {
// 	static char str[32];
// 	memset(str, 0, 32);
	
// 	for(int i = 7; i >= 0; i--)
// 		sprintf(str, "%s%02X", str, (fsid[i] & 0xFF));

// 	return str;
// }

void ppmDone(ppm_ctx_t* ctx)
{
	if (ctx->videoOffsets != NULL)
	{
		pd_free(ctx->videoOffsets);
		ctx->videoOffsets = NULL;
	}

	if (ctx->videoData != NULL)
	{
		pd_free(ctx->videoData);
		ctx->videoData = NULL;
	}

	if (ctx->audioFrames != NULL)
	{
		pd_free(ctx->audioFrames);
		ctx->audioFrames = NULL;
	}

	if (ctx->bgmData != NULL)
	{
		pd_free(ctx->bgmData);
		ctx->bgmData = NULL;
	}

	for (u8 i = 0; i < PPM_SE_CHANNELS; i++)
	{
		if (ctx->seData[i] != NULL)
		{
			pd_free(ctx->seData[i]);
			ctx->seData[i] = NULL;
		}
	}

	for (u8 i = 0; i < PPM_LAYERS; i++)
	{
		pd_free(ctx->layers[i]);
		pd_free(ctx->prevLayers[i]);
	}
}