#!/bin/bash

echo "### check if .gitconfig exists ###"
if [ -e ~/.gitconfig ]; then
  echo ".gitconfig file exists. continue to settings"
else
  echo ".gitconfig does not exists. make .gitconfig file and continue to settings"
  touch ~/.gitconfig
fi

echo "### start .gitconfig settings ###"
git config --global include.path `readlink -f gitconfig/.gitconfig_shared`

echo "### start .gitignore settings ###"
git config --global core.excludesfile `readlink -f gitconfig/.gitignore_global`


RET_CD=$?
exit ${RET_CD}
