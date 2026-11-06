#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <image-url> <emote-name> [size]" >&2
    exit 2
}
[[ $# -ge 2 && $# -le 3 ]] || usage
url=$1
name=$2
size=${3:-32}

[[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "Error: emote name may contain only letters, numbers, _ and -." >&2; exit 2; }
[[ "$size" =~ ^[1-9][0-9]*$ ]] || { echo "Error: size must be a positive integer." >&2; exit 2; }
command -v curl >/dev/null || { echo "Missing dependency: curl (install with: sudo pacman -S curl)" >&2; exit 1; }
command -v magick >/dev/null || { echo "Missing dependency: ImageMagick (install with: sudo pacman -S imagemagick)" >&2; exit 1; }
[[ -f emotes.lua ]] || { echo "Error: run this script from the project directory containing emotes.lua." >&2; exit 1; }

mkdir -p emotes
image="emotes/$name.webp"

url=$(printf '%s' "$url" | sed -E "s/(size=)[0-9]+/\\1$size/")
curl --fail --location --silent --show-error "$url" --output "$image"
magick "$image" -background none -gravity center -resize "${size}x${size}" "$image"

newline='["'"$name"'"] = basePath .. "'"$name"'.tga:28:28",'
sed -i -e '$i\'"    $newline" emotes.lua
