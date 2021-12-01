# Exports
export ZSH="$HOME/.oh-my-zsh"
export GPG_TTY=$(tty)
export LANG=de_DE.UTF-8
export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"
  [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"
export PATH="/usr/local/sbin:$PATH"

source "$ZSH/oh-my-zsh.sh"

# Aliases
alias shfmt="docker run --rm -v $PWD:/work tmknom/shfmt -w -s $1"

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH="$HOME/Library/Caches/heroku/autocomplete/zsh_setup" && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;

# Config
plugins=(git docker docker-compose composer)
source /usr/local/opt/powerlevel10k/powerlevel10k.zsh-theme
