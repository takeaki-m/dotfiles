#!/bin/bash

NVIM_DOT_FILE=init.lua
NVIM_DOT_FILE_HOME_PATH=$HOME/settings/dotfiles/nvim
NVIM_DOT_FILE_LUA_PATH=$NVIM_DOT_FILE_HOME_PATH/lua
NVIM_DOT_FILE_LUA_PLUGINS_PATH=$NVIM_DOT_FILE_LUA_PATH/plugins

NVIM_HOME_PATH=$HOME/.config/nvim
NVIM_LUA_PATH=$NVIM_HOME_PATH/lua
NVIM_LUA_PLUGIN_PATH=$NVIM_LUA_PATH/plugins

MESSAGE_CHECK_DIRECTORY="ディレクトリの存在チェック。存在しなければ作成します"
MESSAGE_MAKE_DIRECTORY="ディレクトリが存在しませんでした。作成します"
MESSAGE_DIRECTORY_EXIST="ディレクトリが存在します"

MESSAGE_CHECK_FILE="ファイルの存在チェック。存在しなければ作成します"
MESSAGE_MAKE_FILE="ファイルが存在しませんでした。作成します"
MESSAGE_FILE_EXIST="ファイルが存在します"

for dist in $NVIM_HOME_PATH $NVIM_LUA_PATH $NVIM_LUA_PLUGIN_PATH; do
	echo "$dist $MESSAGE_CHECK_DIRECTORY"
	if [ ! -e $dist ]; then
		echo "$dist $MESSAGE_MAKE_DIRECTORY"
		mkdir $dist
	else
		echo "$dist $MESSAGE_DIRECTORY_EXIST"
	fi
done

echo "$NVIM_DOT_FILE $MESSAGE_CHECK_FILE"
if [ ! -e $NVIM_HOME_PATH/$NVIM_DOT_FILE ]; then
	echo "$NVIM_DOT_FILE $MESSAGE_MAKE_FILE"
	ln -s $NVIM_DOT_FILE_HOME_PATH/$NVIM_DOT_FILE $NVIM_HOME_PATH/$NVIM_DOT_FILE
else
	echo "$NVIM_DOT_FILE $MESSAGE_FILE_EXIST"
fi

for file in options.lua keymaps.lua; do
	if [ ! -e $NVIM_LUA_PATH/$file ]; then
		echo "$file $MESSAGE_MAKE_FILE"
		ln -s $NVIM_DOT_FILE_LUA_PATH/$file $NVIM_LUA_PATH/$file
	else
		echo "$file $MESSAGE_FILE_EXIST"
	fi
done

for file in "$NVIM_DOT_FILE_LUA_PLUGINS_PATH"/*.lua; do
	## $file変数のままではfull pathになってしまうため、ファイル名だけ抜き出す
	echo "$file"
	filename=$(basename "$file")
	if [ ! -e $NVIM_LUA_PLUGIN_PATH/$filename ]; then
		echo "$filename $MESSAGE_MAKE_FILE"
		ln -s $NVIM_DOT_FILE_LUA_PLUGINS_PATH/$filename $NVIM_LUA_PLUGIN_PATH/$filename
	else
		echo "$filename $MESSAGE_FILE_EXIST"
	fi
done
