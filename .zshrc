autoload -U compinit
compinit

export LANG=ja_JP.UTF-8

if [ -d ~/android-sdks ]; then
  export ANDROID_SDK_ROOT=~/android-sdks
elif [ -d ~/work/android-sdk-mac_x86 ]; then
  export ANDROID_SDK_ROOT=~/work/android-sdk-mac_x86
fi

# export ANDROID_SDK_ROOT=~/work/android-sdk-mac_x86
export ANDROID_SDK_HOME=$ANDROID_SDK_ROOT
export ANDROID_HOME=$ANDROID_SDK_HOME
export ANDROID_NDK_ROOT=~/work/android-ndk-r6b

export SCALA_HOME=/opt/local/share/scala
# export PLAY_HOME=~/work/bin/play-2.0-beta
export PLAY_HOME=~/work/bin/Play20

export DART_SDK=/Applications/dart/dart-sdk

export PATH=~/bin:~/work/bin:/opt/local/bin:/opt/local/sbin/:~/work/bin/sbt:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_NDK_ROOT:~/work/scala-2.8.1.final/bin/:$PLAY_HOME:$DART_SDK/bin:$PATH
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

