echo 'Using antigen ...'

if [[ ! -s "${ZDOTDIR:-$HOME}/antigen.zsh" ]]; then
    curl -L git.io/antigen > "${ZDOTDIR:-$HOME}"/antigen.zsh
fi

source "${ZDOTDIR:-$HOME}"/antigen.zsh

antigen use prezto

antigen bundle zsh-users/zsh-apple-touchbar
antigen bundle supercrabtree/k

antigen apply
