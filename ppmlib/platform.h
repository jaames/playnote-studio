#pragma once

#include <stddef.h>
#include <string.h>
#include "pd_api.h"

extern PlaydateAPI* pd;

#ifndef pd_alloc
#define pd_alloc(s) pd->system->realloc(NULL, (s))
#endif
#ifndef pd_malloc
#define pd_malloc(s) pd->system->realloc(NULL, (s))
#endif
#ifndef pd_calloc
#define pd_calloc(numEls, elSize) pd->system->realloc(NULL, ((numEls) * (elSize)))
#endif
#ifndef pd_realloc
#define pd_realloc pd->system->realloc
#endif
#ifndef pd_free
#define pd_free(ptr) pd->system->realloc((ptr), 0)
#endif

#ifndef pd_log
#define pd_log(s, ...) pd->system->logToConsole((s), ##__VA_ARGS__)
#endif

#ifndef pd_error
#define pd_error(s, ...) pd->system->error((s), ##__VA_ARGS__)
#endif