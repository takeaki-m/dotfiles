#!/bin/bash

KARABINER_JSONS=(karabiner/*.json)

for file in ${KARABINER_JSONS[@]}
do
    file=`echo $file | sed -e "s/karabiner//g"`
    echo $file
    ln -s $HOME/dotfiles/karabiner/$file $HOME/.config/karabiner/assets/complex_modifications/$file
done
