#include "ppm.h"
#include "platform.h"

static inline void closeWithError(ppm_ctx_t* ctx, const char* msg)
{
	if (ctx->lastError != NULL)
		pd_free(ctx->lastError);
	ctx->lastError = NULL;
	pd->system->formatString(&ctx->lastError, "Flipnote load error\n%s\n%s", ctx->filePath, msg);
	pd_log(ctx->lastError);
	ppmDone(ctx);
	pd->file->close(ctx->file);
	ctx->file = NULL;
	ctx->filePath = NULL;
}

static int errorHandledFileRead(ppm_ctx_t* ctx, void* buf, unsigned int len, const char* errorMsg)
{
	int res = pd->file->read(ctx->file, buf, len);
	if (res == -1)
	{
		const char* fileErr = pd->file->geterr();
		char* err = NULL;
		pd->system->formatString(&err, "%s\n%s", errorMsg, fileErr);
		closeWithError(ctx, err);
		return -1;
	}
	else if (len > 0 && res != len)
	{
		closeWithError(ctx, errorMsg);
		return -1;
	}
	return 0;
}

ppm_ctx_t* ppmNew()
{
	ppm_ctx_t* ctx = pd_malloc(sizeof(ppm_ctx_t));

	ctx->prevFrame = -1;

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

	ctx->file = NULL;
	ctx->filePath = NULL;
	ctx->lastError = NULL;

	return ctx;
}

char* ppmGetError(ppm_ctx_t* ctx)
{
	if (ctx->lastError != NULL)
		return ctx->lastError;
	else
		return "No error";
}

int ppmOpen(ppm_ctx_t* ctx, const char* filePath)
{
	SDFile* file;
	int readResult;

	file = pd->file->open(filePath, kFileRead | kFileReadData);
	if (file == NULL)
	{
		const char* fileErr = pd->file->geterr();
		char* err = NULL;
		pd->system->formatString(&err, "Couldn't open file (%s)", fileErr);
		closeWithError(ctx, err);
		return -1;
	}

	pd->file->seek(file, 0, SEEK_END);
	int size = pd->file->tell(file);
	pd->file->seek(file, 0, SEEK_SET);

	ctx->file = file;
	ctx->filePath = filePath;

	readResult = errorHandledFileRead(ctx, &ctx->hdr, sizeof(ppm_header_t), "Couldn't read header");
	ctx->hdr.numFrames++;
	if (readResult == -1)
		return -1;

	if (strncmp(ctx->hdr.magic, "PARA", 4) != 0)
	{
		closeWithError(ctx, "Invalid format");
		return -1;
	}

	readResult = errorHandledFileRead(ctx, ctx->thumbnail, sizeof(ctx->thumbnail), "Couldn't read thumbnail");
	if (readResult == -1)
		return -1;

	readResult = errorHandledFileRead(ctx, &ctx->animHdr, sizeof(ppm_animation_header_t), "Couldn't read anim header");
	if (readResult == -1)
		return -1;

	ctx->videoOffsets = pd_malloc(sizeof(u32) * ctx->hdr.numFrames);
	readResult = errorHandledFileRead(ctx, ctx->videoOffsets, sizeof(u32) * ctx->hdr.numFrames, "Couldn't read frame offsets");
	if (readResult == -1)
		return -1;

	ctx->videoData = pd_malloc(ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames));
	readResult = errorHandledFileRead(ctx, ctx->videoData, ctx->hdr.animationLength - sizeof(ppm_animation_header_t) - (sizeof(u32) * ctx->hdr.numFrames), "Couldn't read frame data");
	if (readResult == -1)
		return -1;

	ctx->audioFrames = pd_malloc(ctx->hdr.numFrames);
	readResult = errorHandledFileRead(ctx, ctx->audioFrames, ctx->hdr.numFrames, "Couldn't read sfx flags");
	if (readResult == -1)
		return -1;

	pd->file->seek(file, ROUND_UP_4(pd->file->tell(file)), SEEK_SET);

	readResult = errorHandledFileRead(ctx, &ctx->sndHdr, sizeof(ppm_sound_header_t), "Couldn't read sound header");
	if (readResult == -1)
		return -1;
	
	ctx->bgmData = pd_malloc(ctx->sndHdr.bgmLength);
	readResult = errorHandledFileRead(ctx, ctx->bgmData, ctx->sndHdr.bgmLength, "Couldn't read bgm data");
	if (readResult == -1)
		return -1;

	for (u8 i = 0; i < PPM_SE_CHANNELS; i++)
	{
		ctx->seData[i] = pd_malloc(ctx->sndHdr.seLength[i]);
		readResult = errorHandledFileRead(ctx, ctx->seData[i], ctx->sndHdr.seLength[i], "Couldn't read sfx data");
		if (readResult == -1)
			return -1;
	}

	// last part of the ppm is a 128-byte signature followed by 16 null padding bytes
	if (pd->file->tell(file) != size - 128 - 16)
	{
		closeWithError(ctx, "Invalid PPM size");
		return -1;
	}

	ctx->frameRate    = speedTable[8 - ctx->sndHdr.playbackSpeed];
	ctx->bgmFrameRate = speedTable[8 - ctx->sndHdr.recordedSpeed];
	
	// test error handling
	// closeWithError(ctx, "Something dun goofed");
	// return -1;

	pd->file->close(file);
	ctx->file = NULL;
	ctx->filePath = NULL;
	return 0;
}

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
		if (ctx->layers[i] != NULL)
		{
			pd_free(ctx->layers[i]);
			ctx->layers[i] = NULL;
		}
		if (ctx->prevLayers[i] != NULL)
		{
			pd_free(ctx->prevLayers[i]);
			ctx->prevLayers[i] = NULL;
		}
	}
}