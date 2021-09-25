#include "luaglue.h"

#include "pd_api.h"

static PlaydateAPI* pd = NULL;

static const lua_reg libPpm[];
static int testFunction(lua_State* L);

void registerExt(PlaydateAPI* playdate)
{
	pd = playdate;
	
	const char* err;
	
	if (!pd->lua->registerClass("PpmParser", libPpm, NULL, 0, &err))
		pd->system->logToConsole("%s:%i: registerClass failed, %s", __FILE__, __LINE__, err);

	if (!pd->lua->addFunction(testFunction, "playdate.testFunction", &err))
		pd->system->logToConsole("%s:%i: addFunction failed, %s", __FILE__, __LINE__, err);
}

static int ppm_new(lua_State* L)
{
	return 0;
}

static int ppm_test(lua_State* L)
{
	char* str = "Please god I hope this works";
	pd->lua->pushString(str);
  return 1;
}

static int ppm_gc(lua_State* L)
{
  return 0;
}

static const lua_reg libPpm[] =
{
	{ "__gc",			ppm_gc },
	{ "new",			ppm_new },
	{ "test",			ppm_test },
	{ NULL,				NULL }
};

static int testFunction(lua_State* L)
{
	const char* arg = pd->lua->getArgString(1);

	char* str;

	pd->system->formatString(&str, "Hello, %s!", (char*)arg);

	pd->lua->pushString(str); // push a string onto the lua stack (will be returned as the result of the funcion call in lua)

	// release it
	pd->system->realloc(str, 0);
		
	return 1; // number of things you pushed to the stack
}