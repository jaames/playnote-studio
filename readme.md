## TODO

- sfx: redo dialog open, Flipnote view page not allowed, Note list page slide / page not allowed
- Scrolling on Settings should change selection
- Website
- Add all special chars that can be used in a DSi username to font
- Redraw hiragana and katakana?
- Create a PPM test suite to verify against

## Playnote Studio

Play Flipnote Studio animations on your Playdate!

## Features

- Play any Flipnote animation file created with the DSiWare version of Flipnote Studio, just drop the files from your DSi's SD card into your Playdate's storage!
- Use the Playdate's crank to smoothly scroll through frames!
- Comes bundled with a bunch of sample Flipnotes kindly provided by from some of the best artists in the Flipnote community, such as [Kéké](twitter.com/Kekeflipnote), [ペキラ (Pekira)](twitter.com/pekira1227), [MrJohn](flipnot.es/9F990EE00074AC4D), [bokeh f/2 (who cares)](www.instagram.com/gsupnet_) and many more!
- Available in 10 languages: English, Japanese, French, Spanish, German, Italian, Dutch, Polish, Russian, and... Welsh!
- Pretty UI with thumbnail lists, folder selection, settings screen, etc -- all accompanied by custom-made sound effects!

## Credits

If you wish to use parts of this repo in your own project, please be sure to credit the right people:

- *Lua or web code, UI design elements, image assets or the 3d playdate model* - [James](https://github.com/jaames)
- *C Flipinote parser* - [Simon](https://github.com/simontime) and [James](https://github.com/jaames)
- *Sound effects* - Talon Stradley
- *Flipnote Studio screenshots* - [Austin](https://twitter.com/AustinSudomemo), [Rob]()

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

#### C

Memory management functions like `alloc`, `malloc`, `realloc`, `free`, etc are not available - instead you will need to include `pd.h` which contains `pd_alloc`, `pd_malloc`, `pd_realloc` and `pd_free`. These all wrap `playdate->system->realloc` and should behave the same as their respective functions.

#### Website Video

The website interactive demo uses a transparent video, at two resolutions which will get served depending on device pixel ratio. The 3D Playdate model is rendered out as a series of RGBA PNGs for each frame, which needs to be converted to a transparent VP9 webm video. Since the demo sets the video's currentTime manually, for smoothness we set the framerate to 1 FPS and keyframe interval is set to every 2 frames.
- **2x** `ffmpeg -framerate 1 -i "./%04d.png" -c:v libvpx-vp9 -g 2 -pix_fmt yuva420p output_2x.webm`.
- **1x** `ffmpeg -framerate 1 -i "./%04d.png" -vf scale=iw/2:ih/2 -c:v libvpx-vp9 -g 2 -pix_fmt yuva420p output_1x.webm`.

Because Apple is a very competent browser vendor, we also have to encode a separate alpha HEVC video for Safari...
- **2x**
  - `ffmpeg -framerate 1 -i "./%04d.png" -c:v prores_ks -pix_fmt yuva444p10le -profile:v 4444 -alpha_bits 8 output_2x.mov`
  - Right-click the output .mov, go to Services > Encode Selected Video Files. In the modal that opens, the format should be `HEVC 2160p` and `Preserve Transparency` should also be checked. 
- **1x**
  - `ffmpeg -framerate 1 -i "./%04d.png" -vf scale=iw/2:ih/2 -c:v prores_ks -pix_fmt yuva444p10le -profile:v 4444 -alpha_bits 8 output_1x.mov`
  - Right-click the output .mov, go to Services > Encode Selected Video Files. In the modal that opens, the format should be `HEVC 1080p` and `Preserve Transparency` should also be checked. 