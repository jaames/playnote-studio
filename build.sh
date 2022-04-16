
#!/bin/bash
# this is just here for my convenience, because I am an idiot

# REPLACE WITH THE NAME OF YOUR PLAYDATE GAME PDX
GAME="Playnote.pdx"
# SDK installer writes the install location to ~/.Playdate/config
SDK = ${PLAYDATE_SDK_PATH}
ifeq ($(SDK),)
SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
endif
CMD=$1

if [ -z $CMD ]; then
  echo "No command provided"
  exit 1
fi

if [ $CMD == "sim" ]; then
  echo "compiling simulator build..."
  cd build
  cmake ..
  make
  cd ..
fi

if [ $CMD == "dev" ]; then
  echo "compiling dev device build..."
  # compile C
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=${SDK}/C_API/buildsupport/arm.cmake ..
  make
  # compile lua and assets
  cd ..
  make pdc
  # copy to Playdate Simulator disk location
  cp -a ./${GAME} ${SDK}/Disk/Games/${GAME}
fi

if [ $CMD == "build" ]; then
  echo "compiling prod device build..."
  # compile C
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=${SDK}/C_API/buildsupport/arm.cmake ..
  make
  cd ..
  # compile lua and assets, tell pdc to compile lua without debug symbols
  pdc -s Source ${GAME}
  # assumes that you import all the files your game uses into main.lua
  # strip unused .pdz files
  find ./${GAME} -name "*.pdz" -type f -depth 2 -delete
  find ./${GAME} -name "*.pdz" -not -name "main.pdz" -type f -delete
  # remove simulator binaries that aren't needed for a device-only build
  find ./${GAME} -name "*.dylib" -type f -delete
  find ./${GAME} -name "*.dll" -type f -delete
  # cleapup empty directories
  find ./${GAME} -empty -type d -delete
  # zip result, skipping pesky DS_Store files
  zip -vr ./${GAME}.zip ./${GAME}/ -x "*.DS_Store"
fi

if [ $CMD == "lua" ]; then
  echo "compiling lua changes..."
  make pdc
fi

if [ $CMD == "clean" ]; then
  cd build
  make clean
  cd ..
fi

if [ $CMD == "reset" ]; then
  rm -rf ./build/*
fi

if [ $CMD == "release" ]; then
  if [ -z $2 ]; then
    echo "Specify a release version (e.g. 1.0.0)"
    exit 1
  fi
  ./build.sh build
  gh release create v${2} --draft "./${GAME}.zip#Playnote Studio for Playdate"
  rm ./${GAME}.zip
fi

exit 0