#pragma once

#include "pd_api.h"
#include "ppm.h"

// allow up to 12 MB of memory to be used for audio
// (we have the space to spare!)
#define AUDIO_SIZE_LIMIT (12 * 1024 * 1024)

typedef struct player_ctx
{
	ppm_ctx_t* ppm;
	// drawing
	u16 x;
	u16 y;
	// ppm meta shorthands
	u16 numFrames;
	u8 loop;
	// ppm playback state
	u8 isPlaying;
	float startTime;
	float currentTime;
	u16 currentFrame;
	// ppm dither pattern per color per layer
	const u8* layerPattern[2][3];
	// ppm audio render
	s16* masterAudio;
	AudioSample* masterAudioSample;
	SamplePlayer* audioPlayer;
	// callback names
	// playdate SDK makes us call Lua functions by name...
	char* stoppedCallback;
} player_ctx;

player_ctx* playerNew(u16 x, u16 y);

void playerMoveTo(player_ctx* ctx, u16 x, u16 y);

int playerOpenPpm(player_ctx* ctx, const char* filePath);

void playerDone(player_ctx* ctx);

void playerSetLayerDithering(player_ctx* ctx, int layer, int colour, int pattern);

void playerSetFrame(player_ctx* ctx, int frame);

void playerPlay(player_ctx* ctx);

void playerUpdate(player_ctx* ctx);

void playerPause(player_ctx* ctx);