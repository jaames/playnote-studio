#ifndef _d_glue_h
#define _d_glue_h

#include <stdio.h>
#include "pd_api.h"

#include "ppm.h"
#include "ppm_video.h"

#define ROUND_UP_4(n) (((n) + 3) & ~3)

void registerExt(PlaydateAPI *playdate);

#endif /* _d_glue_h */