#include "tmb.h"
#include "platform.h"

// just parses enough of the ppm to get the tmb (thumbnail + meta) data
int tmbInit(tmb_ctx_t* ctx, u8* ppm, int len)
{
	u8* start = ppm;
	
	if (len < sizeof(ppm_header_t))
		return 0;

	memcpy(&ctx->hdr, ppm, sizeof(ppm_header_t));
	ppm += sizeof(ppm_header_t);
	
	if (strncmp(ctx->hdr.magic, "PARA", 4) != 0)
	{
		pd_log("Invalid PPM magic");
		return 1;
	}

	if (ppm - start + sizeof(ctx->thumbnail) > len)
	{
		pd_log("PPM too small for thumbnail data size");
		return 2;
	}

	memcpy(ctx->thumbnail, ppm, sizeof(ctx->thumbnail));
	ppm += sizeof(ctx->thumbnail);

	return -1;
}

void tmbGetThumbnail(tmb_ctx_t* ctx, u8* out)
{
	u8* rawData = ctx->thumbnail;

	for (int y = 0; y < 48; y += 8)
	for (int x = 0; x < 64; x += 8)
	for (int l = 0; l <  8; l += 1)
	for (int p = 0; p <  8; p += 2)
	{
		out[(y + l) * 64 + (x + p + 0)] = *rawData  & 0xf;
		out[(y + l) * 64 + (x + p + 1)] = *rawData++ >> 4;
	}
}