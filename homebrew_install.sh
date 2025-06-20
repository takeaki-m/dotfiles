#!/bin/bash

echo "install homebrew..."
which brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "run brew doctor..."
which brew >/dev/null 2>&1 && brew doctor

echo "run brew update..."
which brew >/dev/null 2>&1 && brew update

echo "ok. run brew upgrade..."

brew upgrade -all

formulas=(
    anyenv
    apr
    apr-util
    autoconf
    bash-completion
    berkeley-db
    cask
    cmake
    cscope
    gcc
    gdbm
    gettext
    git
    gmp
    go
    icu4c
    isl
    libevent
    libmpc
    libssh2
    libyaml
    lua
    lz4
    mono
    mpdecimal
    mpfr
    ncurses
    node
    pcre2
    perl
    pkg-config
    pwgen
    pyenv
    readline
    sqlite
    tcl-tk
    tmux
    tree
    utf8proc
    vim
    xz
    zsh-autosuggestions
    zsh-completions
    zsh-git-prompt
    zsh-syntax-highlighting
    alfred
    ripgrep
)

echo "start brew install apps..."
for formula in "${formulas[@]}"; do
    brew install $formula || brew upgrade $formula
done

casks=(
    slack
    alfred
    iterm2
    virtualbox
    vagrant
    vagrant-manager
    dash
)

echo "start brew cask install apps..."
for cask in "${cask[@]}"; do
    brew  install -cask $cask
done

brew cleanup
brew cask cleanup

cat << END

================================
homebrew installed bye.
================================

END
