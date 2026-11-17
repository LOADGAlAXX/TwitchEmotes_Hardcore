#!/usr/bin/env bash

set -Eeuo pipefail

# Run from the repository directory containing this script.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load release credentials/configuration.
if [[ ! -f ".env" ]]; then
    echo "Error: .env file not found." >&2
    exit 1
fi
# shellcheck disable=SC1091
source ".env"

if [[ -z "${CURSEFORGE_API_TOKEN:-}" ]]; then
    echo "Error: CURSEFORGE_API_TOKEN is not set in .env." >&2
    exit 1
fi

# Match build.sh's default stage.
stage="${1:-release}"

# Check required Linux commands.
for cmd in git gh curl awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: required command not found: %s\n' "$cmd" >&2
        exit 1
    fi
done

toc_file="TwitchEmotes_Hardcore.toc"

if [[ ! -f "$toc_file" ]]; then
    printf 'Error: required file not found: %s\n' "$toc_file" >&2
    exit 1
fi

version="$(awk '$1 == "##" && $2 == "Version:" { print $3; exit }' "$toc_file")"

if [[ -z "$version" ]]; then
    printf 'Error: could not read ## Version: from %s.\\n' "$toc_file" >&2
    exit 1
fi

version="${version}-${stage}"
archive="dist/TwitchEmotes_Hardcore-${version}.zip"
changelog="$version - Changed .toc structure to use only one file, added coloring to the name in the addons list, gave it an icon in the addons list, also changed o to require semicolon | !! THIS UPDATE REQUIRES A GAME RESTART DUE TO THE TOC CHANGES !!"

# Require a clean working tree.
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: Not all changes committed." >&2
    exit 1
fi

# Ensure all local commits are included in the configured upstream branch.
if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    echo "Error: current branch has no upstream configured." >&2
    exit 1
fi

if ! git merge-base --is-ancestor HEAD '@{u}'; then
    echo "Error: Not all commits merged/pushed to the upstream branch." >&2
    exit 1
fi

# Build the release archive.
if [[ ! -x "./build-linux.sh" ]]; then
    echo "Error: ./build-linux.sh is missing or not executable." >&2
    echo "Run: chmod +x build-linux.sh" >&2
    exit 1
fi

./build-linux-new.sh "$stage"

if [[ ! -f "$archive" ]]; then
    printf 'Error: build did not create expected archive: %s\n' "$archive" >&2
    exit 1
fi

# Create/update the annotated Git tag and push it to origin.
git tag -f -a "$version" -m "$version"
git push --force origin "refs/tags/$version"

# Publish the GitHub release.
gh release create \
    "$version" \
    --verify-tag \
    --title "TwitchEmotes Hardcore $version" \
    --notes "$changelog" \
    "$archive"

echo "Published version $version to GitHub"

# Upload the same archive to CurseForge.
metadata="$(cat <<EOF
{
    "changelog": "$changelog",
    "displayName": "TwitchEmotes Hardcore $version",
    "gameVersions": [17053, 16984, 16630, 16533, 16081, 16168],
    "releaseType": "$stage"
}
EOF
)"

curl --fail-with-body --show-error --silent \
    -H "X-Api-Token: $CURSEFORGE_API_TOKEN" \
    -F "metadata=$metadata" \
    -F "file=@$archive" \
    "https://wow.curseforge.com/api/projects/1019223/upload-file"

echo "Published version $version to CurseForge"
