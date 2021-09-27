#include "pd_api.h"

#include "luaglue.h"
#include "pd.h"
#include "types.h"
#include "ppm.h"
#include "ppm_video.h"

static PlaydateAPI *pd = NULL;

static const lua_reg libPpm[];

void registerExt(PlaydateAPI *playdate)
{
	pd = playdate;

	const char *err;

	if (!pd->lua->registerClass("PpmParser", libPpm, NULL, 0, &err))
		pd->system->logToConsole("%s:%i: registerClass failed, %s", __FILE__, __LINE__, err);

	pd_setRealloc(pd->system->realloc);
}

static ppm_ctx_t *getPpmCtx(int n) { return pd->lua->getArgObject(n, "PpmParser", NULL); }

static int ppm_new(lua_State *L)
{
	const char *filePath = pd->lua->getArgString(1);

	pd->system->logToConsole("path: %s", filePath);

	SDFile *f = pd->file->open(filePath, kFileRead | kFileReadData);

	pd->file->seek(f, 0, SEEK_END);
	int fsize = pd->file->tell(f);
	pd->file->seek(f, 0, SEEK_SET);

	u8 *ppm = pd_malloc(fsize);
	pd->file->read(f, ppm, fsize);
	pd->file->close(f);

	ppm_ctx_t *ctx = pd_malloc(sizeof(ppm_ctx_t));

	int err = ppmInit(ctx, ppm, fsize);

	if (err == -1)
	{
		pd->system->logToConsole("file size: %d", fsize);
		pd->system->logToConsole("ppm init worked!? fuck you koizumi");
	}
	// pd->system->logToConsole("anim size: %d", ctx->hdr.animationLength);

	pd_free(ppm);
	// SDFile *f = pd->file->open(filePath, kFileRead | kFileReadData);

	// pd->file->seek(f, 0, SEEK_END);
	// int fsize = pd->file->tell(f);
	// pd->file->seek(f, 0, SEEK_SET);

	// u8 *buf = pd_malloc(fsize);
	// pd->file->read(f, buf, fsize);

	// ppm_ctx_t *ctx = pd_malloc(sizeof(ppm_ctx_t));

	// int err = ppmInit(ctx, buf, fsize);

	// pd->system->logToConsole("err: %d", err);

	// pd->system->logToConsole("size: %d", ctx->sndHdr.bgmLength);

	// pd_free(buf);
	// pd->file->close(f);

	ppmVideoDecodeFrame(ctx, 1);

	pd->system->logToConsole("IT JUST FUCKING DECODED A FRAME");

	pd->system->logToConsole("I AM A GOD AMONG MEN");

	pd->lua->pushObject(ctx, "PpmParser", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int ppm_gc(lua_State *L)
{
	// TODO: this will crash on boot?
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

// // get the flipnote framerate (in frames per second) as a float
// static int ppm_getFps(lua_State *L)
// {
// 	ppm_ctx_t *ctx = getPpmCtx(1);
// 	float rate = ctx->frameRate;
// 	pd->lua->pushFloat(rate);
//   return 1;
// }

// // get the number of flipnote frames
// static int ppm_getNumFrames(lua_State *L)
// {
// 	ppm_ctx_t *ctx = getPpmCtx(1);
// 	pd->lua->pushInt(ctx->hdr.numFrames);
//   return 1;
// }

// // decode a frame at a given index
// // frame index begins at 1 - lua-style
// static int ppm_decodeFrame(lua_State *L)
// {
// 	ppm_ctx_t *ctx = getPpmCtx(1);
// 	int frame = pd->lua->getArgInt(2) - 1;
// 	ppmVideoDecodeFrame(ctx, (u16)frame);
//   return 0;
// }

// decode a frame at a given index
// frame index begins at 1 - lua-style
static int ppm_decodeFrameToBitmap(lua_State *L)
{
	ppm_ctx_t *ctx = getPpmCtx(1);
	int frame = pd->lua->getArgInt(2) - 1;

	pd->system->logToConsole("Frame index: %d", frame);

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

	pd->system->logToConsole("Bitmap w: %d, h:%d", width, height);

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
	{ "__gc",                ppm_gc },
	{ "new",                 ppm_new },
	{ "getMagic",            ppm_getMagic },
	// { "getNumFrames",        ppm_getNumFrames },
	// { "getFps",              ppm_getFps },
	// { "decodeFrame",         ppm_decodeFrame },
	{ "decodeFrameToBitmap", ppm_decodeFrameToBitmap },
	{ NULL,                  NULL }
};