#include <string.h>

#include "pd_api.h"

#include "utils.h"
#include "platform.h"
#include "types.h"
#include "tmb.h"
#include "tmblib.h"
#include "tables.h"

static const lua_reg libTmb[];

void registerTmblib()
{
	const char* err;

	if (!pd->lua->registerClass("TmbParser", libTmb, NULL, 0, &err))
	{
		pd_error("%s:%i: registering TMB lib failed, %s", __FILE__, __LINE__, err);
		return;
	}
}


LCDBitmap* tmbGetPdBitmap(tmblib_ctx* ctx)
{
	u8* pixels = pd_malloc(PPM_THUMBNAIL_WIDTH * PPM_THUMBNAIL_HEIGHT);

	int width = 0;
	int height = 0;
	int rowBytes = 0;
	int hasMask = 0;
	u8* bitmapData;
	
	LCDBitmap* bitmap = pd->graphics->newBitmap(PPM_THUMBNAIL_WIDTH, PPM_THUMBNAIL_HEIGHT, kColorBlack);
	pd->graphics->getBitmapData(bitmap, &width, &height, &rowBytes, &hasMask, &bitmapData);

	tmbGetThumbnail(ctx->tmb, pixels);

	u8 chunk = 0;
	u8 patternOffset = 0;
	u16 src = 0;
	u16 dst = 0;
	for (u8 y = 0; y < PPM_THUMBNAIL_HEIGHT; y++)
	{
		// pack 8 pixels horizontally
		for (u8 x = 0; x < PPM_THUMBNAIL_WIDTH; x += 8)
		{
			// all pixels start out white
			chunk = 0xFF;
			for (u8 shift = 0; shift < 8; shift++)
			{
				// convert the thumbnail image (which uses paleted color) to 1 bit
				// patterns are used to mask specific pixels and produce dithering
				switch (ppmThumbnailPaletteGray[pixels[src++]])
				{
					// black
					case 0: 
						chunk &= MASK_tmbDitherNone[patternOffset + shift];
						break;
					// dark gray (polka pattern, inverted)
					case 1:
						chunk &= MASK_tmbDitherInvPolka[patternOffset + shift];
						break;
					// mid gray (checkerboard pattern)
					case 2:
						chunk &= MASK_tmbDitherChecker[patternOffset + shift];
						break;
					// light gray (polka pattern)
					case 3:
						chunk &= MASK_tmbDitherPolka[patternOffset + shift];
						break;
					// 4 = white, do nothing
				}
			}
			bitmapData[dst++] = chunk;
		}
		// at the end of every line, switch to the other half of the pattern table
		patternOffset = patternOffset == 8 ? 0 : 8;
	}

	pd_free(pixels);
	return bitmap;
}

static tmblib_ctx* getTmbCtx(int n)
{
  return pd->lua->getArgObject(n, "TmbParser", NULL);
}

static int tmb_new(lua_State* L)
{
	const char* filePath = pd->lua->getArgString(1);

	int fsize = 0x06A0;
	u8* tmb = pd_malloc(fsize);

	SDFile* f = pd->file->open(filePath, kFileRead | kFileReadData);
	pd->file->read(f, tmb, fsize);
	pd->file->close(f);

	tmblib_ctx* ctx = pd_malloc(sizeof(tmblib_ctx));
	ctx->tmb = pd_malloc(sizeof(tmb_ctx_t));
	int err = tmbInit(ctx->tmb, tmb, fsize);
	pd_free(tmb);

	if (err != -1)
	{
		pd_error("tmbInit error: %d", err);
		pd->lua->pushNil();
		return 1;
	}

	ctx->ppmPath = pd_strdup(filePath);
	ctx->bitmap = tmbGetPdBitmap(ctx);

	pd->lua->pushObject(ctx, "TmbParser", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int tmb_gc(lua_State* L)
{
	tmblib_ctx* ctx = getTmbCtx(1);
	pd_free(ctx->tmb);
	pd_free(ctx->ppmPath);
	pd->graphics->freeBitmap(ctx->bitmap);
	// pd_log("tmb free at 0x%08x", ctx);
	pd_free(ctx);
  return 0;
}

static int tmb_index(lua_State* L)
{
	if (pd->lua->indexMetatable() == 1)
		return 1;
	
	tmblib_ctx* ctx = getTmbCtx(1);
	const char* key = pd->lua->getArgString(2);

	if (strcmp(key, "bitmap") == 0)
		pd->lua->pushBitmap(ctx->bitmap);
	else if (strcmp(key, "path") == 0)
		pd->lua->pushString(ctx->ppmPath);
	else if (strcmp(key, "numFrames") == 0)
		pd->lua->pushInt(ctx->tmb->hdr.numFrames);
	else if (strcmp(key, "currentAuthor") == 0)
		pd->lua->pushBytes((char*)ctx->tmb->hdr.currentAuthor, 22);
	else if (strcmp(key, "previousAuthor") == 0)
		pd->lua->pushBytes((char*)ctx->tmb->hdr.previousAuthor, 22);
	else if (strcmp(key, "originalAuthor") == 0)
		pd->lua->pushBytes((char*)ctx->tmb->hdr.originalAuthor, 22);
	else if (strcmp(key, "currentAuthorId") == 0)
		pd->lua->pushBytes((char*)ctx->tmb->hdr.currentAuthorId, 8);
	else if (strcmp(key, "previousAuthorId") == 0)
		pd->lua->pushBytes((char*)ctx->tmb->hdr.previousAuthorId, 8);
	else if (strcmp(key, "originalAuthorId") == 0)
		pd->lua->pushBytes((char*)ctx->tmb->hdr.originalAuthorId, 8);
	else if (strcmp(key, "timestamp") == 0)
		pd->lua->pushInt(ctx->tmb->hdr.timeStamp);
	else if (strcmp(key, "ppmSize") == 0)
	{
		FileStat* stat = pd_malloc(sizeof(FileStat));
		int res = pd->file->stat(ctx->ppmPath, stat);
		if (res == 0)
			pd->lua->pushInt(stat->size);
		else
			pd->lua->pushNil();
		pd_free(stat);
	}

	else
		pd->lua->pushNil();

  return 1;
}

static const lua_reg libTmb[] =
{
	{ "new",                 tmb_new },
	{ "__gc",                tmb_gc },
	{ "__index",             tmb_index },
	{ NULL,                  NULL }
};