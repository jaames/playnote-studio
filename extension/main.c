#include "pd_api.h"
#include "../ppmlib/ppmlib.h"

PlaydateAPI *pd = NULL;

int eventHandler(PlaydateAPI *playdate, PDSystemEvent event, uint32_t arg) {
  if(event == kEventInitLua) {
    pd = playdate;
    registerPpmlib();
  }
  return 0;
}