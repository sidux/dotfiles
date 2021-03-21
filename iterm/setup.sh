#!/bin/sh

[ "$(uname -s)" != "Darwin" ] && exit 0

defaults write com.googlecode.iterm2 "PrefsCustomFolder" -string "$HOME/dotfiles/iterm"
defaults write com.googlecode.iterm2 "LoadPrefsFromCustomFolder" -bool true

cp ~/dotfiles/iterm/ItermQuake.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/.
