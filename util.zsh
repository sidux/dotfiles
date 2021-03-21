#!/bin/bash

function info() {
  # shellcheck disable=SC2059
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

function user() {
  # shellcheck disable=SC2059
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

function success() {
  # shellcheck disable=SC2059
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

function fail() {
  # shellcheck disable=SC2059
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

function bundle() {
  local repo=$1
  local repo_url="https://github.com/$repo.git"
  local repo_path="${ZDOTDIR:-$HOME}/.zsh/$repo"
  local name="${repo_path##*/}"

  declare -a arr=("$repo_path/$name.plugin.zsh" "$repo_path/init.zsh" "$repo_path/init.sh" "$repo_path/$name.zsh" "$repo_path/$name.sh")

  if [[ ! -d "$repo_path" ]]; then
    if ! git ls-remote -q "$repo_url" >/dev/null; then
      echo "Module $repo does not exist."
      return 1
    fi
    git clone --recursive "$repo_url" "$repo_path"
  fi

  for file in "${arr[@]}"; do
    if [[ -s "$file" ]]; then
      source "$file"
      return 0
    fi
  done
  rm -rf "$repo_path"
  echo "Module $repo is not supported."
  return 1
}
