#include <string.h>

#include "pd_api.h"

#include "ppmlib.h"
#include "platform.h"
#include "types.h"
#include "ppm.h"
#include "video.h"
#include "dither.h"

static const lua_reg libPpm[];
static const lua_reg libTmb[];

void registerPpmlib()
{
	const char *err;

	if (!pd->lua->registerClass("PpmParser", libPpm, NULL, 0, &err))
		pd->system->logToConsole("%s:%i: registering ppm lib failed, %s", __FILE__, __LINE__, err);

	if (!pd->lua->registerClass("TmbParser", libTmb, NULL, 0, &err))
		pd->system->logToConsole("%s:%i: registering tmb lib failed, %s", __FILE__, __LINE__, err);
}

static ppm_ctx_t *getPpmCtx(int n) 
{
	return pd->lua->getArgObject(n, "PpmParser", NULL);
}

static int ppm_new(lua_State *L)
{
	const char *filePath = pd->lua->getArgString(1);

	SDFile *f = pd->file->open(filePath, kFileRead | kFileReadData);

	pd->file->seek(f, 0, SEEK_END);
	int fsize = pd->file->tell(f);
	pd->file->seek(f, 0, SEEK_SET);

	u8 *ppm = pd_malloc(fsize);
	pd->file->read(f, ppm, fsize);
	pd->file->close(f);

	ppm_ctx_t *ctx = pd_malloc(sizeof(ppm_ctx_t));
	int err = ppmInit(ctx, ppm, fsize);
	pd_free(ppm);

	if (err != -1)
	{
		pd->system->error("ppmInit error: %d", err);
		pd->lua->pushNil();
		return 1;
	}

	pd->lua->pushObject(ctx, "PpmParser", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int ppm_gc(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	ppmDone(ctx);
	pd_free(ctx);
	pd->system->logToConsole("ppm free");
  return 0;
}

static int ppm_index(lua_State *L)
{
	if (pd->lua->indexMetatable() == 1)
		return 1;
	
	ppm_ctx_t *ctx = getPpmCtx(1);
	const char* key = pd->lua->getArgString(2);

	if (strcmp(key, "frameRate") == 0 || strcmp(key, "fps") == 0)
		pd->lua->pushFloat(ctx->frameRate);
	else if (strcmp(key, "numFrames") == 0)
		pd->lua->pushInt(ctx->hdr.numFrames);
	else if (strcmp(key, "loop") == 0)
		pd->lua->pushBool(ctx->hdr.numFrames);
	// else if (strcmp(key, "isLocked") == 0)
	// 	pd->lua->pushInt(ctx->hdr.isLocked);
	// else if (strcmp(key, "currentEditor") == 0)
	// 	pd->lua->pushBytes((char *)ctx->hdr.currentEditor, sizeof(ctx->hdr.currentEditor));
	// else if (strcmp(key, "currentEditorId") == 0)
	// 	pd->lua->pushBytes((char *)ctx->hdr.currentEditorId, sizeof(ctx->hdr.currentEditorId));
	else
		pd->lua->pushNil();

  return 1;
}

// example for reading fields from the ppm ctx
static int ppm_getMagic(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	pd->lua->pushBytes(ctx->hdr.magic, sizeof(ctx->hdr.magic));
  return 1;
}

// get the flipnote framerate (in frames per second) as a float
static int ppm_getFps(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	float rate = ctx->frameRate;
	pd->lua->pushFloat(rate);
  return 1;
}

// get the number of flipnote frames
static int ppm_getNumFrames(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	pd->lua->pushInt(ctx->hdr.numFrames);
  return 1;
}

// decode a frame at a given index
// frame index begins at 1 - lua-style
static int ppm_decodeFrame(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	int frame = pd->lua->getArgInt(2) - 1;
	ppmVideoDecodeFrame(ctx, (u16)frame);
  return 0;
}

// draw a given frame into the framebuffer
static int ppm_drawFrame(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	int frameIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	int updateLines = pd->lua->getArgBool(3);
	void *frameBuffer = pd->graphics->getFrame();
	// initial frame data start position
	// startY = 16
	// startX = 72
	// stride = 52
	frameBuffer = (u32*)(frameBuffer + 16 * 52 + 9);
	// 
	ppmVideoDecodeFrame(ctx, (u16)frameIndex);
	u8 *layerA = ctx->layers[0];
	u8 *layerB = ctx->layers[1];

	const u32 *layerAPattern = ditherMaskNone;
	const u32 *layerBPattern = ditherMaskChecker;
	u8 patternOffset = 32;

	u32 chunk = 0;
	int src = 0;

	for (u8 y = 0; y < SCREEN_HEIGHT; y++)
	{
		// shift pattern between even and odd row
		patternOffset = patternOffset == 32 ? 0 : 32;
		// pack 32 pixels into a 4-byte chunk
		for (u8 c = 0; c < 8; c += 1)
		{
			// all pixels start out white
			chunk = 0xFFFFFFFF;
			for (u8 shift = 0; shift < 32; shift++, src++)
			{
				// flip bit to black if the pixel is > 0
				if (layerA[src])
					chunk &= layerAPattern[patternOffset + shift];
				else if (layerB[src])
					chunk &= layerBPattern[patternOffset + shift];
			}
			// invert chunk if paper is black
			if (ctx->paperColour == 0)
				chunk = ~chunk;
			*(u32 *)frameBuffer = chunk;
			frameBuffer += 4;
		}
		frameBuffer += 20;
	}

	if (updateLines)
		pd->graphics->markUpdatedRows(16, 16 + SCREEN_HEIGHT);

	return 0;
}

// decode a frame at a given index
// frame index begins at 1 - lua-style
static int ppm_decodeFrameToBitmap(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	int frame = pd->lua->getArgInt(2) - 1;

	LCDBitmap* bitmap = pd->lua->getBitmap(3);

	int width = 0;
	int height = 0;
	int rowBytes = 0;
	int hasMask = 0;
	u8* data;
	
	pd->graphics->getBitmapData(bitmap, &width, &height, &rowBytes, &hasMask, &data);

	// TODO: better error message
	if (width != SCREEN_WIDTH || height != SCREEN_HEIGHT || hasMask != 1)
	{
		pd->system->logToConsole("Error with layer bitmap");
		return 0;
	}

	// bitmap data is comprised of two maps for each channel, one after the other
	int mapSize = (height * rowBytes);
	u8* color = data; // each bit is 0 for black, 1 for white
	u8* alpha = data + mapSize; // each bit is 0 for transparent, 1 for opaque

	// clear color map
	memset(color, 0x00, mapSize);
	// fill alpha map - so all pixels are opaque
	memset(alpha, 0xFF, mapSize);

	ppmVideoDecodeFrame(ctx, (u16)frame);

	u8* layerA = ctx->layers[0];
	u8* layerB = ctx->layers[1];
	
	// pack layers into 1-bit pixel map
	int srcOffset = 0;
	u8 chunk = 0;
	int dstOffset = 0;
	while (dstOffset < mapSize)
	{
		chunk = 0xFF; // all bits start out white
		for (int shift = 0; shift < 8; shift++)
		{
			// set a bit to black if it corresponds to a black pixel
			if (layerA[srcOffset] == 1 || layerB[srcOffset] == 1)
				chunk ^= (0x80 >> shift);
			srcOffset++;
		}
		color[dstOffset++] = chunk;
	}

	return 0;
}

static const lua_reg libPpm[] =
{
	{ "new",                 ppm_new },
	{ "__gc",                ppm_gc },
	{ "__index",             ppm_index },
	{ "getMagic",            ppm_getMagic },
	{ "getNumFrames",        ppm_getNumFrames },
	{ "getFps",              ppm_getFps },
	{ "decodeFrame",         ppm_decodeFrame },
	{ "drawFrame",           ppm_drawFrame },
	{ "decodeFrameToBitmap", ppm_decodeFrameToBitmap },
	{ NULL,                  NULL }
};

static tmb_ctx_t *getTmbCtx(int n) { return pd->lua->getArgObject(n, "TmbParser", NULL); }

static int tmb_new(lua_State *L)
{
	const char *filePath = pd->lua->getArgString(1);

	int fsize = 0x06A0;
	u8 *tmb = pd_malloc(fsize);

	SDFile *f = pd->file->open(filePath, kFileRead | kFileReadData);
	pd->file->read(f, tmb, fsize);
	pd->file->close(f);

	tmb_ctx_t *ctx = pd_malloc(sizeof(tmb_ctx_t));
	int err = tmbInit(ctx, tmb, fsize);
	pd_free(tmb);

	if (err != -1)
	{
		pd->system->error("tmbInit error: %d", err);
		pd->lua->pushNil();
		return 1;
	}

	pd->lua->pushObject(ctx, "TmbParser", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int tmb_gc(lua_State *L)
{
	tmb_ctx_t *ctx = getTmbCtx(1);
	pd_free(ctx);
	pd->system->logToConsole("tmb free");
  return 0;
}

static int tmb_toBitmap(lua_State *L)
{
	tmb_ctx_t *ctx = getTmbCtx(1);
	u8 *pixels = pd_malloc(THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT);

	pd_log("AAAAA");

	int width = 0;
	int height = 0;
	int rowBytes = 0;
	int hasMask = 0;
	u32 *bitmapData;
	
	LCDBitmap *bitmap = pd->graphics->newBitmap(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT, kColorBlack);
	pd->graphics->getBitmapData(bitmap, &width, &height, &rowBytes, &hasMask, (u8 **)&bitmapData);

	tmbGetThumbnail(ctx, pixels);

	u32 chunk = 0;
	u8 patternOffset = 32;
	u16 src = 0;
	u16 dst = 0;
	for (u8 y = 0; y < THUMBNAIL_HEIGHT; y++)
	{
		patternOffset = patternOffset == 32 ? 0 : 32;
		for (u8 x = 0; x < THUMBNAIL_WIDTH; x += 32)
		{
			// all pixels start out white
			chunk = 0xFFFFFFFF;
			for (u8 shift = 0; shift < 32; shift++)
			{
				switch (ppmThumbnailPaletteGray[pixels[src++]])
				{
					// black
					case 0: 
						chunk &= ditherMaskNone[patternOffset + shift];
						break;
					// dark gray
					case 1:
						chunk &= ditherMaskInvPolka[patternOffset + shift];
						break;
					// mid gray
					case 2:
						chunk &= ditherMaskChecker[patternOffset + shift];
						break;
					// light gray
					case 3:
						chunk &= ditherMaskPolka[patternOffset + shift];
						break;
					// 4 = white, do nothing
				}
			}
			bitmapData[dst++] = chunk;
		}
	}

	pd_free(pixels);
	pd->lua->pushBitmap(bitmap);
	return 1;
}

static const lua_reg libTmb[] =
{
	{ "new",                 tmb_new },
	{ "__gc",                tmb_gc },
	// { "__index",             ppm_index },
	{ "toBitmap",        		 tmb_toBitmap },
	{ NULL,                  NULL }
};