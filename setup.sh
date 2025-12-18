#!/bin/bash

# Install nix if not present
if ! command -v nix &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
fi

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Export hostname for flake (macOS doesn't set HOSTNAME by default)
export HOSTNAME=$(hostname -s)

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
