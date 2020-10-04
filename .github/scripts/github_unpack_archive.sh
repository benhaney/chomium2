#!/bin/bash -eux

# Unpacking script for GitHub Actions

echo "Checking sha256sum of archive:"
sha256sum -c sums.txt

_root=$(dirname "$(greadlink -f "$0")")
_src="$_root/build/src"
_cache="$_root/build/download_cache"
mkdir -p "$_src"

# zstd -d --rm ./build_src.sparsebundle.tar.zst
zstd -c -d ./build_src.sparsebundle.tar.zst | tar -x -f -
rm -v ./build_src.sparsebundle.tar.zst

ls -lrt
echo "Mounting build/src folder"
hdiutil attach ./build_src.sparsebundle -mountpoint "$_src" -nobrowse -noverify -noautoopen -noautofsck

if [[ ! -d "$_src/third_party/llvm-build/Release+Asserts/" ]]; then
  mkdir -p "$_cache"
  "$_root/utils/downloads.py" retrieve -i "$_root/llvm_download.ini" -c "$_cache"
  "$_root/utils/downloads.py" unpack -i "$_root/llvm_download.ini" -c "$_cache" "$_src"
fi
