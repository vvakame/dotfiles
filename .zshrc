autoload -U compinit
compinit

export DOTFILES=$HOME/dotfiles

### antigen
source $DOTFILES/antigen/antigen.zsh

antigen use oh-my-zsh
# antigen update

# Terminalでの入力に色がつく http://blog.glidenote.com/blog/2012/12/15/zsh-syntax-highlighting/
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
# mvnで入力補完が効くようになる https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins#mvn
# antigen bundle mvn
antigen bundle z

antigen theme vvakame/dotfiles themes/vv-custom
antigen apply

### Environment Variables
export LANG=ja_JP.UTF-8
export EDITOR=vi

export HOMEBREW_CASK_OPTS="--appdir=/Applications"
[ -s /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"

if [ `uname` = "Darwin" ]; then
  export JAVA_HOME=$(/usr/libexec/java_home)
fi
export _JAVA_OPTIONS="-Dfile.encoding=UTF-8"

if [ `uname` = "Darwin" ]; then
  export GOPATH=$HOME/work/gopath
  # export GOROOT=$(brew --prefix go)/libexec
  export PATH=$PATH:$GOPATH/bin
fi

# GAE
# export APPENGINE_DEV_APPSERVER=$HOME/go_appengine/dev_appserver.py
export PATH=$PATH:$HOME/go_appengine
export PATH=$PATH:$HOME/google-cloud-sdk/platform/google_appengine

[ -s $HOME/google-cloud-sdk/path.zsh.inc ] && source $HOME/google-cloud-sdk/path.zsh.inc
[ -s $HOME/google-cloud-sdk/completion.zsh.inc ] && source $HOME/google-cloud-sdk/completion.zsh.inc
# https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
USE_GKE_GCLOUD_AUTH_PLUGIN=True

## Path settings
export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/bin:$PATH
# JetBirans etc
export PATH=$HOME/work/bin:$PATH
# nvm より優先する
export PATH=$HOME/.nodebrew/current/bin:$PATH
export PATH=$PATH:$JAVA_HOME/bin
# misc
export PATH=$HOME/.cabal/bin:$PATH
export PATH=$PATH:$HOME/.foundry/bin
if [ `uname` = "Darwin" ]; then
  export PATH=$PATH:$(brew --prefix git)/share/git-core/contrib/diff-highlight
elif [ `uname` = "Linux" ]; then
  export PATH=$PATH:/usr/share/doc/git/contrib/diff-highlight
  export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH
  export PATH=$PATH:/mnt/c/Users/vvakame/AppData/Local/Programs/Microsoft\ VS\ Code/bin/
fi
[ -f "$(which rbenv)" ] && eval "$(rbenv init - zsh)"
[ -f "$(which direnv)" ] && eval "$(direnv hook zsh)"
[ -s $HOME/.cargo/env ] && source $HOME/.cargo/env
# [ -s $HOME/work/emsdk_portable/emsdk_env.sh ] && source $HOME/work/emsdk_portable/emsdk_env.sh
[ -f $DOTFILES/work.zsh ] && source $DOTFILES/work.zsh

export MANPATH=/opt/local/man:$MANPATH

export WASMTIME_HOME="$HOME/.wasmtime"
export PATH="$WASMTIME_HOME/bin:$PATH"


if [ -f "$(which colordiff)" ]; then
  alias diff='colordiff -u'
else
  alias diff='diff -u'
fi
export LESS='-R'

HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt hist_ignore_all_dups
# ignore duplication command history list
setopt hist_ignore_dups
setopt hist_save_nodups
# share command history data
setopt share_history
setopt hist_no_store
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt append_history
setopt inc_append_history

# setopt no_beep
setopt nolistbeep
setopt auto_pushd

autoload colors
colors

alias ls="ls -G"
alias la="ls -laGF"
alias emacs="open -a Emacs"
# alias pwdweb="python -m SimpleHTTPServer 8989"
alias pwdweb="live-server --port=8989 --no-browser --cors --verbose"

[ -f $HOME/.opam/opam-init/init.zsh ] && $HOME/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

if [ `uname` = "Darwin" ]; then
  [ -f $DOTFILES/zsh/mac.zsh ] && source $DOTFILES/zsh/mac.zsh
elif [ `uname` = "Linux" ]; then
  [ -f $DOTFILES/zsh/ubuntu.zsh ] && source $DOTFILES/zsh/ubuntu.zsh
fi
