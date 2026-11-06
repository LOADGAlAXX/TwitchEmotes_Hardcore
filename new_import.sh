#!/bin/bash

set -euo pipefail

image="emotes/$2.webp"

if [[ "$1" == "https://7tv.app/emotes/"* ]]; then
    image_id=$(echo "${1##*/}")
    url="https://cdn.7tv.app/emote/$image_id/2x.webp"
    curl "$url" -o "emotes/$2.webp"
else
    size=${3:-64}
    url=$(echo "$1" | sed "s/size=[[:digit:]]\+/size=$size/")
    curl "$url" -o "emotes/$2.webp"
fi

# magick "$image" -background none -gravity center -resize "${size}x${size}" "$image"

# second number is width
magick "$image" -resize "64x64" -background none -gravity center -extent "64x64" "$image"

newline='["'$2'"] = basePath .. "'$2'.tga:28:28",'

# Insert before the last line (before the closing bracket)
sed -i -e '$i\'"    $newline" emotes.lua
