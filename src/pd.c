#include "pd.h"

void *(*pd_realloc)(void* ptr, size_t size);

void pd_setRealloc(void *(*realloc)(void *ptr, size_t size))
{
	pd_realloc = realloc;
}

void *pd_calloc(size_t numElem, size_t elSize)
{
	void *p;
	p = pd_malloc(numElem * elSize);
	if (p == 0)
		return (p);
	memset(p, 0, numElem * elSize);
	return (p);
}