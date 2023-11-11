#!/bin/bash

DOT_FILES=(.tmux.conf .vimrc .zshenv .zshrc)

for file in ${DOT_FILES[@]}
do
    ln -s $HOME/settings/dotfiles/$file $HOME/$file
done
