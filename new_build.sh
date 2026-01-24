#!/bin/bash

set -euo pipefail

stage=${1:-release}

version_mainline=$(grep "Version: " TwitchEmotes_Hardcore-Mainline.toc | cut -d ' ' -f 3)
version_classic=$(grep "Version: " TwitchEmotes_Hardcore-Classic.toc | cut -d ' ' -f 3)

[ "$version_mainline" == "$version_classic" ] || {
    echo "Error: TwitchEmotes_Coomer-Mainline.toc is version $version_mainline, but TwitchEmotes_Coomer-Classic.toc is version $version_classic"
    exit 1
}

version="$version_mainline-$stage"

dist_root="dist"
dist_dir="TwitchEmotes_Hardcore"
zip_name="TwitchEmotes_Hardcore-$version.zip"

# make build

rm -f "$dist_root/$zip_name"
(cd "$dist_root" && "/c/Program Files/7-Zip/7z" a "$zip_name" "$dist_dir")
