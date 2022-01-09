#include <string.h>

#include "pd_api.h"

#include "ppmlib.h"
#include "platform.h"
#include "types.h"
#include "ppm.h"
#include "audio.h"
#include "video.h"
#include "tables.h"

static const lua_reg libPpm[];

void registerPpmlib()
{
	const char* err;

	if (!pd->lua->registerClass("PpmParser", libPpm, NULL, 0, &err))
	{
		pd_error("%s:%i: registering PPM lib failed, %s", __FILE__, __LINE__, err);
		return;
	}
}

static ppmlib_ctx* getPpmCtx(int n) 
{
	return pd->lua->getArgObject(n, "PpmParser", NULL);
}

static int ppm_new(lua_State* L)
{
	const char* filePath = pd->lua->getArgString(1);

	SDFile* f = pd->file->open(filePath, kFileRead | kFileReadData);

	pd->file->seek(f, 0, SEEK_END);
	int fsize = pd->file->tell(f);
	pd->file->seek(f, 0, SEEK_SET);

	u8* ppm = pd_malloc(fsize);
	pd->file->read(f, ppm, fsize);
	pd->file->close(f);

	ppmlib_ctx* ctx = pd_malloc(sizeof(ppmlib_ctx));
	ctx->ppm = pd_malloc(sizeof(ppm_ctx_t));
	int err = ppmInit(ctx->ppm, ppm, fsize);
	pd_free(ppm);

	if (err != -1)
	{
		pd_error("ppmInit error: %d", err);
		pd->lua->pushNil();
		return 1;
	}

	ctx->currentFrame = 0;
	ctx->numFrames = ctx->ppm->hdr.numFrames;
	ctx->loop = ctx->ppm->animHdr.flags.loop;

	ctx->layerPattern[0][0] = LUT_ppmDitherNone;
	ctx->layerPattern[0][1] = LUT_ppmDitherNone;
	ctx->layerPattern[0][2] = LUT_ppmDitherNone;
	ctx->layerPattern[1][0] = LUT_ppmDitherNone;
	ctx->layerPattern[1][1] = LUT_ppmDitherNone;
	ctx->layerPattern[1][2] = LUT_ppmDitherNone;

	ctx->masterAudio = NULL;
	ppm_sound_header_t* ppmSnd = &ctx->ppm->sndHdr;
	if (ppmSnd->bgmLength > 0 || ppmSnd->seLength[0] > 0 || ppmSnd->seLength[1] > 0 || ppmSnd->seLength[2] > 0)
	{
		// render master audio track
		int audioTrackSize = min(ppmAudioNumSamples(ctx->ppm) * sizeof(s16), AUDIO_SIZE_LIMIT);
		ctx->masterAudio = pd_malloc(audioTrackSize);
		memset(ctx->masterAudio, 0, audioTrackSize);
		ppmAudioRender(ctx->ppm, ctx->masterAudio, AUDIO_SIZE_LIMIT);
		// create playdate audio sample and player from master audio track
		ctx->masterAudioSample = pd->sound->sample->newSampleFromData((u8*)ctx->masterAudio, kSound16bitMono, DS_SAMPLE_RATE, audioTrackSize);
		ctx->audioPlayer = pd->sound->sampleplayer->newPlayer();
		pd->sound->sampleplayer->setSample(ctx->audioPlayer, ctx->masterAudioSample);
	}
	
	pd->lua->pushObject(ctx, "PpmParser", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int ppm_gc(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	ppmDone(ctx->ppm);
	pd_free(ctx->ppm);
	if (ctx->masterAudio != NULL)
	{
		pd->sound->sampleplayer->stop(ctx->audioPlayer);
		pd->sound->sampleplayer->freePlayer(ctx->audioPlayer);
		pd->sound->sample->freeSample(ctx->masterAudioSample);
		pd_free(ctx->masterAudio);
	}
	// pd_log("ppm free at 0x%08x", ctx);
	pd_free(ctx);
  return 0;
}

static int ppm_index(lua_State* L)
{
	if (pd->lua->indexMetatable() == 1)
		return 1;
	
	ppmlib_ctx* ctx = getPpmCtx(1);
	const char* key = pd->lua->getArgString(2);

	if (strcmp(key, "currentFrame") == 0)
		pd->lua->pushInt(ctx->currentFrame + 1); // index startsa at 1 in lua
	else if (strcmp(key, "progress") == 0)
		pd->lua->pushFloat((float)ctx->currentFrame / ((float)ctx->numFrames - 1.0));
	else if (strcmp(key, "frameRate") == 0 || strcmp(key, "fps") == 0)
		pd->lua->pushFloat(ctx->ppm->frameRate);
	else if (strcmp(key, "numFrames") == 0)
		pd->lua->pushInt(ctx->numFrames);
	else if (strcmp(key, "duration") == 0)
		pd->lua->pushFloat((float)ctx->numFrames * (1.0 / (float)ctx->ppm->frameRate));
	else if (strcmp(key, "loop") == 0)
		pd->lua->pushBool(ctx->loop);
	// else if (strcmp(key, "isLocked") == 0)
	// 	pd->lua->pushInt(ctx->hdr.isLocked);
	// else if (strcmp(key, "currentEditor") == 0)
	// 	pd->lua->pushBytes((char* )ctx->hdr.currentEditor, sizeof(ctx->hdr.currentEditor));
	// else if (strcmp(key, "currentEditorId") == 0)
	// 	pd->lua->pushBytes((char* )ctx->hdr.currentEditorId, sizeof(ctx->hdr.currentEditorId));
	else
		pd->lua->pushNil();

  return 1;
}

// decode a frame at a given index
// frame index begins at 1 - lua-style
// static int ppm_decodeFrame(lua_State* L)
// {
// 	ppmlib_ctx* ctx = getPpmCtx(1);
// 	int frame = pd->lua->getArgInt(2) - 1;
// 	ppmVideoDecodeFrame(ctx->ppm, (u16)frame);
//   return 0;
// }

// set a layer's dither pattern from a list of presets
static int ppm_setLayerDither(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int layerIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	int colour = pd->lua->getArgInt(3) - 1; // starts at 1 in lua
	int pattern = pd->lua->getArgInt(4) - 1; // starts at 1 in lua

	switch (pattern)
	{
		// 0 = LUT_ppmDitherNone
		case 1:
			ctx->layerPattern[layerIndex][colour] = LUT_ppmDitherPolka;
			break;
		case 2:
			ctx->layerPattern[layerIndex][colour] = LUT_ppmDitherChecker;
			break;
		case 3:
			ctx->layerPattern[layerIndex][colour] = LUT_ppmDitherInvPolka;
			break;
		default:
			ctx->layerPattern[layerIndex][colour] = LUT_ppmDitherNone;
	}
	return 0;
}

static int ppm_setCurrentFrame(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int frame = pd->lua->getArgInt(2) - 1; // starts at 1 in lua

	if (ctx->loop)
	{
		if (frame > ctx->numFrames - 1) 
			ctx->currentFrame = 0;
		else if (frame < 0)
			ctx->currentFrame = ctx->numFrames - 1;
		else
			ctx->currentFrame = frame;
	}
	else
	{
		ctx->currentFrame = frame;
		CLAMP(ctx->currentFrame, 0, ctx->numFrames - 1);
	}

	return 0;
}

void ppm_blitFrame(ppmlib_ctx* ctx, u16 frameIndex, void* frameBufferBase, u16 frameX, u16 frameY, u16 frameStride)
{
	void* frameBuffer;

	ppmVideoDecodeFrame(ctx->ppm, frameIndex);

	u8* layerA = ctx->ppm->layers[0];
	u8* layerB = ctx->ppm->layers[1];
	const u8* layerAPattern = ctx->layerPattern[0][ctx->ppm->layerColours[0] - 1];
	const u8* layerBPattern = ctx->layerPattern[1][ctx->ppm->layerColours[1] - 1];
	u16 patternOffset = 0;
	int src = 0;

	// code is a bit messy here, but doing a branch inside the loop would hurt performance
	// invert bits after combining for white paper
	if (ctx->ppm->paperColour != 0)
	{
		for (u8 y = 0; y < PPM_SCREEN_HEIGHT; y++)
		{
			frameBuffer = frameBufferBase + (frameY + y) * frameStride + (frameX / 8);
			for (u8 c = 0; c < PPM_BUFFER_STRIDE; c++)
			{
				*(u8*)frameBuffer = ~(layerAPattern[layerA[src] + patternOffset] | layerBPattern[layerB[src] + patternOffset]);
				src += 1;
				frameBuffer += 1;
			}
			patternOffset = patternOffset == 256 ? 0 : 256;
		}
	}
	// retain inverted bits for black paper
	else
	{
		for (u8 y = 0; y < PPM_SCREEN_HEIGHT; y++)
		{
			frameBuffer = frameBufferBase + (frameY + y) * frameStride + (frameX / 8);
			for (u8 c = 0; c < PPM_BUFFER_STRIDE; c++)
			{
				*(u8*)frameBuffer = layerAPattern[layerA[src] + patternOffset] | layerBPattern[layerB[src] + patternOffset];
				src += 1;
				frameBuffer += 1;
			}
			patternOffset = patternOffset == 256 ? 0 : 256;
		}
	}
}

void ppm_blitFrameToBitmap(ppmlib_ctx* ctx, u16 frameIndex, LCDBitmap* bitmap, u16 x, u16 y)
{
	int width = 0;
	int height = 0;
	int stride = 0;
	int hasMask = 0;
	u8* bitmapBuffer;
	
	pd->graphics->getBitmapData(bitmap, &width, &height, &stride, &hasMask, &bitmapBuffer);

	if (width != PPM_SCREEN_WIDTH || height != PPM_SCREEN_HEIGHT)
	{
		pd_log("Error with layer bitmap");
		return;
	}

	// bitmap data is comprised of two maps for each channel, one after the other
	int mapSize = height * stride;
	void* color = bitmapBuffer; // each bit is 0 for black, 1 for white
	if (hasMask)
	{
		void* alpha = bitmapBuffer + mapSize; // each bit is 0 for transparent, 1 for opaque
		memset(alpha, 0xFF, mapSize); // fill alpha map - so all pixels are opaque
	}

	ppm_blitFrame(ctx, frameIndex, color, 0, 0, stride);
}

// draw the current frame into the frame buffer
// ppm:draw(x, y)
static int ppm_draw(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int frameX = pd->lua->getArgInt(2);
	int frameY = pd->lua->getArgInt(3);
	void* frameBuffer = pd->graphics->getFrame();

	ppm_blitFrame(ctx, ctx->currentFrame, frameBuffer, frameX, frameY, LCD_ROWSIZE);

	pd->graphics->drawRect(frameX - 2, frameY - 2, PPM_SCREEN_WIDTH + 4, PPM_SCREEN_HEIGHT + 4, kColorBlack);
	pd->graphics->drawRect(frameX - 1, frameY - 1, PPM_SCREEN_WIDTH + 2, PPM_SCREEN_HEIGHT + 2, kColorWhite);

	return 0;
}

// draw the current frame into a bitmap
// ppm:drawToBitmap(bitmap)
static int ppm_drawToBitmap(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	LCDBitmap* bitmap = pd->lua->getBitmap(2);

	ppm_blitFrameToBitmap(ctx, ctx->currentFrame, bitmap, 0, 0);

	return 0;
}

// draw a given frame index (starts at 1) into the framebuffer
// ppm:drawFrame(frameIndex, x, y)
static int ppm_drawFrame(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int frameIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	int frameX = pd->lua->getArgInt(3);
	int frameY = pd->lua->getArgInt(4);
	void* frameBuffer = pd->graphics->getFrame();

	ppm_blitFrame(ctx, (u16)frameIndex, frameBuffer, frameX, frameY, LCD_ROWSIZE);

	pd->graphics->drawRect(frameX - 2, frameY - 2, PPM_SCREEN_WIDTH + 4, PPM_SCREEN_HEIGHT + 4, kColorBlack);
	pd->graphics->drawRect(frameX - 1, frameY - 1, PPM_SCREEN_WIDTH + 2, PPM_SCREEN_HEIGHT + 2, kColorWhite);

	return 0;
}

// draw a given frame index (starts at 1) into a bitmap
// ppm:drawFrameToBitmap(frameIndex, bitmap)
static int ppm_drawFrameToBitmap(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int frameIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	LCDBitmap* bitmap = pd->lua->getBitmap(3);

	ppm_blitFrameToBitmap(ctx, (u16)frameIndex, bitmap, 0, 0);

	return 0;
}

static int ppm_playAudio(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	if (ctx->masterAudio != NULL)
	{
		pd->sound->sampleplayer->play(ctx->audioPlayer, 1, 1.0);
		// pd->sound->sampleplayer->setOffset(ctx->audioPlayer, X// TODO);
	}
  return 0;
}

static int ppm_stopAudio(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	if (ctx->masterAudio != NULL)
		pd->sound->sampleplayer->stop(ctx->audioPlayer);
  return 0;
}

static const lua_reg libPpm[] =
{
	{ "new",                 ppm_new },
	{ "__gc",                ppm_gc },
	{ "__index",             ppm_index },
	{ "setLayerDither",      ppm_setLayerDither },
	{ "setCurrentFrame",     ppm_setCurrentFrame },
	{ "draw",                ppm_draw },
	{ "drawToBitmap",        ppm_drawToBitmap },
	{ "drawFrame",           ppm_drawFrame },
	{ "drawFrameToBitmap",   ppm_drawFrameToBitmap },
	{ "playAudio",           ppm_playAudio },
	{ "stopAudio",           ppm_stopAudio },
	{ NULL,                  NULL }
};