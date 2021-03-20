#!/bin/bash

function bundle() {
  local repo=$1
  local repo_url="https://github.com/$repo.git"
  local path="${ZDOTDIR:-$HOME}/.zsh/$repo"
  local name="${path##*/}"

  declare -a arr=("$path/init.zsh" "$path/init.sh" "$path/$name.zsh" "$path/$name.sh")

  if [[ ! -d "$path" ]]; then
    if ! /usr/local/bin/git ls-remote -q "$repo_url" >/dev/null; then
      echo "Module $repo does not exist."
      return 1
    fi
    /usr/local/bin/git clone --recursive "$repo_url" "$path"
  fi

  for file in "${arr[@]}"; do
    if [[ -s "$file" ]]; then
      source "$file"
      return 0
    fi
  done
  echo "Module $repo is not supported."
  return 1
}
