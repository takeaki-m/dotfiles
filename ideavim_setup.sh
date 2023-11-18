#!/bin/bash

DOT_FILE=.ideavimrc
echo "make $DOT_FILE synbolik link"
ln -s $HOME/settings/dotfiles/$DOT_FILE $HOME/$DOT_FILE
