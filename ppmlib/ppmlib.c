#include <string.h>

#include "pd_api.h"

#include "ppmlib.h"
#include "platform.h"
#include "types.h"
#include "ppm.h"
#include "audio.h"
#include "video.h"
#include "dither.h"

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

	ctx->layerPattern[0][0] = ditherMaskNone;
	ctx->layerPattern[0][1] = ditherMaskNone;
	ctx->layerPattern[0][2] = ditherMaskNone;
	ctx->layerPattern[1][0] = ditherMaskNone;
	ctx->layerPattern[1][1] = ditherMaskNone;
	ctx->layerPattern[1][2] = ditherMaskNone;

	ctx->masterAudio = NULL;
	ppm_sound_header_t* ppmSnd = &ctx->ppm->sndHdr;
	if (ppmSnd->bgmLength > 0 || ppmSnd->seLength[0] > 0 || ppmSnd->seLength[1] > 0 || ppmSnd->seLength[2] > 0)
	{
		// render master audio track
		int audioTrackSize = min(ppmAudioNumSamples(ctx->ppm) * sizeof(u16), AUDIO_SIZE_LIMIT);
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

	if (strcmp(key, "frameRate") == 0 || strcmp(key, "fps") == 0)
		pd->lua->pushFloat(ctx->ppm->frameRate);
	else if (strcmp(key, "numFrames") == 0)
		pd->lua->pushInt(ctx->ppm->hdr.numFrames);
	else if (strcmp(key, "loop") == 0)
		pd->lua->pushBool(ctx->ppm->animHdr.flags.loop);
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
static int ppm_decodeFrame(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int frame = pd->lua->getArgInt(2) - 1;
	ppmVideoDecodeFrame(ctx->ppm, (u16)frame);
  return 0;
}

// set a layer's dither pattern from a list of presets
static int ppm_setLayerDither(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int layerIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	int colour = pd->lua->getArgInt(3) - 1; // starts at 1 in lua
	int pattern = pd->lua->getArgInt(4) - 1; // starts at 1 in lua

	switch (pattern)
	{
		// 0 = ditherMaskNone
		case 1:
			ctx->layerPattern[layerIndex][colour] = ditherMaskPolka;
			break;
		case 2:
			ctx->layerPattern[layerIndex][colour] = ditherMaskChecker;
			break;
		case 3:
			ctx->layerPattern[layerIndex][colour] = ditherMaskInvPolka;
			break;
		default:
			ctx->layerPattern[layerIndex][colour] = ditherMaskNone;
	}
	return 0;
}

// draw a given frame into the framebuffer
static int ppm_drawFrame(lua_State* L)
{
	ppmlib_ctx* ctx = getPpmCtx(1);
	int frameIndex = pd->lua->getArgInt(2) - 1; // starts at 1 in lua
	int updateLines = pd->lua->getArgBool(3);
	void* frameBuffer = pd->graphics->getFrame();
	// initial frame data start position
	// startY = 16
	// startX = 72
	// stride = 52
	frameBuffer = (u32*)(frameBuffer + 16 * 52 + 9);
	// 
	ppmVideoDecodeFrame(ctx->ppm, (u16)frameIndex);

	u8* layerA = ctx->ppm->layers[0];
	u8* layerB = ctx->ppm->layers[1];
	const u32* layerAPattern = ctx->layerPattern[0][ctx->ppm->layerColours[0] - 1];
	const u32* layerBPattern = ctx->layerPattern[1][ctx->ppm->layerColours[1] - 1];
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
			if (ctx->ppm->paperColour == 0)
				chunk = ~chunk;
			*(u32*)frameBuffer = chunk;
			frameBuffer += 4;
		}
		frameBuffer += 20;
	}

	if (updateLines)
		pd->graphics->markUpdatedRows(16, 16 + SCREEN_HEIGHT);

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
	{
		pd->sound->sampleplayer->stop(ctx->audioPlayer);
	}
  return 0;
}

// // decode a frame at a given index
// // frame index begins at 1 - lua-style
// static int ppm_decodeFrameToBitmap(lua_State* L)
// {
// 	ppm_ctx_t* ctx = getPpmCtx(1);
// 	int frame = pd->lua->getArgInt(2) - 1;

// 	LCDBitmap* bitmap = pd->lua->getBitmap(3);

// 	int width = 0;
// 	int height = 0;
// 	int rowBytes = 0;
// 	int hasMask = 0;
// 	u8* data;
	
// 	pd->graphics->getBitmapData(bitmap, &width, &height, &rowBytes, &hasMask, &data);

// 	// TODO: better error message
// 	if (width != SCREEN_WIDTH || height != SCREEN_HEIGHT || hasMask != 1)
// 	{
// 		pd_log("Error with layer bitmap");
// 		return 0;
// 	}

// 	// bitmap data is comprised of two maps for each channel, one after the other
// 	int mapSize = (height*  rowBytes);
// 	u8* color = data; // each bit is 0 for black, 1 for white
// 	u8* alpha = data + mapSize; // each bit is 0 for transparent, 1 for opaque

// 	// clear color map
// 	memset(color, 0x00, mapSize);
// 	// fill alpha map - so all pixels are opaque
// 	memset(alpha, 0xFF, mapSize);

// 	ppmVideoDecodeFrame(ctx, (u16)frame);

// 	u8* layerA = ctx->layers[0];
// 	u8* layerB = ctx->layers[1];
	
// 	// pack layers into 1-bit pixel map
// 	int srcOffset = 0;
// 	u8 chunk = 0;
// 	int dstOffset = 0;
// 	while (dstOffset < mapSize)
// 	{
// 		chunk = 0xFF; // all bits start out white
// 		for (int shift = 0; shift < 8; shift++)
// 		{
// 			// set a bit to black if it corresponds to a black pixel
// 			if (layerA[srcOffset] == 1 || layerB[srcOffset] == 1)
// 				chunk ^= (0x80 >> shift);
// 			srcOffset++;
// 		}
// 		color[dstOffset++] = chunk;
// 	}

// 	return 0;
// }

static const lua_reg libPpm[] =
{
	{ "new",                 ppm_new },
	{ "__gc",                ppm_gc },
	{ "__index",             ppm_index },
	{ "setLayerDither",      ppm_setLayerDither },
	{ "decodeFrame",         ppm_decodeFrame },
	{ "drawFrame",           ppm_drawFrame },
	{ "playAudio",           ppm_playAudio },
	{ "stopAudio",           ppm_stopAudio },
	// { "decodeFrameToBitmap", ppm_decodeFrameToBitmap },
	{ NULL,                  NULL }
};