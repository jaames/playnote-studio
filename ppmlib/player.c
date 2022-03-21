#include <string.h>

#include "pd_api.h"

#include "utils.h"
#include "player.h"
#include "platform.h"
#include "types.h"
#include "ppm.h"
#include "audio.h"
#include "video.h"
#include "tables.h"
#include "player.h"

static void doCallback(char* fnName, int numArgs)
{
	const char* err;
	if (!pd->lua->callFunction(fnName, numArgs, &err))
    pd_log("Error calling Lua callback: %s", err);
}

player_ctx* playerInit(u16 x, u16 y)
{
  player_ctx* ctx = pd_malloc(sizeof(player_ctx));
	ctx->ppm = NULL;
	ctx->masterAudio = NULL;
  playerMoveTo(ctx, x, y);
  return ctx;
}

void playerMoveTo(player_ctx* ctx, u16 x, u16 y)
{
  ctx->x = x;
  ctx->y = y; 
}

int playerLoadPpm(player_ctx* ctx, void* ppmBuffer, size_t ppmSize)
{
	ctx->ppm = pd_malloc(sizeof(ppm_ctx_t));
	int err = ppmInit(ctx->ppm, ppmBuffer, ppmSize);
  if (err != -1)
	{
		pd_error("Error loading PPM: %d", err);
		return 1;
	}
  
  ctx->isPlaying = 0;
	ctx->startTime = 0;
	ctx->currentTime = 0;
  ctx->currentFrame = 0;
	ctx->numFrames = ctx->ppm->hdr.numFrames;
	ctx->loop = ctx->ppm->animHdr.flags.loop;
  
  ctx->layerPattern[0][0] = LUT_ppmDitherNone;
	ctx->layerPattern[0][1] = LUT_ppmDitherNone;
	ctx->layerPattern[0][2] = LUT_ppmDitherNone;
	ctx->layerPattern[1][0] = LUT_ppmDitherNone;
	ctx->layerPattern[1][1] = LUT_ppmDitherNone;
	ctx->layerPattern[1][2] = LUT_ppmDitherNone;

	ctx->stoppedCallback = NULL;

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
		ctx->masterAudioSample = pd->sound->sample->newSampleFromData((u8*)ctx->masterAudio, kSound16bitMono, OUTPUT_SAMPLE_RATE, audioTrackSize);
		ctx->audioPlayer = pd->sound->sampleplayer->newPlayer();
		pd->sound->sampleplayer->setSample(ctx->audioPlayer, ctx->masterAudioSample);
	}

  return 0;
}

void playerDone(player_ctx* ctx)
{
  ppmDone(ctx->ppm);
	pd_free(ctx->ppm);
  if (ctx->masterAudio != NULL)
	{
		pd->sound->sampleplayer->stop(ctx->audioPlayer);
		pd->sound->sampleplayer->freePlayer(ctx->audioPlayer);
		pd->sound->sample->freeSample(ctx->masterAudioSample);
		pd_free(ctx->masterAudio);
	}
	pd_free(ctx);
}

void playerSetLayerDithering(player_ctx* ctx, int layer, int colour, int pattern)
{
  switch (pattern)
	{
		case 1:
			ctx->layerPattern[layer][colour] = LUT_ppmDitherPolka;
			break;
		case 2:
			ctx->layerPattern[layer][colour] = LUT_ppmDitherChecker;
			break;
		case 3:
			ctx->layerPattern[layer][colour] = LUT_ppmDitherInvPolka;
			break;
    case 0:
		default:
			ctx->layerPattern[layer][colour] = LUT_ppmDitherNone;
	}
}

void playerSetFrame(player_ctx* ctx, int frame)
{
  if (ctx->loop)
		ctx->currentFrame = mod(frame, ctx->numFrames);
	else
		ctx->currentFrame = clamp(frame, 0, ctx->numFrames - 1);
	ctx->currentTime = ctx->currentFrame * (1.0 / (float)ctx->ppm->frameRate);
}

static void playerPlayAudio(player_ctx* ctx)
{
	if (ctx->masterAudio != NULL)
	{
		pd->sound->sampleplayer->stop(ctx->audioPlayer);
		pd->sound->sampleplayer->setOffset(ctx->audioPlayer, ctx->currentTime);
		pd->sound->sampleplayer->play(ctx->audioPlayer, 1, 1.0);
	}
}

void playerPlay(player_ctx* ctx)
{
	ctx->isPlaying = 1;
	pd->system->resetElapsedTime();
	ctx->startTime = -ctx->currentTime;
  playerPlayAudio(ctx);
}

void playerPause(player_ctx* ctx)
{
	ctx->isPlaying = 0;
  if (ctx->masterAudio != NULL)
		pd->sound->sampleplayer->stop(ctx->audioPlayer);
}

void playerUpdate(player_ctx* ctx)
{
  if (!ctx->isPlaying)
    return;

  ctx->currentTime = pd->system->getElapsedTime() - ctx->startTime;
  u16 frameIndex = (u16)floor(ctx->currentTime / (1.0 / (float)ctx->ppm->frameRate));
  
  if (frameIndex != ctx->currentFrame)
  {
    if (ctx->loop && frameIndex >= ctx->numFrames)
    {
			pd->system->resetElapsedTime();
			ctx->currentFrame = 0;
      ctx->startTime = 0;
      ctx->currentTime = 0;
			playerPlayAudio(ctx);
    }
		else if (frameIndex >= ctx->numFrames)
		{
			ctx->currentFrame = 0;
      ctx->currentTime = 0;
			if (ctx->stoppedCallback != NULL)
				doCallback(ctx->stoppedCallback, 1);
			ctx->isPlaying = 0;
		}
		else 
		{
			ctx->currentFrame = frameIndex;
		}	
		LCDRect dirtyRect = {ctx->x - 4, ctx->x + PPM_SCREEN_WIDTH + 4, ctx->y - 4, ctx->y + PPM_SCREEN_HEIGHT + 4};
		pd->sprite->addDirtyRect(dirtyRect);
  }
}