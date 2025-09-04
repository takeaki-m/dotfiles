#!/bin/bash

CLAUDE_SETTINGS_FOLDER_PATH="$HOME/settings/dotfiles/claude"

ln -s $CLAUDE_SETTINGS_FOLDER_PATH/settings.json $HOME/.claude/settings.json
ln -s $CLAUDE_SETTINGS_FOLDER_PATH/CLAUDE.md $HOME/.claude/CLAUDE.md

