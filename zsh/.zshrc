autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then

	compinit;
else
	compinit -C;
fi;

# Execute code only if STDERR is bound to a TTY.
if [[ -o INTERACTIVE && -t 2 ]]; then
  # Print a random, hopefully interesting, adage.
  if (( $+commands[fortune] )); then
    fortune -s
    print
  fi
fi >&2

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) ]]; then
  source ~/dotfiles/zsh/.zprofile
fi

source ~/dotfiles/util.zsh
source ~/dotfiles/iterm/.iterm2_shell_integration.zsh
source ~/dotfiles/zsh/plugin/symfony.plugin.zsh
source ~/dotfiles/zsh/.zpreztorc

source ~/dotfiles/zsh/"${ZSH_BUNDLER:-prezto}".zshrc

alias xdebug='php -dzend_extension=xdebug.so'
alias pcov='php -dextension=pcov'
