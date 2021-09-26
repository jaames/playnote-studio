#pragma once

#include "types.h"
#include "ppm.h"

#include <string.h>

void ppmVideoDecodeFrame(ppm_ctx_t *ctx, u16 frame);

int ppmVideoRenderFrame(ppm_ctx_t *ctx, u32 *out, u16 frame);