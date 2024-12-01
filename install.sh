#!/bin/bash

set -euo pipefail

source .env || true

case $1 in
    retail)
        wow_addon_path="${WOW_ADDONS_RETAIL:-/c/Program Files (x86)/World of Warcraft/_retail_/Interface/Addons}"
        ;;
    classic)
        wow_addon_path="${WOW_ADDONS_CLASSIC_ERA:-/c/World of Warcraft/_classic_era_/Interface/AddOns}"
        ;;
    *)
        echo "Unknown wow version $1"
        exit 1
        ;;
esac

addon_build_path="dist/TwitchEmotes_Hardcore"

[ -d "$addon_build_path" ] || {
    echo "'$addon_build_path' does not exist. Please run ./build.sh first"
    exit 1
}

[ -d "$wow_addon_path" ] || {
    echo "'$wow_addon_path' does not exist"
    exit 1
}

rm -rf "$wow_addon_path/TwitchEmotes_Hardcore"

cp -r "$addon_build_path" "$wow_addon_path"
