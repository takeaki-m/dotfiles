#!/bin/bash

NVIM_DOT_FILE=init.lua
# vim.pack の lockfile。VCS 管理して再現性を担保するため symlink で配置する。
NVIM_LOCK_FILE=nvim-pack-lock.json
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

# vim.pack の lockfile を symlink する。
# 背景: vim.pack は stdpath('config')/nvim-pack-lock.json をその場(fs_open 'w')で更新するため、
#   symlink にしておけば書き込みは repo 側の実ファイルへ届き、VCS で再現性を管理できる。
#   新規マシンでは、このリンクを張ってから nvim を起動すると lockfile の pinned revision で
#   プラグインが復元される。
echo "$NVIM_LOCK_FILE $MESSAGE_CHECK_FILE"
if [ ! -e $NVIM_HOME_PATH/$NVIM_LOCK_FILE ]; then
	echo "$NVIM_LOCK_FILE $MESSAGE_MAKE_FILE"
	ln -s $NVIM_DOT_FILE_HOME_PATH/$NVIM_LOCK_FILE $NVIM_HOME_PATH/$NVIM_LOCK_FILE
else
	echo "$NVIM_LOCK_FILE $MESSAGE_FILE_EXIST"
fi

for file in $(ls $NVIM_DOT_FILE_LUA_PATH); do
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
