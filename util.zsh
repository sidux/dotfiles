#!/bin/bash

function bundle() {
  local repo=$1
  local repo_url="https://github.com/$repo.git"
  local repo_path="${ZDOTDIR:-$HOME}/.zsh/$repo"
  local name="${repo_path##*/}"

  declare -a arr=("$repo_path/init.zsh" "$repo_path/init.sh" "$repo_path/$name.zsh" "$repo_path/$name.sh")

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
  echo "Module $repo is not supported."
  return 1
}
