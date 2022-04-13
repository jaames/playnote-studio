#pragma once

#include "pd_api.h"
#include "tmb.h"

typedef struct tmblib_ctx
{
	tmb_ctx_t* tmb;
	LCDBitmap* bitmap;
	char* ppmPath;
} tmblib_ctx;

extern void registerTmblib(void);