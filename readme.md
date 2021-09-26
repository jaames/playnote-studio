# Building

I'm an extreme beginner with C, so I could only get this compile with cmake on mac. If you're one of those weird people that actually understands all this stuff please feel free to make a very elaborate issue thread pointing out all of my mistakes!

To build with Cmake manually do the following from the root of the project:

```
mkdir build
cd build
cmake ..
make
This will produce a PDX that’s ready to run on the simulator.
```
When you want to build for the device do this:

```
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=<path to SDK>/C_API/buildsupport/arm.cmake ..
make
```