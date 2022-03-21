#include <string.h>

#include "pd_api.h"

#include "utils.h"
#include "platform.h"
#include "types.h"

char* pd_strdup(const char* str)
{
  size_t len = strlen(str);
  char* s = pd_malloc(len + 1);
  memcpy(s, str, len);
  s[len] = '\0';
  return s;
}

int clamp(int n, int l, int h)
{
	if (n < l) return l;
	if (n > h) return h;
	return n;
}

int mod(int x, int n)
{
  return (x % n + n) % n;
}