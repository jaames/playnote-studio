#include <stdio.h>
#include <stdlib.h>

#include "pd_api.h"
#include "luaglue.h"

int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
	if (event == kEventInitLua)
		registerExt(playdate);
	
	return 0;
}
