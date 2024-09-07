#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Path to your flake.nix file
FLAKE_FILE="$HOME/dotfiles/flake.nix"

# Get the current hostname
CURRENT_HOSTNAME=$(hostname -s)

echo "Current hostname: $CURRENT_HOSTNAME"

# Temporary file for sed operation
TEMP_FILE=$(mktemp)

# Replace "my_hostname" with the current hostname
sed "s/\"my_hostname\"/\"$CURRENT_HOSTNAME\"/g" "$FLAKE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$FLAKE_FILE"

echo "Hostname updated in flake.nix"

# Build and activate the configuration
nix --extra-experimental-features "nix-command flakes" build ".#darwinConfigurations.$CURRENT_HOSTNAME.system"

if [ -e ./result/sw/bin/darwin-rebuild ]; then
    ./result/sw/bin/darwin-rebuild switch --flake ".#$CURRENT_HOSTNAME"
else
    echo "Error: darwin-rebuild not found in expected location. The build may have failed."
    exit 1
fi

# Replace the hostname back to "my_hostname"
sed "s/\"$CURRENT_HOSTNAME\"/\"my_hostname\"/g" "$FLAKE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$FLAKE_FILE"

echo "Configuration updated and hostname restored in flake.nix"