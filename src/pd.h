#ifndef pd_h
#define pd_h

#include <stddef.h>
#include <string.h>

extern void* (*pd_realloc)(void* ptr, size_t size);

#define pd_malloc(s) pd_realloc(NULL, (s))
#define pd_free(ptr) pd_realloc((ptr), 0)

void pd_setRealloc(void* (*realloc)(void* ptr, size_t size));

void *pd_calloc(size_t nelem, size_t elsize);

#endif /* pd_h */
