## TODO

- Player play/pause with timer
- Audio play/pause
- Make dithering settings screen pretty
- Dither settings per note
- Add DSi username chars to font
- Function to delete sample notes
- Flipnote details screen
- Get audio design in
- Get translators in
- launchSoundPath in pdxinfo
- Create a PPM test suite to verify against
- Instructions for loading PPMs in settings? or on the "no flipnotes in folder" view?
- Website

## Playnote Studio

Play animations from the DSiWare version of Flipnote Studio on your Playdate!

## Special Thanks

- All of the Flipnote artists who kindly granted me permission to include some of their works as sample notes:
  - [Kéké](twitter.com/Kekeflipnote)
  - [MrJohn](flipnot.es/9F990EE00074AC4D)
  - [bokeh f/2 (who cares)](www.instagram.com/gsupnet_)
  - [ペキラ (Pekira)](twitter.com/pekira1227)
- [Simon](https://github.com/simontime) for kindly letting me use his C PPM library and answering my dumb C questions while I was trying to port it to the Playdate.
- [Lauren](https://github.com/thejsa) and [Ezekiel](https://github.com/Stary2001) for additional C tips
- Rob and Austin from [Sudomemo](https://www.sudomemo.net/) for helping me reach out to various Flipnote artists, and for the cross-promo
- [Matt](https://github.com/gingerbeardman) for helping me get into to the Playdate Developer Preview

## Building

You will need to have the Playdate SDK, cmake, make, and clang installed.

For convenience (and because I'm a big dumb-dumb idiot that keeps forgetting things) I made a bash utility script for running various compilation commands in the right sequence:

 - **`./build.sh sim`** - Produces a .pdx build that will run in the Playdate Simulator, but won't run on device
 - **`./build.sh dev`** - Produces a .pdx build that will run in the Playdate Simulator and will run on device
 - **`./build.sh build`** - Produces a .pdx build that will only run on device, and strips junk
 - **`./build.sh lua`** - Produces a .pdx build that will run on device, but skips C compilation for faster Lua development
 - **`./build.sh clean`** - Runs `make clean`
 - **`./build.sh refresh`** - Sometimes the compiler doesn't seem to update the embedded C code when doing a new build, or it will produce an empty pdex.bin. I'm not entirely sure what causes this, but this command should clean up any build files so that things will behave again.

### Notes

- Memory management functions like `malloc`, `calloc`, `realloc`, `free`, etc are not available - instead you will need to include `pd.h` which contains `pd_malloc`, `pd_calloc`, `pd_realloc` and `pd_free`, which all wrap `playdate->system->realloc` and should behave the same as their respective functions.