#!/bin/bash

GHOSTTY_SETING_PATH=$HOME/.config/ghostty
GHOSTTY_SETING_FILE=$GHOSTTY_SETING_PATH/config
GHOSTTY_SETTINGS_FILE_PATH="$HOME/settings/dotfiles/ghostty/config"

MESSAGE_CHECK_DIRECTORY="ディレクトリの存在チェック。存在しなければ作成します"
MESSAGE_MAKE_DIRECTORY="ディレクトリが存在しませんでした。作成します"
MESSAGE_DIRECTORY_EXIST="ディレクトリが存在します"

for dist in $GHOSTTY_SETING_PATH; do
	echo "$dist $MESSAGE_CHECK_DIRECTORY"
	if [ ! -e $dist ]; then
		echo "$dist $MESSAGE_MAKE_DIRECTORY"
		mkdir $dist
	else
		echo "$dist $MESSAGE_DIRECTORY_EXIST"
	fi
done

ln -s $GHOSTTY_SETTINGS_FILE_PATH $GHOSTTY_SETING_FILE
