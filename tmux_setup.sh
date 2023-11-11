#!/bin/bash

DOT_FILE=.tmux.conf
echo "make $DOT_FILE sybolink links"

ln -s $HOME/settings/dotfiles/$DOT_FILE $HOME/$DOT_FILE
