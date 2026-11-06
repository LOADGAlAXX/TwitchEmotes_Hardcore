#!/usr/bin/env bash

set -Eeuo pipefail

# Run from the directory containing this script, regardless of the caller's cwd.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

stage="${1:-release}"

mainline_toc="TwitchEmotes_Hardcore-Mainline.toc"
classic_toc="TwitchEmotes_Hardcore-Classic.toc"
tbc_toc="TwitchEmotes_Hardcore-TBC.toc"

# Check required tools.
for cmd in grep cut cp mkdir rm zip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: required command not found: %s\n' "$cmd" >&2
        exit 1
    fi
done

# Prefer ImageMagick 7's "magick", but support ImageMagick 6's "convert".
if command -v magick >/dev/null 2>&1; then
    IMAGE_CONVERT=(magick)
elif command -v convert >/dev/null 2>&1; then
    IMAGE_CONVERT=(convert)
else
    echo "Error: ImageMagick is required (install ImageMagick)." >&2
    exit 1
fi

for file in "$mainline_toc" "$classic_toc" "$tbc_toc"; do
    if [[ ! -f "$file" ]]; then
        printf 'Error: required file not found: %s\n' "$file" >&2
        exit 1
    fi
done

version_mainline="$(awk '$1 == "##" && $2 == "Version:" { print $3; exit }' "$mainline_toc")"
version_classic="$(awk '$1 == "##" && $2 == "Version:" { print $3; exit }' "$classic_toc")"

if [[ -z "$version_mainline" || -z "$version_classic" ]]; then
    echo "Error: could not read version from the TOC files." >&2
    exit 1
fi

if [[ "$version_mainline" != "$version_classic" ]]; then
    printf 'Error: %s is version %s, but %s is version %s\n' \
        "$mainline_toc" "$version_mainline" \
        "$classic_toc" "$version_classic" >&2
    exit 1
fi

version="${version_mainline}-${stage}"

dist_root="dist"
dist_dir="$dist_root/TwitchEmotes_Hardcore"
zip_name="$dist_root/TwitchEmotes_Hardcore-${version}.zip"

if [[ ! -d "emotes" ]]; then
    echo "Error: emotes directory not found." >&2
    exit 1
fi

shopt -s nullglob
images=(emotes/*.webp)
shopt -u nullglob

if (( ${#images[@]} == 0 )); then
    echo "Error: no .webp images found in emotes/." >&2
    exit 1
fi

# Recreate the distribution directory.
rm -rf -- "$dist_root"
mkdir -p -- "$dist_dir/emotes"

# Convert WebP images to TGA.
for img in "${images[@]}"; do
    output_file="$dist_dir/${img%.*}.tga"
    "${IMAGE_CONVERT[@]}" "$img" "$output_file"
done

# Copy addon files.
lua_files=( *.lua )
if (( ${#lua_files[@]} == 0 )); then
    echo "Error: no Lua files found." >&2
    exit 1
fi

cp -- "${lua_files[@]}" "$dist_dir/"
cp -- "$mainline_toc" "$classic_toc" "$tbc_toc" "$dist_dir/"

# Create a Linux-native ZIP archive.
(
    cd "$dist_root"
    zip -qr "${zip_name##*/}" "TwitchEmotes_Hardcore"
)

printf 'Build complete: %s\n' "$zip_name"
