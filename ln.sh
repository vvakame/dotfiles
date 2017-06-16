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
