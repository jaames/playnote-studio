## TODO

- Intro theme
- sfx: dialog open, crank tick, crank docked/undocked, Flipnote view page not allowed, Note list page slide / page not allowed, Flipnote view crank forward / crank back, Multiple dither swatch sounds
- Sound effect bug in pekira note
- Sound doesn't restart after loop
- Credits lag when song kicks in
- Credits autoscroll speed adjust
- Scrolling on Settings should change selection
- Buttons should have gfx for when they've been clicked
- Website
- Add DSi username chars to font
- Redraw hiragana and katakana?
- Function to delete sample notes
- Create a PPM test suite to verify against

## Playnote Studio

Play Flipnote Studio animations on your Playdate!

## Features

- Play any Flipnote animation file created with the DSiWare version of Flipnote Studio, just drop the files from your DSi's SD card into your Playdate's storage!
- Use the Playdate's crank to smoothly scroll through frames!
- Comes bundled with a bunch of sample Flipnotes kindly provided by from some of the best artists in the Flipnote community, such as [Kéké](twitter.com/Kekeflipnote), [ペキラ (Pekira)](twitter.com/pekira1227), [MrJohn](flipnot.es/9F990EE00074AC4D), [bokeh f/2 (who cares)](www.instagram.com/gsupnet_) and many more!
- Available in English, Japanese, French, German, Italian, Dutch, Polish, Russian, and... Welsh!
- Pretty UI with thumbnail lists, folder selection, settings screen, etc -- all accompanied by custom-made sound effects!

## Credits

If you wish to use parts of this repo in your own project, please be sure to credit the right people:

- *any lua or web code, UI design elements, image assets or the 3d playdate model* - [James Daniel](https://github.com/jaames)
- *ppmlib code* - [Simon Aarons](https://github.com/simontime) and [James Daniel](https://github.com/jaames)
- *sound effects* - TODO
- *Flipnote Studio screenshots* - [Austin Burk](https://twitter.com/AustinSudomemo)

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

- Memory management functions like `alloc`, `malloc`, `realloc`, `free`, etc are not available - instead you will need to include `pd.h` which contains `pd_alloc`, `pd_malloc`, `pd_realloc` and `pd_free`. These all wrap `playdate->system->realloc` and should behave the same as their respective functions.