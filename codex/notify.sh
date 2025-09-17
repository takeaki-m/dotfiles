#!/bin/bash

# agentの最後の発言を抽出
#LAST_MESSAGE=$(echo "$1" | jq -r '.["last-assistant-message"] // "Codex task completed"')


#osascript -e' display notification "$LAST_MESSAGE" with title "Codex" subtitle "Processing is complete." sound name "Pop"'

# 以下LLMのレビューを反映した改良版
# stdinからエージェントの出力(JSON)を受け取り、last-assistant-messageを抽出
LAST_MESSAGE=$(jq -r '.["last-assistant-message"] // "Codex task completed"' < /dev/stdin)

osascript -e "display notification \"$LAST_MESSAGE\" with title \"Codex\" subtitle \"Processing is complete.\" sound name \"Pop\""
