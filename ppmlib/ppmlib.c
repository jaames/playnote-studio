#include <string.h>

#include "pd_api.h"

#include "ppmlib.h"
#include "platform.h"
#include "types.h"
#include "ppm.h"
#include "audio.h"
#include "video.h"
#include "tables.h"
#include "player.h"
#include "utils.h"

static const lua_reg libPpm[];

void registerPpmlib()
{
	const char* err;

	if (!pd->lua->registerClass("PpmPlayer", libPpm, NULL, 0, &err))
	{
		pd_error("%s:%i: registering PPM lib failed, %s", __FILE__, __LINE__, err);
		return;
	}

	ppmAudioRegister();
}

static player_ctx* getPlayerCtx(int n) 
{
	return pd->lua->getArgObject(n, "PpmPlayer", NULL);
}

static void blitPpmFrame(player_ctx* ctx, u16 frameIndex, void* destBuffer, u16 destX, u16 destY, u16 destStride)
{
  void* dest;

	ppmVideoDecodeFrame(ctx->ppm, frameIndex, 0);

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
			dest = destBuffer + (destY + y) * destStride + (destX / 8);
			for (u8 c = 0; c < PPM_BUFFER_STRIDE; c++)
			{
				*(u8*)dest = ~(layerAPattern[layerA[src] + patternOffset] | layerBPattern[layerB[src] + patternOffset]);
				src += 1;
				dest += 1;
			}
			patternOffset = patternOffset == 256 ? 0 : 256;
		}
	}
	// retain inverted bits for black paper
	else
	{
		for (u8 y = 0; y < PPM_SCREEN_HEIGHT; y++)
		{
			dest = destBuffer + (destY + y) * destStride + (destX / 8);
			for (u8 c = 0; c < PPM_BUFFER_STRIDE; c++)
			{
				*(u8*)dest = layerAPattern[layerA[src] + patternOffset] | layerBPattern[layerB[src] + patternOffset];
				src += 1;
				dest += 1;
			}
			patternOffset = patternOffset == 256 ? 0 : 256;
		}
	}
}

static int ppmlib_new(lua_State* L)
{
	const char* filePath = pd->lua->getArgString(1);
	int x = pd->lua->getArgInt(2);
	int y = pd->lua->getArgInt(3);

	SDFile* f = pd->file->open(filePath, kFileRead | kFileReadData);
	if (f == NULL)
	{
		const char* err = pd->file->geterr();
		pd_error("Error opening %s: %s", filePath, err);
		pd->lua->pushNil();
		return 1;
	}

	pd->file->seek(f, 0, SEEK_END);
	int fsize = pd->file->tell(f);
	pd->file->seek(f, 0, SEEK_SET);

	u8* ppm = pd_malloc(fsize);
	pd->file->read(f, ppm, fsize);
	pd->file->close(f);

	player_ctx* ctx = playerInit((u16)x, (u16)y);
	int err = playerLoadPpm(ctx, ppm, fsize);
	pd_free(ppm);
	
	if (err == 1)
	{
		pd->lua->pushNil();
		return 1;
	}

	pd->lua->pushObject(ctx, "PpmPlayer", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int ppmlib_gc(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	playerDone(ctx);
  return 0;
}

static int ppmlib_index(lua_State* L)
{
	if (pd->lua->indexMetatable() == 1)
		return 1;
	
	player_ctx* ctx = getPlayerCtx(1);
	const char* key = pd->lua->getArgString(2);

	if (strcmp(key, "isPlaying") == 0)
		pd->lua->pushBool(ctx->isPlaying);
	else if (strcmp(key, "currentFrame") == 0)
		pd->lua->pushInt(ctx->currentFrame + 1); // index starts at 1 in lua
	else if (strcmp(key, "currentTime") == 0)
		pd->lua->pushFloat((float)ctx->currentFrame * (1.0 / (float)ctx->ppm->frameRate));
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
	else
		pd->lua->pushNil();

  return 1;
}

// set a layer's dither pattern from a list of presets
static int ppmlib_setLayerDither(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	int layerIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	int colour = pd->lua->getArgInt(3) - 1; // starts at 1 in lua
	int pattern = pd->lua->getArgInt(4) - 1; // starts at 1 in lua
	playerSetLayerDithering(ctx, layerIndex, colour, pattern);
	return 0;
}

static int ppmlib_setCurrentFrame(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	int frame = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	playerSetFrame(ctx, frame);
	return 0;
}

// draw the current frame into the frame buffer
// ppm:draw()
static int ppmlib_draw(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	blitPpmFrame(ctx, ctx->currentFrame, pd->graphics->getFrame(), ctx->x, ctx->y, LCD_ROWSIZE);
  pd->graphics->drawRect(ctx->x - 2, ctx->y - 2, PPM_SCREEN_WIDTH + 4, PPM_SCREEN_HEIGHT + 4, kColorBlack);
  pd->graphics->drawRect(ctx->x - 1, ctx->y - 1, PPM_SCREEN_WIDTH + 2, PPM_SCREEN_HEIGHT + 2, kColorWhite);
	return 0;
}

// draw a given frame index (starts at 1) into a bitmap
// ppm:drawFrameToBitmap(frameIndex, bitmap)
static int ppmlib_drawFrameToBitmap(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	int frameIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	LCDBitmap* bitmap = pd->lua->getBitmap(3);
	int width = 0;
	int height = 0;
	int stride = 0;
	int hasMask = 0;
	u8* bitmapBuffer;
	pd->graphics->getBitmapData(bitmap, &width, &height, &stride, &hasMask, &bitmapBuffer);
	if (width != PPM_SCREEN_WIDTH || height != PPM_SCREEN_HEIGHT)
	{
		pd_log("Error with layer bitmap");
		return 0;
	}
	// bitmap data is comprised of two maps for each channel, one after the other
	int mapSize = height * stride;
	void* colorBuffer = bitmapBuffer; // each bit is 0 for black, 1 for white
	if (hasMask)
	{
		void* alphaBuffer = bitmapBuffer + mapSize; // each bit is 0 for transparent, 1 for opaque
		memset(alphaBuffer, 0xFF, mapSize); // fill alpha map - so all pixels are opaque
	}
	blitPpmFrame(ctx, frameIndex, colorBuffer, 0, 0, stride);
	return 0;
}

static int ppmlib_update(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	playerUpdate(ctx);
  return 0;
}

static int ppmlib_play(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	playerPlay(ctx);
  return 0;
}

static int ppmlib_pause(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	playerPause(ctx);
  return 0;
}

static int ppmlib_setStoppedCallback(lua_State* L)
{
	player_ctx* ctx = getPlayerCtx(1);
	ctx->stoppedCallback = pd_strdup(pd->lua->getArgString(2));
  return 0;
}

static const lua_reg libPpm[] =
{
	{ "new",                 ppmlib_new },
	{ "__gc",                ppmlib_gc },
	{ "__index",             ppmlib_index },
	{ "draw",                ppmlib_draw },
	{ "drawFrameToBitmap",   ppmlib_drawFrameToBitmap },
	{ "setLayerDither",      ppmlib_setLayerDither },
	{ "setCurrentFrame",     ppmlib_setCurrentFrame },
	{ "play",                ppmlib_play },
	{ "pause",               ppmlib_pause },
	{ "update",              ppmlib_update },
	{ "setStoppedCallback",  ppmlib_setStoppedCallback },
	{ NULL,                  NULL }
};