#pragma once

#include "ppm.h"
#include "types.h"

typedef struct tmb_ctx_t
{
	ppm_header_t hdr;
	u8 thumbnail[PPM_THUMBNAIL_LENGTH];
	LCDBitmap* bitmap;
	// open function state
	SDFile* file;
	char* filePath;
	char* lastError;
} tmb_ctx_t;

tmb_ctx_t* tmbNew();
int        tmbOpen(tmb_ctx_t* ctx, const char* filePath);
int        tmbInit(tmb_ctx_t* ctx, u8* ppm, int len);
void       tmbGetThumbnail(tmb_ctx_t* ctx, u8* out);
void       tmbDone(tmb_ctx_t* ctx);