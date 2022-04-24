#include "tmb.h"
#include "platform.h"

tmb_ctx_t* tmbNew()
{
	tmb_ctx_t* ctx = pd_malloc(sizeof(tmb_ctx_t));
	ctx->bitmap = NULL;
	ctx->file = NULL;
	ctx->filePath = NULL;
	ctx->lastError = NULL;
	return ctx;
}

static void closeWithError(tmb_ctx_t* ctx, const char* msg)
{
	if (ctx->lastError != NULL)
		pd_free(ctx->lastError);
	ctx->lastError = NULL;
	pd->system->formatString(&ctx->lastError, "Thumbnail load error\n%s\n%s", ctx->filePath, msg);
	pd_log(ctx->lastError);
	pd->file->close(ctx->file);
	ctx->file = NULL;
	ctx->filePath = NULL;
}

static int errorHandledFileRead(tmb_ctx_t* ctx, void* buf, unsigned int len, const char* errorMsg)
{
	int res = pd->file->read(ctx->file, buf, len);
	if (res == -1)
	{
		const char* fileErr = pd->file->geterr();
		char* err = NULL;
		pd->system->formatString(&err, "%s\n%s", errorMsg, fileErr);
		closeWithError(ctx, err);
		return -1;
	}
	else if (len > 0 && res != len)
	{
		closeWithError(ctx, errorMsg);
		return -1;
	}
	return 0;
}

int tmbOpen(tmb_ctx_t* ctx, const char* filePath)
{
	SDFile* file;
	int readResult;

	file = pd->file->open(filePath, kFileRead | kFileReadData);
	if (file == NULL)
	{
		const char* fileErr = pd->file->geterr();
		char* err = NULL;
		pd->system->formatString(&err, "Couldn't open file (%s)", fileErr);
		closeWithError(ctx, err);
		return -1;
	}

	ctx->file = file;
	ctx->filePath = filePath;

	readResult = errorHandledFileRead(ctx, &ctx->hdr, sizeof(ppm_header_t), "Couldn't read header");
	if (readResult == -1)
		return -1;

	if (strncmp(ctx->hdr.magic, "PARA", 4) != 0)
	{
		closeWithError(ctx, "Invalid format");
		return -1;
	}

	readResult = errorHandledFileRead(ctx, ctx->thumbnail, sizeof(ctx->thumbnail), "Couldn't read thumb bitmap");
	if (readResult == -1)
		return -1;

	pd->file->close(file);
	ctx->file = NULL;
	// keep filePath
	return 0;
}

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

void tmbDone(tmb_ctx_t* ctx)
{
	if (ctx->filePath != NULL)
	{
		pd_free(ctx->filePath);
		ctx->filePath = NULL;
	}

	if (ctx->lastError != NULL)
	{
		pd_free(ctx->lastError);
		ctx->lastError = NULL;
	}

	if (ctx->bitmap != NULL)
	{
		pd->graphics->freeBitmap(ctx->bitmap);
		ctx->bitmap = NULL;
	}
}