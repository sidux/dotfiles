#!/bin/bash

# Path to your flake.nix file
FLAKE_FILE="$HOME/dotfiles/flake.nix"

# Get the current hostname
CURRENT_HOSTNAME=$(hostname -s)
CURRENT_USER=$(whoami)

echo "Current hostname: $CURRENT_HOSTNAME"

# Temporary file for sed operation
TEMP_FILE=$(mktemp)

sed -e "s/\"<host>\"/\"$CURRENT_HOSTNAME\"/g" \
    -e "s/\"<user>\"/\"$CURRENT_USER\"/g" "$FLAKE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$FLAKE_FILE"

echo "Hostname updated in flake.nix"

# Build and activate the configuration
nix --extra-experimental-features "nix-command flakes" build ".#darwinConfigurations.$CURRENT_HOSTNAME.system"

if [ -e ./result/sw/bin/darwin-rebuild ]; then
    ./result/sw/bin/darwin-rebuild switch --flake ".#$CURRENT_HOSTNAME"
else
    echo "Error: darwin-rebuild not found in expected location. The build may have failed."
fi

sed -e "s/\"$CURRENT_HOSTNAME\"/\"<host>\"/g" \
    -e "s/\"$CURRENT_USER\"/\"<user>\"/g" "$FLAKE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$FLAKE_FILE"

echo "Hostname restored in flake.nix"
