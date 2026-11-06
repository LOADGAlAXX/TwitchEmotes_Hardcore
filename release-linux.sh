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

mainline_toc="TwitchEmotes_Hardcore-Mainline.toc"
classic_toc="TwitchEmotes_Hardcore-Classic.toc"

for file in "$mainline_toc" "$classic_toc"; do
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
archive="dist/TwitchEmotes_Hardcore-${version}.zip"
changelog="$version - Code fixes for forever (No more 50 billion errors in boss fight, but also no emotes in boss fight)"

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
if [[ ! -x "./build.sh" ]]; then
    echo "Error: ./build.sh is missing or not executable." >&2
    echo "Run: chmod +x build.sh" >&2
    exit 1
fi

./build.sh "$stage"

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
