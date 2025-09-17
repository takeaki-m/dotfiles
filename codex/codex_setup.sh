#!/bin/bash

CODEX_SETTINGS_FOLDER_PATH="$HOME/settings/dotfiles/codex"

ln -s $CODEX_SETTINGS_FOLDER_PATH/config.toml $HOME/.codex/config.toml
ln -s $CODEX_SETTINGS_FOLDER_PATH/AGENTS.md $HOME/.codex/AGENTS.md
ln -s $CODEX_SETTINGS_FOLDER_PATH/notify.sh $HOME/.codex/notify.sh

