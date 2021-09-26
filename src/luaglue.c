#include "luaglue.h"

#include "pd_api.h"

#include "ppm.h"
#include "ppm_video.h"

static PlaydateAPI *pd = NULL;

static const lua_reg libPpm[];

void registerExt(PlaydateAPI *playdate)
{
	// playdate API access
	pd = playdate;

	const char *err;

	// expose PpmParser class to lua runtime
	if (!pd->lua->registerClass("PpmParser", libPpm, NULL, 0, &err))
		pd->system->logToConsole("%s:%i: registerClass failed, %s", __FILE__, __LINE__, err);
}

static ppm_ctx_t *getPpmCtx(int n) { return pd->lua->getArgObject(n, "PpmParser", NULL); }

// creates a new PpmParser instance
// takes ppm filepath as a string argument
static int ppm_new(lua_State *L)
{
	const char *filePath = pd->lua->getArgString(1);

	SDFile *f = pd->file->open(filePath, kFileRead | kFileReadData);

	pd->file->seek(f, 0, SEEK_END);
	int fsize = pd->file->tell(f);
	pd->file->seek(f, 0, SEEK_SET);

	u8 *buf = malloc(fsize);
	pd->file->read(f, buf, fsize);

	ppm_ctx_t *ctx = malloc(sizeof(ppm_ctx_t));

	int err = ppmInit(ctx, buf, fsize);

	pd->system->logToConsole("%d", err);

	free(buf);
	pd->file->close(f);

	pd->lua->pushObject(ctx, "PpmParser", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int ppm_gc(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	ppmDone(ctx);
  return 0;
}

// example for reading fields from the ppm ctx
static int ppm_getMagic(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	pd->lua->pushBytes(ctx->hdr.magic, sizeof(ctx->hdr.magic));
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
	int frame = pd->lua->getArgInt(2);
	ppmVideoDecodeFrame(ctx, (u16)frame - 1);
  return 0;
}

static int ppm_decodeFrameToBitmap(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	int frame = pd->lua->getArgInt(2);
	
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
	u8* color = data; // 0 = black, 1 = white
	u8* alpha = data + mapSize; // 0 = transparent, 1 = opaque

	// clear color map
	memset(color, 0x00, mapSize);
	// fill alpha map - so all pixels are opaque
	memset(alpha, 0xFF, mapSize);

	ppmVideoDecodeFrame(ctx, (u16)frame - 1);

	u8* layerA = ctx->layers[0];
	u8* layerB = ctx->layers[1];

	int srcOffset = 0;
	int dstOffset = 0;
	u8 chunk = 0;

	while(dstOffset < mapSize)
	{
		chunk = 0xFF;
		for (int shift = 0; shift < 8; shift++)
		{
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
	{ "__gc",                ppm_gc },
	{ "new",                 ppm_new },
	{ "getMagic",            ppm_getMagic },
	{ "getNumFrames",        ppm_getNumFrames },
	{ "decodeFrame",         ppm_decodeFrame },
	{ "decodeFrameToBitmap", ppm_decodeFrameToBitmap },
	{ NULL,       NULL }
};