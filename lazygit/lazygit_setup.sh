#!/bin/bash
LAZYGIT_DOTFILE_PATH=$HOME/settings/dotfiles/lazygit
LAZYGIT_SETTING_PATH="$HOME/Library/Application Support/lazygit"

for file in "$LAZYGIT_DOTFILE_PATH"/*.yml; do
	## $file変数のままではfull pathになってしまうため、ファイル名だけ抜き出す
	echo "$file"
	filename=$(basename "$file")
	if [ ! -e "$LAZYGIT_SETTING_PATH/$filename" ]; then
		echo "$filename linkes"
		ln -s "$LAZYGIT_DOTFILE_PATH/$filename" "$LAZYGIT_SETTING_PATH/$filename"
	else
		echo "$filename exists"
	fi
done
