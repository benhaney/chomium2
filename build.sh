#!/bin/bash -eux

# Simple build script for macOS

_root=$(dirname "$(greadlink -f "$0")")
_download_cache="$_root/build/download_cache"
_src="$_root/build/src"

# For packaging
_chromium_version=$(cat "$_root/chromium_version.txt")
_ungoogled_revision=$(cat "$_root/revision.txt")
_package_revision=$(cat "$_root/revision.txt")

rm -rf "$_src/out" || true
mkdir -p "$_src/out/Default"
mkdir -p "$_download_cache"
rm -f "$_root/build/domsubcache.tar.gz"

"$_root/utils/downloads.py" retrieve -i "$_root/downloads.ini" "$_root/llvm_download.ini" -c "$_download_cache"
"$_root/utils/downloads.py" unpack -i "$_root/downloads.ini" "$_root/llvm_download.ini" -c "$_download_cache" "$_src"
exit
"$_root/utils/prune_binaries.py" "$_src" "$_root/pruning.list"
"$_root/utils/patches.py" apply "$_src" "$_root/patches"
"$_root/utils/domain_substitution.py" apply -r "$_root/domain_regex.list" -f "$_root/domain_substitution.list" -c "$_root/build/domsubcache.tar.gz" "$_src"
cp "$_root/args.gn" "$_src/out/Default/"

cd "$_src"

chmod +x ./tools/gn/bootstrap/bootstrap.py
./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args
ninja -C out/Default chrome

chrome/installer/mac/pkg-dmg \
  --sourcefile --source out/Default/Chromium.app \
  --target "$_root/build/ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_macos.dmg" \
  --volname Chromium --symlink /Applications:/Applications \
  --format UDBZ --verbosity 2

# Fix issue where macOS requests permission for incoming network connections
# See https://github.com/ungoogled-software/ungoogled-chromium-macos/issues/17
xattr -csr out/Default/Chromium.app
# Using ad-hoc signing
codesign --force --deep --sign - out/Default/Chromium.app
