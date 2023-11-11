#!/bin/bash

karabiner_json_path=$HOME/settings/dotfiles/karabiner

for json_file in *.json; do
	echo "$json_file"
	if [[ -f "$json_file" ]]; then
		ln -s $(readlink -f $karabiner_json_path/$json_file) $HOME/.config/karabiner/assets/complex_modifications/$json_file
	fi
done
