#!/bin/bash

CLAUDE_SETTINGS_FOLDER_PATH="$HOME/settings/dotfiles/claude"

ln -s $CLAUDE_SETTINGS_FOLDER_PATH/settings.json $HOME/.claude/settings.json
ln -s $CLAUDE_SETTINGS_FOLDER_PATH/CLAUDE.md $HOME/.claude/CLAUDE.md
ln -s $CLAUDE_SETTINGS_FOLDER_PATH/statusline.js $HOME/.claude/statusline.js

# Slash Commands
# ディレクトリごとリンクすることで、新しいコマンドファイル追加時に
# このスクリプトの修正が不要になる
ln -s $CLAUDE_SETTINGS_FOLDER_PATH/commands $HOME/.claude/commands

# MCP Servers
# 以下は参考のコマンド
# user levelで定義すると全てのプロジェクトで有効になる。
# MCP はcontextを消費するために、必要なタイミングだけ有効化する
# 基本的にはproject levelで定義することとする
#
# --------------------
# Project Scope
# --------------------
#claude mcp add awslabs_aws-documentation --scope project -- /opt/homebrew/bin/uvx awslabs.aws-documentation-mcp-server@latest
#claude mcp add mui-mcp --scope project -- npx -y @mui/mcp@latest
#claude mcp add terraform --scope project -- docker run -i --rm hashicorp/terraform-mcp-server
#claude mcp add context7 --scope project -- npx -y @upstash/context7-mcp@latest
#claude mcp add chrome-devtools --scope project -- npx -y chrome-devtools-mcp@latest

# --------------------
# User Scope
# --------------------
#claude mcp add awslabs_aws-documentation --scope user -- /opt/homebrew/bin/uvx awslabs.aws-documentation-mcp-server@latest
#claude mcp add mui-mcp --scope user -- npx -y @mui/mcp@latest
#claude mcp add terraform --scope user -- docker run -i --rm hashicorp/terraform-mcp-server
#claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest
#claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest
