#!/usr/bin/env bash
set -euo pipefail

# Klaus installer — works both locally and via curl | bash
# Usage:
#   Local:  ./install.sh
#   Remote: curl -fsSL https://github.com/jtremback/klaus/releases/latest/download/install.sh | bash

KLAUS_ROOT="${KLAUS_ROOT:-$HOME/.klaus}"
KLAUS_INSTALL_DIR="$KLAUS_ROOT/install"
REPO="jtremback/klaus"

die() { echo "klaus: $*" >&2; exit 1; }

command -v docker &>/dev/null || die "Docker is required. Install it from https://docker.com"
command -v git &>/dev/null || die "git is required."

echo "klaus: installing to $KLAUS_ROOT..."

# Detect if running from a local repo checkout (./install.sh) vs piped (curl | bash).
LOCAL_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$LOCAL_DIR" ] && [ -f "$LOCAL_DIR/Dockerfile" ]; then
    # Local install — clone from the local repo
    echo "klaus: installing from local checkout..."
    if [ -d "$KLAUS_INSTALL_DIR/.git" ]; then
        git -C "$KLAUS_INSTALL_DIR" pull --ff-only 2>/dev/null || true
    else
        rm -rf "$KLAUS_INSTALL_DIR"
        git clone "$LOCAL_DIR" "$KLAUS_INSTALL_DIR"
    fi
else
    # Remote install — clone from GitHub
    echo "klaus: cloning from GitHub..."
    if [ -d "$KLAUS_INSTALL_DIR/.git" ]; then
        git -C "$KLAUS_INSTALL_DIR" pull --ff-only 2>/dev/null || true
    else
        rm -rf "$KLAUS_INSTALL_DIR"
        git clone "https://github.com/$REPO.git" "$KLAUS_INSTALL_DIR"
    fi
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

# Update Klaus rules file if sandbox exists (safe to overwrite — it's application code)
KLAUS_CLAUDE_HOME="$KLAUS_ROOT/claude"
if [ -d "$KLAUS_CLAUDE_HOME/rules" ]; then
    cp "$KLAUS_INSTALL_DIR/KLAUS.md" "$KLAUS_CLAUDE_HOME/rules/klaus.md"
fi

# Build base image so first 'klaus' run is fast
echo "klaus: building Docker image..."
docker build -t klaus-base:latest \
    --build-arg USER_UID="$(id -u)" \
    --build-arg GIT_USER_NAME="$(git config --global user.name 2>/dev/null || echo 'Klaus Sandbox')" \
    --build-arg GIT_USER_EMAIL="$(git config --global user.email 2>/dev/null || echo 'klaus@sandbox')" \
    "$KLAUS_INSTALL_DIR"

echo ""
echo "klaus: installed successfully!"
echo "  Run 'klaus' in any project directory to start a sandboxed Claude session."
echo "  Run 'klaus help' for usage info."
echo "  Run 'klaus uninstall' to remove."
