#!/bin/bash
# script/ 配下のユーティリティを ~/.local/bin にシンボリックリンクする
#
# 全体構成: リンク先ディレクトリを用意 → 対象スクリプトを順にリンク
# 何度実行しても同じ結果になる(冪等)ことを前提にしており、setup.sh から
# 繰り返し呼ばれても失敗しない
set -eu

# スクリプト自身の位置から dotfiles のパスを解決する。
# clone 先を $HOME/settings/dotfiles に固定しないため
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN_PATH="$HOME/.local/bin"

# リンク対象。追加するスクリプトはここに並べる
TARGETS="ascii2md.py"

mkdir -p "$LOCAL_BIN_PATH"

for target in $TARGETS; do
	# -f で既存リンクを張り替え、-n でリンク先ディレクトリの中に潜り込むのを防ぐ
	ln -sfn "$SCRIPT_DIR/$target" "$LOCAL_BIN_PATH/$target"
	echo "linked: $LOCAL_BIN_PATH/$target -> $SCRIPT_DIR/$target"
done
