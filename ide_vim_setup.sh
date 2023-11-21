#!/bin/bash

IDEA_DOT_FILE=.ideavimrc
echo "make $ECLIPSE_DOT_FILE synbolik link"
ln -s $HOME/settings/dotfiles/$IDEA_DOT_FILE $HOME/$IDEA_DOT_FILE

ECLIPSE_DOT_FILE=.vrapperrc
echo "make $ECLIPSE_DOT_FILE synbolik link"
ln -s $HOME/settings/dotfiles/$ECLIPSE_DOT_FILE $HOME/$ECLIPSE_DOT_FILE
