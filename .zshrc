autoload -U compinit
compinit

export LANG=ja_JP.UTF-8

if [ -d ~/android-sdks ]; then
  export ANDROID_SDK_ROOT=~/android-sdks
elif [ -d ~/work/android-sdk-mac_x86 ]; then
  export ANDROID_SDK_ROOT=~/work/android-sdk-mac_x86
fi

# export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home
export JAVA_HOME=$(/usr/libexec/java_home -v 1.7)

export ANDROID_SDK_HOME=$ANDROID_SDK_ROOT
export ANDROID_HOME=$ANDROID_SDK_HOME
# export ANDROID_NDK_ROOT=~/work/android-ndk-r6b

export SCALA_HOME=/opt/local/share/scala
export PLAY_HOME=~/work/play-2.0.4

export DART_SDK=/Applications/dart/dart-sdk
export GOROOT=/usr/local/go

export PHANTOMJS_BIN=/opt/local/bin/phantomjs

# setup gvm (Groovy)
if [ -s ~/.gvm/bin/gvm-init.sh ]; then
  source ~/.gvm/bin/gvm-init.sh
fi
export GRADLE_OPTS="-Dorg.gradle.daemon=true"

## Path settings
export PATH=/opt/local/bin:/opt/local/sbin/:$PATH
export PATH=$PATH:$JAVA_HOME/bin
# android
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_NDK_ROOT
# google
export PATH=$PATH:~/work/gcutil/gcutil-1.7.1:~/work/gsutil
# misc
export PATH=$PATH:~/work/JSX/bin
export PATH=$PATH:$HOME/.rbenv/bin
export PATH=$PATH:~/Library/Haskell/ghc-7.4.2/lib/ghc-mod-1.11.2/bin
export PATH=$PATH:~/.nodebrew/current/bin

export MANPATH=/opt/local/man:$MANPATH

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
PROMPT="%{${fg[blue]}%}[%n@%m] %(!.#.$) %{${reset_color}%}"
PROMPT2="%{${fg[blue]}%}%_> %{${reset_color}%}"
SPROMPT="%{${fg[red]}%}correct: %R -> %r [nyae]? %{${reset_color}%}"
RPROMPT="%{${fg[blue]}%}[%~]%{${reset_color}%}"

# alias emacs="/Applications/Emacs.app/Contents/MacOS/Emacs"
alias ls="ls -G"
alias la="ls -laGF"
alias emacs="open -a Emacs"
alias pwdweb="python -m SimpleHTTPServer 8989" 

set_rprompt() {
    local user_color
    if [ `whoami` = root ]; then
        user_color=red
    elif [ `hostname` = otto.local ]; then
        user_color=blue
    elif [ `hostname` = liesa.local ]; then
        user_color=magenta
    elif [ `hostname` = walter.local ]; then
        user_color=green
    elif [ `hostname` = pamela.local ]; then
        user_color=magenta
    elif [ `hostname` = ip21-pc.topgate.lan ]; then
        user_color=green
    elif [ `hostname` = vv-temp.local ]; then
        user_color=green
    fi
    RPROMPT="%{${fg[$user_color]}%}[%~]%{${reset_color}%}"
}

set_rprompt

