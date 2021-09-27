#include "pd.h"

void *(*pd_realloc)(void* ptr, size_t size);

void pd_setRealloc(void *(*realloc)(void *ptr, size_t size))
{
	pd_realloc = realloc;
}

void *pd_calloc(size_t nelem, size_t elsize)
{
	void *p;
	p = pd_malloc(nelem * elsize);
	if (p == 0)
		return (p);
	memset(p, 0, nelem * elsize);
	return (p);
}