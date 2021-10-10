## TODO

- Player timeline bar
- Player counter
- Player play/pause with timer
- Player crank playback
- Player frame-by-frame
- Player support for Flipnotes that use a black bg
- Player support for dithering red/blue colors to contrast them against the pen color
- Player audio
- Bundle sample Flipnotes and add credits for the creators

## Playnote Studio

Play animations from the DSiWare version of Flipnote Studio on your Playdate!

## Special Thanks

- [Simon](https://github.com/simontime) for kindly letting me use his C PPM library and answering my dumb C questions while I was trying to port it to the Playdate.
- [Matt](https://github.com/gingerbeardman) for helping me get access to the Playdate Developer Preview!

## Building

You will need to have the Playdate SDK, cmake, make, and clang installed.

For convenience (and because I'm a big dumb-dumb idiot that keeps forgetting things) I made a bash utility script for running various compilation commands in the right sequence:

 - **`./build.sh sim`** - Produces a .pdx build that will run in the Playdate Simulator, but won't run on device
 - **`./build.sh device`** - Produces a .pdx build that will run in the Playdate Simulator and will run on device
 - **`./build.sh lua`** - Produces a .pdx build that will run on device, but skips C compilation for faster Lua development
 - **`./build.sh clean`** - Runs `make clean`
 - **`./build.sh refresh`** - Sometimes the compiler doesn't seem to update the embedded C code when doing a new build, or it will produce an empty pdex.bin. I'm not entirely sure what causes this, but this command should clean up any build files so that things will behave again after this happens.

### Notes

- Memory management functions like `malloc`, `calloc`, `realloc`, `free`, etc are not available - instead you will need to include `pd.h` which contains `pd_malloc`, `pd_calloc`, `pd_realloc` and `pd_free`, which all wrap `playdate->system->realloc` and should behave the same as their respective functions.