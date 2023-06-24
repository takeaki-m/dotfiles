#!/bin/bash

KARABINER_JSONS=(*.json)

for file in ${KARABINER_JSONS[@]}
do
    echo $file

    ln -s `readlink -f $file` $HOME/.config/karabiner/assets/complex_modifications/$file
done
