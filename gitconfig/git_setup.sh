#!/bin/bash

echo "### check if .gitconfig exists ###"
if [ -e ~/.gitconfig ]; then
	echo ".gitconfig file exists. continue to settings"
else
	echo ".gitconfig does not exists. make .gitconfig file and continue to settings"
	touch ~/.gitconfig
fi

GIT_SET_PATH=$HOME/settings/dotfiles/gitconfig

echo "### start .gitconfig settings ###"
git config --global --add include.path "$GIT_SET_PATH/.gitconfig_shared"
# 差分表示が見にくいためコメントアウトする
#git config --global --add include.path "$GIT_SET_PATH/.delta_config"

echo "### start .gitignore settings ###"
git config --global core.excludesfile $GIT_SET_PATH/.gitignore_global

echo "### start .gitignore settings ###"
git config --global commit.template $GIT_SET_PATH/.commit_template

echo "### set core editor nvim ###"
git config --global core.editor "nvim"

RET_CD=$?
exit ${RET_CD}
