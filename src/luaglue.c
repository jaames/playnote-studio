#include <string.h>

#include "pd_api.h"

#include "luaglue.h"
#include "pd.h"
#include "types.h"
#include "ppm.h"
#include "ppm_video.h"

static PlaydateAPI *pd = NULL;

static const lua_reg libPpm[];
static const lua_reg libTmb[];

void registerExt(PlaydateAPI *playdate)
{
	pd = playdate;

	const char *err;

	if (!pd->lua->registerClass("PpmParser", libPpm, NULL, 0, &err))
		pd->system->logToConsole("%s:%i: registering ppm lib failed, %s", __FILE__, __LINE__, err);

	if (!pd->lua->registerClass("TmbParser", libTmb, NULL, 0, &err))
		pd->system->logToConsole("%s:%i: registering tmb lib failed, %s", __FILE__, __LINE__, err);

	pd_setRealloc(pd->system->realloc);
}

static ppm_ctx_t *getPpmCtx(int n) { return pd->lua->getArgObject(n, "PpmParser", NULL); }

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

	#if TARGET_PLAYDATE
		pd->system->logToConsole("target playdate");
	#endif

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
	// pd->system->logToConsole("ppm free");
  return 0;
}

static int ppm_index(lua_State *L)
{
	if (pd->lua->indexMetatable() == 1)
		return 1;
	
	ppm_ctx_t *ctx = getPpmCtx(1);
	const char* key = pd->lua->getArgString(2);

	if (strcmp(key, "frameRate") == 0)
		pd->lua->pushFloat(ctx->frameRate);
	else if (strcmp(key, "numFrames") == 0)
		pd->lua->pushInt(ctx->hdr.numFrames);
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

// 
static int ppm_drawFrame(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	int frameIndex = pd->lua->getArgInt(2) - 1;
	u8 *frameBuffer = pd->graphics->getFrame();

	ppmVideoDecodeFrame(ctx, (u16)frameIndex);

	u8* layerA = ctx->layers[0];
	u8* layerB = ctx->layers[1];

	int dstPtr = 0;
	int srcPtr = 0;
	register u8 chunk = 0;

	static int stride = 52;
	static int startLine = 16;
	static int startByte = 72 / 8;

	bool oddLine = false;
	// bool isLayerARedBlue = ctx->layerColours[0] > 1;
	// bool isLayerBRedBlue = ctx->layerColours[1] > 1;

	for (int y = 0; y < SCREEN_HEIGHT; y++)
	{
		dstPtr = (startLine + y) * stride + startByte;
		oddLine = (srcPtr - 1) % 512 < 256;

// pack 8 pixels into a one-byte chunk
for (int c = 0; c < 32; c += 1)
{
		// all pixels start out white
	chunk = 0xFF;
	for (int shift = 0; shift < 8; shift++, srcPtr++)
	{
		// flip bit to black if the pixel is > 0
		if (layerA[srcPtr] || layerB[srcPtr])
			chunk &= patternMaskNone[shift];
		// same for layer b, but with a half-dither pattern for contrast
		// else if (layerB[srcPtr])
		// 	chunk &= (oddLine ? patternMaskCheckerboardOdd : patternMaskCheckerboardEven)[shift];
	}
	// invert chunk if paper is black
	if (ctx->paperColour == 0)
		chunk = ~chunk;

	frameBuffer[dstPtr++] = chunk;
}

	}

	pd->graphics->markUpdatedRows(startLine, startLine + SCREEN_HEIGHT);

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
	// pd->system->logToConsole("tmb free");
  return 0;
}

static int tmb_toBitmap(lua_State *L)
{
	tmb_ctx_t *ctx = getTmbCtx(1);

	u8 *pixels = pd_malloc(64 * 48);

	int width = 0;
	int height = 0;
	int rowBytes = 0;
	int hasMask = 0;
	u8* bitmapData;
	
	LCDBitmap *bitmap = pd->graphics->newBitmap(64, 48, kColorBlack);
	pd->graphics->getBitmapData(bitmap, &width, &height, &rowBytes, &hasMask, &bitmapData);

	tmbGetThumbnail(ctx, pixels);

	u8 chunk = 0;
	u8 px = 0;
	bool oddLine = false;
	int srcOffset = 0;
	int dstOffset = 0;
	while (dstOffset < height * rowBytes)
	{
		chunk = 0xFF; // all pixels start out white
		for (int shift = 0; shift < 8; shift++)
		{
			px = ppmThumbnailPaletteGray[pixels[srcOffset++]];
			oddLine = (srcOffset - 1) % 128 < 64;
			// set a bit to black if it corresponds to a black pixel
			if (px == 0)
				chunk ^= (0x80 >> shift);
			// dark grey - inverse polka pattern
			else if (px == 1 && (!oddLine || srcOffset % 2 == 0))
				chunk ^= (0x80 >> shift);
			// mid grey - checkerboard pattern
			else if (px == 2 && srcOffset % 2 == (oddLine ? 1 : 0))
				chunk ^= (0x80 >> shift);
			// light grey - polka pattern
			else if (px == 3 && (oddLine && srcOffset % 2 == 1))
				chunk ^= (0x80 >> shift);
		}
		bitmapData[dstOffset++] = chunk;
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