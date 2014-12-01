autoload -U compinit
compinit

# antigen start
source ~/src/dotfiles/antigen/antigen.zsh

antigen use oh-my-zsh

# Terminalでの入力に色がつく http://blog.glidenote.com/blog/2012/12/15/zsh-syntax-highlighting/
antigen bundle zsh-users/zsh-syntax-highlighting
# mvnで入力補完が効くようになる https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins#mvn
antigen bundle mvn

antigen theme gnzh
antigen apply
# antigen end

[ -f /opt/boxen/env.sh ] && source /opt/boxen/env.sh

export LANG=ja_JP.UTF-8

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

if [ -d ~/android-sdk ]; then
  export ANDROID_SDK_ROOT=~/android-sdk
elif [ -d ~/android-sdks ]; then
  export ANDROID_SDK_ROOT=~/android-sdks
elif [ -d ~/work/android-sdk-mac_x86 ]; then
  export ANDROID_SDK_ROOT=~/work/android-sdk-mac_x86
fi

if [ -f "$(which dvm)" ]; then
  eval "$(dvm env)"
fi

export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

export ANDROID_SDK_HOME=$ANDROID_SDK_ROOT
export ANDROID_HOME=$ANDROID_SDK_HOME
export ANDROID_NDK_ROOT=~/android-ndk-r9b

export SCALA_HOME=/opt/local/share/scala
export PLAY_HOME=~/work/play-2.0.4

export DART_SDK=/Applications/dart/dart-sdk

export GOROOT=~/google-cloud-sdk/platform/google_appengine/goroot
export GOPATH=~/.go
export APPENGINE_DEV_APPSERVER=~/google-cloud-sdk/platform/google_appengine/dev_appserver.py

export NACL_SDK_ROOT=~/nacl_sdk/pepper_31

if [ -s /opt/boxen/homebrew/bin/phantomjs ]; then
  export PHANTOMJS_BIN=/opt/boxen/homebrew/bin/phantomjs
elif [ -s /opt/local/bin/phantomjs ]; then
  export PHANTOMJS_BIN=/opt/local/bin/phantomjs
fi

export DOCKER_HOST=tcp://localhost:4243

# setup gvm (Groovy)
if [ -s ~/.gvm/bin/gvm-init.sh ]; then
  source ~/.gvm/bin/gvm-init.sh
fi
export GRADLE_OPTS="-Dorg.gradle.daemon=true"

if [ -s ~/google-cloud-sdk/completion.zsh.inc ]; then
  source ~/google-cloud-sdk/completion.zsh.inc
fi

## Path settings
export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/bin:$PATH
# nvm より優先する
export PATH=~/.nodebrew/current/bin:$PATH
export PATH=$PATH:$JAVA_HOME/bin
# android
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_NDK_ROOT
# google
export PATH=$PATH:~/google-cloud-sdk/bin
# misc
export PATH=$PATH:$(brew --prefix git)/share/git-core/contrib/diff-highlight
eval "$(rbenv init - zsh)"
export PATH=$PATH:~/Library/Haskell/ghc-7.6.3/lib/ghc-mod-1.11.2/bin
export PATH=$PATH:~/bin
export PATH=$PATH:/usr/texbin

export MANPATH=/opt/local/man:$MANPATH

if [[ -x `which colordiff` ]]; then
  alias diff='colordiff -u'
else
  alias diff='diff -u'
fi
export LESS='-R'

export _JAVA_OPTIONS="-Dfile.encoding=UTF-8"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt hist_ignore_all_dups
setopt hist_ignore_dups     # ignore duplication command history list
setopt hist_save_nodups
setopt share_history        # share command history data
# setopt correct
setopt append_history
setopt inc_append_history
setopt hist_no_store
setopt hist_reduce_blanks
setopt no_beep
setopt hist_ignore_space

autoload colors
colors

# alias emacs="/Applications/Emacs.app/Contents/MacOS/Emacs"
alias ls="ls -G"
alias la="ls -laGF"
alias emacs="open -a Emacs"
alias pwdweb="python -m SimpleHTTPServer 8989"

# added by travis gem
[ -f /Users/vvakame/.travis/travis.sh ] && source /Users/vvakame/.travis/travis.sh

# opam
/Users/vvakame/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

