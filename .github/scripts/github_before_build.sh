#!/bin/bash -eux

# Simple script for downloading, unpacking, and getting ready to build Ungoogled-Chromium macOS binaries on GitHub Actions

_root=$(dirname "$(greadlink -f "$0")")
_cache="$_root/build/download_cache"
_src="$_root/build/src"

mkdir -p "$_src"
hdiutil create -type SPARSEBUNDLE -size 20g -fs APFS -volname build_src -nospotlight -verbose ./build_src.sparsebundle
hdiutil attach ./build_src.sparsebundle -mountpoint "$_src" -nobrowse -noverify -noautoopen -noautofsck

mdutil -i off ./build_src.sparsebundle
rm -rfv ./build_src.sparsebundle/.{,_.}{fseventsd,Spotlight-V*,Trashes} || true
mkdir -pv ./build_src.sparsebundle/.fseventsd
touch ./build_src.sparsebundle/.fseventsd/no_log ./build_src.sparsebundle/.metadata_never_index ./build_src.sparsebundle/.Trashes

rm -rf "$_src/out" || true
mkdir -p "$_src/out/Default"
mkdir -p "$_cache"

"$_root/utils/downloads.py" retrieve -i "$_root/downloads.ini" -c "$_cache"
"$_root/utils/downloads.py" unpack -i "$_root/downloads.ini" -c "$_cache" "$_src"
"$_root/utils/prune_binaries.py" "$_src" "$_root/pruning.list"
"$_root/utils/patches.py" apply "$_src" "$_root/patches"
"$_root/utils/domain_substitution.py" apply -r "$_root/domain_regex.list" -f "$_root/domain_substitution.list" -c "$_root/build/domsubcache.tar.gz" "$_src"
cp "$_root/args.gn" "$_src/out/Default/"

cd "$_src"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args

rm -rvf "$_cache" "$_root/build/domsubcache.tar.gz"
