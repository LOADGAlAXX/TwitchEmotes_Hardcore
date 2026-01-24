#!/bin/bash

. .env

set -euo pipefail

rm -rf import && mkdir import
image_orig="import/$2.webp"
image_appended="import/$2-appended.webp"
image_final="emotes/$2.webp"

curl "$1" -o "$image_orig"

anim_dump -folder import "$image_orig"

num_frames=$(ls -l import/dump_* | wc -l)
if [ $# -ge 4 ] ; then
    frame_sampling=$3
    frame_offset=$4
    i=$frame_offset
    n=$num_frames
    num_frames=0

    frames=()
    while [ $i -lt $n ]; do
        frames+=( $(printf "import/dump_%04d.png" $i) )
        i=$(($i + $frame_sampling))
        num_frames=$(($num_frames + 1))
    done

    # TODO: Resize frames
    magick ${frames[@]} -resize "32x32" -append "$image_appended"
else
    # TODO: Resize frames
    magick import/dump_* -resize "32x32" -background none -gravity center -extent "32x32" -append "$image_appended"
fi

orig_h=$(magick identify -ping -format '%h' "$image_appended")
orig_w=$(magick identify -ping -format '%w' "$image_appended")

frames=$(($orig_h/32))

# Round h up to the next power of 2
final_h=$(($orig_h-1))
final_h=$(($final_h|($final_h>>1)))
final_h=$(($final_h|($final_h>>2)))
final_h=$(($final_h|($final_h>>4)))
final_h=$(($final_h|($final_h>>8)))
final_h=$(($final_h|($final_h>>16)))
final_h=$(($final_h|($final_h>>32)))
final_h=$(($final_h+1))

final_w=$(($orig_w-1))
final_w=$(($final_w|($final_w>>1)))
final_w=$(($final_w|($final_w>>2)))
final_w=$(($final_w|($final_w>>4)))
final_w=$(($final_w|($final_w>>8)))
final_w=$(($final_w|($final_w>>16)))
final_w=$(($final_w|($final_w>>32)))
final_w=$(($final_w+1))

magick "$image_appended" -background none -gravity North -extent "32x${final_h}" "$image_final"

emotes_newline='["'$2'"] = basePath .. "'$2'.tga:28:28",'
sed -i -e '$i\'"    $emotes_newline" emotes.lua

animation_newline="TwitchEmotes_animation_metadata[basePath .. \"$2.tga\"] = {[\"nFrames\"] = $frames, [\"frameWidth\"] = $orig_w, [\"frameHeight\"] = 32, [\"imageWidth\"] = $final_w, [\"imageHeight\"] = $final_h, [\"framerate\"] = 18}";
echo "$animation_newline" >> animation.lua
