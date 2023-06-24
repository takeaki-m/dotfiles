#!/bin/bash

echo "### start .gitconfig settings ###"
git config --global include.path `readlink -f gitconfig/.gitconfig_shared`

echo "### start .gitignore settings ###"
git config --global core.excludesfile `readlink -f gitconfig/.gitignore_global`


RET_CD=$?
exit ${RET_CD}
