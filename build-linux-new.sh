#!/usr/bin/env bash

set -Eeuo pipefail

# Run from the directory containing this script, regardless of the caller's cwd.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

stage="${1:-release}"

toc_file="TwitchEmotes_Hardcore.toc"

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

if [[ ! -f "$toc_file" ]]; then
    printf 'Error: required file not found: %s\n' "$toc_file" >&2
    exit 1
fi

version="$(awk '$1 == "##" && $2 == "Version:" { print $3; exit }' "$toc_file")"

if [[ -z "$version" ]]; then
    printf 'Error: could not read version from %s.\n' "$toc_file" >&2
    exit 1
fi

version="${version}-${stage}"

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
cp -- "$toc_file" "$dist_dir/"

# Create a Linux-native ZIP archive.
(
    cd "$dist_root"
    zip -qr "${zip_name##*/}" "TwitchEmotes_Hardcore"
)

printf 'Build complete: %s\n' "$zip_name"
