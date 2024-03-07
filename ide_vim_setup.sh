#!/bin/bash


VIM_DOT_FILE_HOME_PATH=$HOME/settings/dotfiles
IDE_DOT_FILE=.ide-vimrc
IDEA_DOT_FILE=.ideavimrc
ECLIPSE_DOT_FILE=.vrapperrc

MESSAGE_CHECK_FILE="ファイルの存在チェック。存在しなければ作成します"
MESSAGE_MAKE_FILE="ファイルが存在しませんでした。作成します"
MESSAGE_FILE_EXIST="ファイルが存在します"

echo "$MESSAGE_CHECK_FILE"
for file in $IDEA_DOT_FILE $ECLIPSE_DOT_FILE $IDE_DOT_FILE
do
	if [ ! -e $HOME/$file ]; then
		echo "$file $MESSAGE_MAKE_FILE"
		ln -s $VIM_DOT_FILE_HOME_PATH/$file $HOME/$file
	else
		echo "$file $MESSAGE_FILE_EXIST"
	fi
done

