#!/bin/bash

CLAUDE_SETTINGS_FOLDER_PATH="$HOME/settings/dotfiles/claude"

ln -s $CLAUDE_SETTINGS_FOLDER_PATH/settings.json $HOME/.claude/settings.json
ln -s $CLAUDE_SETTINGS_FOLDER_PATH/CLAUDE.md $HOME/.claude/CLAUDE.md

# MCP Servers
claude mcp add awslabs_aws-documentation -- /opt/homebrew/bin/uvx awslabs.aws-documentation-mcp-server@latest
claude mcp add mui-mcp -- npx -y @mui/mcp@latest
claude mcp add terraform --  docker run -i --rm hashicorp/terraform-mcp-server

