
#!/bin/bash
# this is just here for my convenience, because I am an idiot

CMD=$1
SDK=$(egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)

if [ -z $CMD ]; then
  echo "No command provided"
  exit 1
fi

if [ $CMD == "sim" ]; then
  echo "creating simulator build..."
  cd build
  cmake ..
  make
  cd -
fi

if [ $CMD == "device" ]; then
  echo "creating device build..."
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=${SDK}/C_API/buildsupport/arm.cmake ..
  make
  cd -
  make pdc
fi

if [ $CMD == "clean" ]; then
  cd build
  make clean
  cd -
fi

if [ $CMD == "reset" ]; then
  rm -rf ./build/*
fi

exit 0