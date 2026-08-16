#!/bin/bash -u

ln -s $HOME/dotfiles/.zshrc $HOME/
ln -s $HOME/dotfiles/.screenrc $HOME/
ln -s $HOME/dotfiles/.gitconfig $HOME/
if [ `uname` = "Darwin" ]; then
  ln -s $HOME/dotfiles/.gitconfig.env.mac $HOME/.gitconfig.env
elif [ `uname` = "Linux" ]; then
  ln -s $HOME/dotfiles/.gitconfig.env.linux $HOME/.gitconfig.env
fi
ln -s $HOME/dotfiles/.emacs $HOME/
# ln -s ~/src/dotfiles/.vimrc ~/
ln -s $HOME/dotfiles/.agignore $HOME/

# Claude Code
# ~/.claude には履歴やキャッシュなどの実行時ファイルが同居するので
# ディレクトリごとではなくファイル/サブディレクトリ単位で貼る
mkdir -p $HOME/.claude
# settings.json はマシンごとに異なるキー (theme, enabledPlugins, ...) があるため、
# settings.common.json (共通・git管理) と settings.machine.json (マシン固有・
# gitignore) を merge して生成する。生成された settings.json 自体も
# gitignore 対象だが、symlink 先はリポジトリ内なので ~/.claude 側からは
# dotfiles 管理下だとわかる構造を維持できる。
bash $HOME/dotfiles/claude/apply-settings.sh
for f in CLAUDE.md settings.json statusline-command.sh agents commands hooks skills; do
  if [ -e $HOME/dotfiles/claude/.claude/$f ]; then
    ln -s $HOME/dotfiles/claude/.claude/$f $HOME/.claude/
  fi
done
