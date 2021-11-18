#pragma once

#define _CRT_SECURE_NO_WARNINGS

#ifdef _MSC_VER
#define __builtin_bswap32(x) _byteswap_ulong(x)
#endif

#define THUMBNAIL_WIDTH  64
#define THUMBNAIL_HEIGHT 48
#define THUMBNAIL_LENGTH ((THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT) / 2)

#define SCREEN_WIDTH  256
#define SCREEN_HEIGHT 192
#define SCREEN_SIZE   (SCREEN_WIDTH * SCREEN_HEIGHT)

#define SE_CHANNELS 3
#define LAYERS      2

#define PIXEL(x, y) (((y) * SCREEN_WIDTH) + (x))
#define ROUND_UP_4(n) (((n) + 3) & ~3)

#define MAKE_RGBA(r, g, b, a) (((a) << 24) | ((b) << 16) | ((g) << 8) | (r)) 

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pd_api.h"

#include "palette.h"
#include "types.h"

static const float speedTable[] =
{ 0.0f, 0.5f, 1.0f, 2.0f, 4.0f, 6.0f, 12.0f, 20.0f, 30.0f };

#pragma pack(push)
#pragma pack(1)

typedef struct ppm_frame_header_t
{
	u8 paperColour  : 1;
	u8 layer1Colour : 2;
	u8 layer2Colour : 2;
	u8 doMove       : 2;
	u8 isKeyFrame   : 1;
} ppm_frame_header_t;

typedef struct ppm_header_t
{
	char magic[4];
	u32  animationLength;
	u32  soundLength;
	u16  numFrames;
	u16  unknown;
	u16  isLocked;
	u16  thumbIndex;
	u16  originalCreator[11];
	u16  previousEditor[11];
	u16  currentEditor[11];
	u8   previousEditorId[8];
	u8   currentEditorId[8];
	u8   originalFilename[18];
	u8   currentFilename[18];
	u8   originalCreatorId[8];
	u8   fileId[8];
	u32  timeStamp;
	u16  pad;
} ppm_header_t;

typedef struct ppm_animation_header_t
{
	u16 tableLength;
	u16 pad;
	u32 flags;
} ppm_animation_header_t;

typedef struct ppm_sound_header_t
{
	u32 bgmLength;
	u32 seLength[3];
	u8  playbackSpeed;
	u8  recordedSpeed;
	u8  pad[14];
} ppm_sound_header_t;

typedef struct ppm_ctx_t
{
	ppm_header_t           hdr;
	ppm_animation_header_t animHdr;
	ppm_sound_header_t     sndHdr;
	u8  thumbnail[THUMBNAIL_LENGTH];
	u8  *audioFrames;
	u32 *videoOffsets;
	u8  *bgmData;
	u8  *seData[3];
	u8  *videoData;
	u8  *layers[LAYERS];
	u8  *prevLayers[LAYERS];
	s16 prevFrame;
	u8  layerColours[LAYERS];
	u8  paperColour;
	float frameRate;
	float bgmFrameRate;
} ppm_ctx_t;

typedef struct tmb_ctx_t
{
	ppm_header_t hdr;
	u8 thumbnail[THUMBNAIL_LENGTH];
} tmb_ctx_t;

#pragma pack(pop)

int  ppmInit(ppm_ctx_t *ctx, u8 *ppm, int len);
// void ppmGetThumbnail(ppm_ctx_t *ctx, u32 *out);
void ppmDone(ppm_ctx_t *ctx);
int  tmbInit(tmb_ctx_t *ctx, u8 *ppm, int len);
void tmbGetThumbnail(tmb_ctx_t *ctx, u8 *out);
void tmbDone(tmb_ctx_t *ctx);
char *fsidFromStr(u8 fsid[8]);