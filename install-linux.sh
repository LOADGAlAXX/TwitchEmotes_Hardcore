#!/usr/bin/env bash
set -euo pipefail

# Linux AddOns directory supplied by the user.
default_addons_path="/gamedisk/World of Warcraft/_forever_/Interface/AddOns"

# Optional overrides can be set in .env or in the environment.
if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <retail|classic>" >&2
    exit 2
fi

case "$1" in
    retail)
        wow_addon_path="${WOW_ADDONS_RETAIL:-$default_addons_path}"
        ;;
    classic)
        wow_addon_path="${WOW_ADDONS_CLASSIC_ERA:-$default_addons_path}"
        ;;
    *)
        echo "Unknown WoW version: $1 (expected retail or classic)" >&2
        exit 2
        ;;
esac

addon_build_path="dist/TwitchEmotes_Hardcore"
addon_name="TwitchEmotes_Hardcore"

if [[ ! -d "$addon_build_path" ]]; then
    echo "'$addon_build_path' does not exist. Please run ./build.sh first." >&2
    exit 1
fi

if [[ ! -d "$wow_addon_path" ]]; then
    echo "AddOns directory '$wow_addon_path' does not exist." >&2
    echo "Check that the drive is mounted and the path is correct." >&2
    exit 1
fi

# Replace the installed addon with the freshly built version.
rm -rf -- "$wow_addon_path/$addon_name"
cp -a -- "$addon_build_path" "$wow_addon_path/"
echo "Installed $addon_name to: $wow_addon_path"
