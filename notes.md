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