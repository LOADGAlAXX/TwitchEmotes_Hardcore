#!/bin/bash

set -euo pipefail

source .env

stage=${1:-}

version_mainline=$(grep "Version: " TwitchEmotes_Hardcore-Mainline.toc | cut -d ' ' -f 3)
version_classic=$(grep "Version: " TwitchEmotes_Hardcore-Classic.toc | cut -d ' ' -f 3)

[ "$version_mainline" == "$version_classic" ] || {
    echo "Error: TwitchEmotes_Hardcore-Mainline.toc is version $version_mainline, but TwitchEmotes_Hardcore-Classic.toc is version $version_classic"
    exit 1
}

version="$version_mainline-$stage"

[[ -z $(git status -s) ]] || {
    echo "Error: Not all changes committed"
    exit 1
}

git merge-base --is-ancestor HEAD @{u} || {
    echo "Error: Not all commits merged"
    exit 1
}

./build.sh "$stage"

git tag -f -a "$version" -m "$version"
git push origin --tags "$version"

gh release create \
    "$version" \
    --verify-tag \
    --title "TwitchEmotes Hardcore $version" \
    --notes "TwitchEmotes Hardcore $version - edited COT, SummoningTheDemons, FADEDTHANAHOE, FADEDTHANAGLORP | removed punish | added glorpGang, DESKCHAN" \
    "dist/TwitchEmotes_Hardcore-$version.zip"

echo "Published version $version to GitHub"

# Get version numbers from running this, they're likely at the end of the list.
# (. .env && curl  -H "X-Api-Token: $CURSEFORGE_API_TOKEN" https://wow.curseforge.com/api/game/versions)

metadata=$(cat <<EOF
{
    "changelog": "$version edited COT, SummoningTheDemons, FADEDTHANAHOE, FADEDTHANAGLORP | removed punish | added glorpGang, DESKCHAN",
    "displayName": "TwitchEmotes Hardcore $version",
    "gameVersions": [12216, 12215, 11925, 10272],
    "releaseType": "$stage"
}
EOF
)

curl \
    -H "X-Api-Token: $CURSEFORGE_API_TOKEN" \
    -F metadata="$metadata" \
    -F file="@dist/TwitchEmotes_Hardcore-$version.zip" \
    https://wow.curseforge.com/api/projects/1019223/upload-file

echo "Published version $version to CurseForge"
