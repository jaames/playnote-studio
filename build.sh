
#!/bin/bash
# this is just here for my convenience, because I am an idiot

CMD=$1
SDK=$(egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
PRODUCT="Playnote.pdx"

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
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=${SDK}/C_API/buildsupport/arm.cmake ..
  make
  cd ..
  make pdc
fi

if [ $CMD == "build" ]; then
  echo "compiling prod device build..."
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=${SDK}/C_API/buildsupport/arm.cmake ..
  make
  cd ..
  # tell pdc to compile lua without debug symbols
  pdc -s Source ${PRODUCT}
  # strip unused .pdz files and macOS C binaries
  find ./${PRODUCT} -name "*.pdz" -type f -depth 2 -delete
  find ./${PRODUCT} -name "*.dylib" -type f -delete
  find ./${PRODUCT} -empty -type d -delete
  # zip result, skipping pesky DS_Store files
  zip -vr ./${PRODUCT}.zip ./${PRODUCT}/ -x "*.DS_Store"
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
  ./build.sh build
  zip -r ./Playnote.pdx.zip ./Playnote.pdx
  gh release create v${2} --draft './Playnote.pdx.zip#Playnote PDX'
  rm ./Playnote.pdx.zip
fi

exit 0