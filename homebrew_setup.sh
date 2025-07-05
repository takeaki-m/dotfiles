#!/bin/bash

echo "install homebrew..."
which brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "run brew doctor..."
which brew >/dev/null 2>&1 && brew doctor

echo "run brew update..."
which brew >/dev/null 2>&1 && brew update

echo "ok. run brew upgrade..."

brew upgrade

brew cleanup


echo "bundle .Brewfile"

BREWFILE_DOT_FILE_HOME_PATH=$HOME/settings/dotfiles/.Brewfile

ln -s $BREWFILE_DOT_FILE_HOME_PATH ~/.Brewfile

brew bundle --global

cat << END

================================
homebrew installed bye.
================================

END
