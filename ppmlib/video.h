#pragma once

#include "types.h"
#include "ppm.h"

#include <string.h>

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

void ppmVideoDecodeFrame(ppm_ctx_t* ctx, u16 frame, int preventDecodingPrev);

// int ppmVideoRenderFrame(ppm_ctx_t* ctx, u32* out, u16 frame);