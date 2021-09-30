
#!/bin/bash
# this is just here for my convenience, because I am an idiot

CMD=$1
SDK=$(egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)

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

if [ $CMD == "device" ]; then
  echo "compiling device build..."
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=${SDK}/C_API/buildsupport/arm.cmake ..
  make
  cd ..
  make pdc
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
    echo "Specify a release version (e.g. v1.0.0)"
    exit 1
  fi
  ./build.sh device
  zip -r ./Playnote.pdx.zip ./Playnote.pdx
  gh release create v${2} --draft './Playnote.pdx.zip#Playnote PDX'
  rm ./Playnote.pdx.zip
fi

exit 0