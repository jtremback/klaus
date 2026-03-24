#!/usr/bin/env bash
set -euo pipefail

# Creates a release tarball and optionally publishes to GitHub.
# Reads version from the klaus script.
# Usage:
#   ./release.sh              # create tarball only
#   ./release.sh --push       # create tarball and publish GitHub release

VERSION="$(grep '^KLAUS_VERSION=' klaus | cut -d'"' -f2)"
[ -n "$VERSION" ] || { echo "Could not read version from klaus script"; exit 1; }

PUSH="${1:-}"
TARBALL="klaus.tar.gz"

echo "klaus: creating release v$VERSION..."

tar -czf "$TARBALL" \
    klaus \
    Dockerfile \
    KLAUS.md

echo "  created $TARBALL"

if [ "$PUSH" = "--push" ]; then
    command -v gh &>/dev/null || { echo "gh CLI required for --push"; exit 1; }

    git tag -a "v$VERSION" -m "Release v$VERSION"
    git push origin "v$VERSION"

    gh release create "v$VERSION" \
        --title "v$VERSION" \
        --generate-notes \
        "$TARBALL" \
        install.sh

    echo "  published GitHub release v$VERSION"
else
    echo "  run with --push to publish to GitHub"
fi
