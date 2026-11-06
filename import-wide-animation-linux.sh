#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <animated-webp-url> <emote-name> [frame-sampling frame-offset]" >&2
    exit 2
}
[[ $# -eq 2 || $# -eq 4 ]] || usage
url=$1
name=$2

[[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "Error: emote name may contain only letters, numbers, _ and -." >&2; exit 2; }
if [[ $# -eq 4 ]]; then
    sampling=$3
    offset=$4
    [[ "$sampling" =~ ^[1-9][0-9]*$ && "$offset" =~ ^[0-9]+$ ]] || { echo "Error: frame-sampling must be positive and frame-offset non-negative." >&2; exit 2; }
fi
for cmd in curl magick anim_dump; do
    command -v "$cmd" >/dev/null || {
        echo "Missing dependency: $cmd. Install curl, imagemagick and libwebp-utils with: sudo pacman -S curl imagemagick libwebp-utils" >&2
        exit 1
    }
done
[[ -f emotes.lua ]] || { echo "Error: run this script from the project directory containing emotes.lua." >&2; exit 1; }
[[ -f animation.lua ]] || { echo "Error: animation.lua not found in the project directory." >&2; exit 1; }

mkdir -p emotes
rm -rf import
mkdir -p import
image_orig="import/$name.webp"
image_appended="import/$name-appended.webp"
image_final="emotes/$name.webp"

curl --fail --location --silent --show-error "$url" --output "$image_orig"
anim_dump -folder import "$image_orig"

shopt -s nullglob
all_frames=(import/dump_*.png)
num_available=${#all_frames[@]}
(( num_available > 0 )) || { echo "Error: anim_dump did not produce any PNG frames." >&2; exit 1; }

frames=()
if [[ $# -eq 4 ]]; then
    for ((i=offset; i<num_available; i+=sampling)); do
        frames+=("$(printf 'import/dump_%04d.png' "$i")")
    done
else
    frames=("${all_frames[@]}")
fi
(( ${#frames[@]} > 0 )) || { echo "Error: frame selection is empty." >&2; exit 1; }

magick "${frames[@]}" -resize "93x32" -background none -gravity center -append "$image_appended"

orig_h=$(magick identify -ping -format '%h' "$image_appended")
orig_w=$(magick identify -ping -format '%w' "$image_appended")
frames_count=$((orig_h / 32))
(( frames_count > 0 )) || { echo "Error: generated sprite sheet has no complete frames." >&2; exit 1; }

# Round the sprite-sheet height up to the next power of two.
final_h=1
while (( final_h < orig_h )); do final_h=$((final_h * 2)); done
final_w=1
while (( final_w < orig_w )); do final_w=$((final_w * 2)); done

magick "$image_appended" -background none -gravity North -extent "93x${final_h}" "$image_final"

emotes_newline='["'"$name"'"] = basePath .. "'"$name"'.tga:56:28",'
sed -i -e '$i\'"    $emotes_newline" emotes.lua

animation_newline="TwitchEmotes_animation_metadata[basePath .. \"$name.tga\"] = {[\"nFrames\"] = $frames_count, [\"frameWidth\"] = $orig_w, [\"frameHeight\"] = 32, [\"imageWidth\"] = $final_w, [\"imageHeight\"] = $final_h, [\"framerate\"] = 18}"
printf '%s\n' "$animation_newline" >> animation.lua
