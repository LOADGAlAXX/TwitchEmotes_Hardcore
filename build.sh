#!/bin/bash

set -euo pipefail

stage=${1:-release}

version_mainline=$(grep "Version: " TwitchEmotes_Hardcore-Mainline.toc | cut -d ' ' -f 3)
version_classic=$(grep "Version: " TwitchEmotes_Hardcore-Classic.toc | cut -d ' ' -f 3)

[ "$version_mainline" == "$version_classic" ] || {
    echo "Error: TwitchEmotes_Hardcore-Mainline.toc is version $version_mainline, but TwitchEmotes_Hardcore-Classic.toc is version $version_classic"
    exit 1
}

version="$version_mainline-$stage"

dist_root="dist"
dist_dir="$dist_root/TwitchEmotes_Hardcore"
zip_name="$dist_root/TwitchEmotes_Hardcore-$version.zip"

rm -rf "$dist_root"
mkdir -p "$dist_dir"
mkdir "$dist_dir/emotes"
for img in emotes/*.webp ; do magick "$img" "$dist_dir/${img%.*}.tga" ; done
cp *.lua "$dist_dir"
cp TwitchEmotes_Hardcore-Mainline.toc "$dist_dir"
cp TwitchEmotes_Hardcore-Classic.toc "$dist_dir"
cp TwitchEmotes_Hardcore-TBC.toc "$dist_dir"

powershell Compress-Archive "$dist_dir" "$zip_name"
