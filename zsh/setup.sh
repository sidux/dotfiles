#!/bin/sh

if ! grep -q 'source ~/dotfiles/zsh/.zshrc' ~/.zshrc; then
  echo 'source ~/dotfiles/zsh/.zshrc' >> ~/.zshrc
fi;
