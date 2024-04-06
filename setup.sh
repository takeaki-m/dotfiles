#!/bin/bash

/Users/takeaki/settings/dotfiles/setup.sh
DOTFILES_ROOT_PATH=$HOME/settings/dotfiles

echo " 各種設定ファイルを呼び出してdotifilesの設定を行います"
sh $DOTFILES_ROOT_PATH/dotfile_setup.sh
sh $DOTFILES_ROOT_PATH/homebrew_install.sh
sh $DOTFILES_ROOT_PATH/zsh/zsh_setup.sh
sh $DOTFILES_ROOT_PATH/karabiner/karabiner_setup.sh
sh $DOTFILES_ROOT_PATH/gitconfig/git_setup.sh
sh $DOTFILES_ROOT_PATH/hammerspoon/hammerspoon_setup.sh

