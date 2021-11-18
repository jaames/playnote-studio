#pragma once

#include "types.h"

static const u32 ppmThumbnailPalette[] = 
{
	// grays
	0xFFFFFFFF, 0xFF525252, 0xFFFFFFFF, 0xFF9C9C9C,
	// reds (last 1 unused)
	0xFFFF4844, 0xFFC851FC, 0xFFFFADAC, 0xFF00FF00,
	// blues (last 1 unused)
	0xFF4840FF, 0xFF514FB8, 0xFFADABFF, 0xFF00FF00,
	// purple (last 3 unused)
	0xFFB657B7, 0xFF00FF00, 0xFF00FF00, 0xFF00FF00
};

// 0 = black, 1 = dark gray, 2 = mid gray, 3 = light gray, 4 = white
static const u8 ppmThumbnailPaletteGray[] =
{
	4, 0, 4, 2,
	1, 0, 3, 2,
	2, 1, 3, 2,
	2, 2, 2, 2
};

static const u32 ppmPaperPalette[] =
{ 0xFF0E0E0E, 0xFFFFFFFF };

static const u32 ppmPenPalette[] =
{ 0, 1, 0xFFFF2A2A, 0xFF0A39FF };