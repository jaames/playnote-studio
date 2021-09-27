
#!/bin/bash
# this is just here for my convenience, because I am an idiot

CMD=$1

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
  echo "creating simulator build..."
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=/Users/james1/Developer/PlaydateSDK/C_API/buildsupport/arm.cmake ..
  make
  cd -
  make pdc
fi

if [ $CMD == "clean" ]; then
  cd build
  make clean
  cd -
fi

exit 0