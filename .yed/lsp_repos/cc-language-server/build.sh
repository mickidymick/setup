#!/usr/bin/env bash

sudo apt -y bear install clang cmake libclang-dev llvm-dev rapidjson-dev
cmake -H. -BRelease
cmake --build Release

cd Release
sudo make install
