#pragma once

#include <stddef.h>
#include <string.h>
#include "pd_api.h"

extern PlaydateAPI* pd;

// memory management
#define pd_alloc(s) pd->system->realloc(NULL, (s))
#define pd_malloc(s) pd->system->realloc(NULL, (s))
// NOTE: pd_calloc does not initialise mem to 0, need to use memset() afterwards
#define pd_calloc(numEls, elSize) pd->system->realloc(NULL, ((numEls) * (elSize)))
#define pd_realloc pd->system->realloc
#define pd_free(ptr) pd->system->realloc((ptr), 0)

// loging
#define pd_log(s, ...) pd->system->logToConsole((s), ##__VA_ARGS__)

#define pd_error(s, ...) pd->system->error((s), ##__VA_ARGS__)