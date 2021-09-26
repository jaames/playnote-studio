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

static const lua_reg libPpm[] =
{
	{ "__gc",         ppm_gc },
	{ "new",          ppm_new },
	{ "getMagic",     ppm_getMagic },
	{ "getNumFrames", ppm_getNumFrames },
	{ "decodeFrame",  ppm_decodeFrame },
	{ NULL,       NULL }
};