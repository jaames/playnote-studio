#pragma once

#include "ppm.h"
#include "types.h"

typedef struct tmb_ctx_t
{
	ppm_header_t hdr;
	u8 thumbnail[THUMBNAIL_LENGTH];
} tmb_ctx_t;

int  tmbInit(tmb_ctx_t* ctx, u8* ppm, int len);
void tmbGetThumbnail(tmb_ctx_t* ctx, u8* out);
void tmbDone(tmb_ctx_t* ctx);