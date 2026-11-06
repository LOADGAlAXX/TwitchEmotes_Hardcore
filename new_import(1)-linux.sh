#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <image-url-or-7tv-emote-url> <emote-name> [size]" >&2
    exit 2
}
[[ $# -ge 2 && $# -le 3 ]] || usage
url=$1
name=$2
size=${3:-64}

[[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "Error: emote name may contain only letters, numbers, _ and -." >&2; exit 2; }
[[ "$size" =~ ^[1-9][0-9]*$ ]] || { echo "Error: size must be a positive integer." >&2; exit 2; }
command -v curl >/dev/null || { echo "Missing dependency: curl (install with: sudo pacman -S curl)" >&2; exit 1; }
command -v magick >/dev/null || { echo "Missing dependency: ImageMagick (install with: sudo pacman -S imagemagick)" >&2; exit 1; }
[[ -f emotes.lua ]] || { echo "Error: run this script from the project directory containing emotes.lua." >&2; exit 1; }

mkdir -p emotes
image="emotes/$name.webp"

if [[ "$url" == https://7tv.app/emotes/* ]]; then
    image_id=${url%/}
    image_id=${image_id##*/}
    [[ -n "$image_id" ]] || { echo "Error: could not determine 7TV emote ID from URL." >&2; exit 2; }
    download_url="https://cdn.7tv.app/emote/$image_id/2x.webp"
else
    download_url=$(printf '%s' "$url" | sed -E "s/(size=)[0-9]+/\\1$size/")
fi

curl --fail --location --silent --show-error "$download_url" --output "$image"
magick "$image" -resize "64x64" -background none -gravity center -extent "64x64" "$image"

newline='["'"$name"'"] = basePath .. "'"$name"'.tga:28:28",'
sed -i -e '$i\'"    $newline" emotes.lua
