#!/usr/bin/env bash
set -euo pipefail

# Klaus installer — works both locally and via curl | bash
# Usage:
#   Local:  ./install.sh
#   Remote: curl -fsSL https://github.com/OWNER/klaus/releases/latest/download/install.sh | bash

KLAUS_ROOT="${KLAUS_ROOT:-$HOME/.klaus}"
KLAUS_INSTALL_DIR="$KLAUS_ROOT/install"
REPO="jtremback/klaus"

die() { echo "klaus: $*" >&2; exit 1; }

command -v docker &>/dev/null || die "Docker is required. Install it from https://docker.com"
command -v curl &>/dev/null || die "curl is required."

echo "klaus: installing to $KLAUS_ROOT..."

# Detect if running from a local repo checkout (./install.sh) vs piped (curl | bash).
# When piped, BASH_SOURCE[0] is empty.
LOCAL_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$LOCAL_DIR" ] && [ -f "$LOCAL_DIR/Dockerfile" ]; then
    echo "klaus: installing from local checkout..."
    mkdir -p "$KLAUS_INSTALL_DIR"
    cp "$LOCAL_DIR/klaus" "$KLAUS_INSTALL_DIR/"
    cp "$LOCAL_DIR/Dockerfile" "$KLAUS_INSTALL_DIR/"
    cp "$LOCAL_DIR/KLAUS.md" "$KLAUS_INSTALL_DIR/"
else
    echo "klaus: downloading latest release..."
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    RELEASE_URL="https://github.com/$REPO/releases/latest/download/klaus.tar.gz"
    curl -fsSL "$RELEASE_URL" -o "$TMPDIR/klaus.tar.gz" \
        || die "Failed to download release from $RELEASE_URL"
    mkdir -p "$KLAUS_INSTALL_DIR"
    tar -xzf "$TMPDIR/klaus.tar.gz" -C "$KLAUS_INSTALL_DIR"
fi

chmod +x "$KLAUS_INSTALL_DIR/klaus"

# Symlink to PATH
if [ -w /usr/local/bin ]; then
    BIN_DIR="/usr/local/bin"
else
    mkdir -p "$HOME/.local/bin"
    BIN_DIR="$HOME/.local/bin"
fi

ln -sf "$KLAUS_INSTALL_DIR/klaus" "$BIN_DIR/klaus"

# Add BIN_DIR to shell profile if not already in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -q "^${BIN_DIR}$"; then
    SHELL_NAME="$(basename "$SHELL")"
    case "$SHELL_NAME" in
        zsh)  PROFILE="$HOME/.zshrc" ;;
        bash) PROFILE="${HOME}/.bashrc" ;;
        *)    PROFILE="$HOME/.profile" ;;
    esac

    if ! grep -qF "$BIN_DIR" "$PROFILE" 2>/dev/null; then
        echo "" >> "$PROFILE"
        echo "# Added by klaus installer" >> "$PROFILE"
        echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "$PROFILE"
        echo "klaus: added $BIN_DIR to PATH in $PROFILE"
    fi
fi

# Build base image so first 'klaus' run is fast
echo "klaus: building Docker image..."
docker build -t klaus-base:latest \
    --build-arg USER_UID="$(id -u)" \
    "$KLAUS_INSTALL_DIR"

echo ""
echo "klaus: installed successfully!"
echo "  Run 'klaus' in any project directory to start a sandboxed Claude session."
echo "  Run 'klaus help' for usage info."
echo "  Run 'klaus uninstall' to remove."
