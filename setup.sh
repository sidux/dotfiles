#!/bin/bash

# Install nix if not present
if ! command -v nix &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
fi

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Warn if repo is not at ~/dotfiles (aliases and iTerm2 config expect this path)
EXPECTED_DIR="$HOME/dotfiles"
if [ "$SCRIPT_DIR" != "$EXPECTED_DIR" ]; then
    echo "Warning: this repo is at $SCRIPT_DIR but some config expects ~/dotfiles."
    echo "  - The 'nix-build' fish alias will point to $EXPECTED_DIR/setup.sh (broken)"
    echo "  - iTerm2 will look for preferences at $EXPECTED_DIR/iterm (broken)"
    read -rp "Continue anyway? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi

# Export hostname for flake (macOS doesn't set HOSTNAME by default)
export HOSTNAME=$(hostname -s)

# Prompt for git identity if not already set via environment
if [ -z "$GIT_USER_NAME" ]; then
    read -rp "Git user name [sidux]: " input_name
    export GIT_USER_NAME="${input_name:-}"
fi
if [ -z "$GIT_USER_EMAIL" ]; then
    read -rp "Git user email [ahmed.lebbada@gmail.com]: " input_email
    export GIT_USER_EMAIL="${input_email:-}"
fi

echo "Building nix-darwin for user: $USER, host: $HOSTNAME"

# Build and activate (--impure allows reading environment variables)
nix build "$SCRIPT_DIR#darwinConfigurations.$HOSTNAME.system" \
    --extra-experimental-features "nix-command flakes" \
    --impure

if [ -e ./result/sw/bin/darwin-rebuild ]; then
    sudo ./result/sw/bin/darwin-rebuild switch --flake "$SCRIPT_DIR#$HOSTNAME" --impure
else
    echo "Error: darwin-rebuild not found. Build may have failed."
    exit 1
fi
