#!/bin/bash

CMD=$1

if [ -z $CMD ]; then
  echo "No command provided"
  exit 1
fi

if [ $CMD == "build" ]; then
  echo "creating production build..."
  pdc -s ./source ./build/Playnote.pdx
fi

if [ $CMD == "dev" ]; then
  echo "creating development build..."
  pdc ./source ./build/Playnote.pdx
fi

if [ $CMD == "watch" ]; then
  echo "watching ./source folder for changes..."
  fswatch -o ./source | xargs -n1 -I{} pdc ./source ./build/Playnote.pdx
fi

exit 0