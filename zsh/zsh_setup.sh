#!/bin/bash

ln -s `readlink -f .zshrc` $HOME/.zshrc 
ln -s `readlink -f .zshenv` $HOME/.zshenv

ZSH=(global_setting.zsh)

for file in ${ZSH[@]}
do
    echo $file

    ln -s `readlink -f $file` $HOME/.zsh.d/$file
done
