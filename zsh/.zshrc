autoload -Uz compinit
re_initialize=0
for match in $zcompdump*(.Nmh+24); do
  re_initialize=1
  break
done

if [ "$re_initialized" -eq "1" ]; then
  compinit
  # update the timestamp on compdump file
  compdump
else
  # omit the check for new functions since we updated today
  compinit -C
fi

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
alias afk='open -a /System/Library/CoreServices/ScreenSaverEngine.app'
alias pr='gh pr create --web'
