#!/bin/bash

ln -s `readlink -f .zshrc` $HOME/.zshrc 
ln -s `readlink -f .zshenv` $HOME/.zshenv

ZSH=(global_setting.zsh)

for file in ${ZSH[@]}
do
    echo $file

    ln -s `readlink -f $file` $HOME/.zsh.d/$file
done

ZSH_GIT=(_git git-completion.bash git-prompt.sh)

for file_git in ${ZSH_GIT[@]}
do
    echo $file_git

    ln -s `readlink -f $file_git` $HOME/.zsh/$file_git
done
