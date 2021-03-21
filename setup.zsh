#!/bin/sh

DOTFILES_ROOT=$(pwd -P)

export DOTFILES_ROOT

set -e
shopt -s nullglob

for script in "$DOTFILES_ROOT"/*/setup.sh; do
  ./"$script"
done
