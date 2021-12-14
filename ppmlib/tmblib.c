#include "pd_api.h"

#include "platform.h"
#include "types.h"
#include "tmb.h"
#include "dither.h"

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

static tmb_ctx_t* getTmbCtx(int n)
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

	tmb_ctx_t* ctx = pd_malloc(sizeof(tmb_ctx_t));
	int err = tmbInit(ctx, tmb, fsize);
	pd_free(tmb);

	if (err != -1)
	{
		pd_error("tmbInit error: %d", err);
		pd->lua->pushNil();
		return 1;
	}

	pd->lua->pushObject(ctx, "TmbParser", 0);
	return 1;
}

// called when lua garbage-collects a class instance
static int tmb_gc(lua_State* L)
{
	tmb_ctx_t* ctx = getTmbCtx(1);
	pd_free(ctx);
	// pd_log("tmb free");
  return 0;
}

static int tmb_toBitmap(lua_State* L)
{
	tmb_ctx_t* ctx = getTmbCtx(1);
	u8* pixels = pd_malloc(THUMBNAIL_WIDTH*  THUMBNAIL_HEIGHT);

	int width = 0;
	int height = 0;
	int rowBytes = 0;
	int hasMask = 0;
	u32* bitmapData;
	
	LCDBitmap* bitmap = pd->graphics->newBitmap(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT, kColorBlack);
	pd->graphics->getBitmapData(bitmap, &width, &height, &rowBytes, &hasMask, (u8**)&bitmapData);

	tmbGetThumbnail(ctx, pixels);

	u32 chunk = 0;
	u8 patternOffset = 32;
	u16 src = 0;
	u16 dst = 0;
	for (u8 y = 0; y < THUMBNAIL_HEIGHT; y++)
	{
		// each pattern is 32 * 2 pixels, or 2 lines of 32 pixels
		// for every line in the image, we want to flip between the two pattern lines
		patternOffset = patternOffset == 32 ? 0 : 32;
		// pack 32 pixels horizontally
		for (u8 x = 0; x < THUMBNAIL_WIDTH; x += 32)
		{
			// all pixels start out white
			chunk = 0xFFFFFFFF;
			for (u8 shift = 0; shift < 32; shift++)
			{
				// convert the thumbnail image (which uses paleted color) to 1 bit
				// patterns are used to mask specific pixels and produce dithering
				switch (ppmThumbnailPaletteGray[pixels[src++]])
				{
					// black
					case 0: 
						chunk &= ditherMaskNone[patternOffset + shift];
						break;
					// dark gray (polka pattern, inverted)
					case 1:
						chunk &= ditherMaskInvPolka[patternOffset + shift];
						break;
					// mid gray (checkerboard pattern)
					case 2:
						chunk &= ditherMaskChecker[patternOffset + shift];
						break;
					// light gray (polka pattern)
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
	{ "toBitmap",        		 tmb_toBitmap },
	{ NULL,                  NULL }
};