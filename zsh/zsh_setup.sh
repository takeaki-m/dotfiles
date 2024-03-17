#!/bin/bash

ZSH_DOTFILE_PATH=$HOME/settings/dotfiles/zsh

if [ -d $HOME/.zsh ]; then
	echo "$HOME配下に.zshフォルダは作成済み"
else
	echo "$HOME配下に.zshフォルダは作成前。フォルダを作成します"
	mkdir $HOME/.zsh
fi

if [ -d $HOME/.zsh.d ]; then
	echo "$HOME配下に.zshフォルダは作成済み"
else
	echo "$HOME配下に.zshフォルダは作成前。フォルダを作成します"
	mkdir $HOME/.zsh.d
fi

ln -s $(readlink -f $ZSH_DOTFILE_PATH/.zshrc) $HOME/.zshrc
ln -s $(readlink -f $ZSH_DOTFILE_PATH/.zshenv) $HOME/.zshenv

ZSH=(global_setting.zsh global_env.zsh)

for file in ${ZSH[@]}; do
	echo $file

	ln -s $(readlink -f $ZSH_DOTFILE_PATH/$file) $HOME/.zsh.d/$file
done

ZSH_GIT=(_git git-completion.bash git-prompt.sh)

for file_git in ${ZSH_GIT[@]}; do
	echo $file_git

	ln -s $(readlink -f $ZSH_DOTFILE_PATH/$file_git) $HOME/.zsh/$file_git
done

