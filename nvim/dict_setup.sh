#!/bin/bash
# 全体構成: nvim-cmp の辞書補完(cmp-dictionary)用の英単語リストを生成する
# 詳細:
#   1. aspell の主辞書(master)を dump して原形のリストを取得
#   2. expand コマンドで活用形(複数形/過去形/三単現等)を展開
#   3. スペース区切りの行を改行区切りに変換し、ソート+重複排除して書き出す
# 出力先: ~/.config/nvim/dict/english.txt
#   init.lua の cmp_dictionary 設定がこのパスを参照する
#
# 前提条件: aspell が brew install 済みであること
#   未インストール時は homebrew_setup.sh または `brew install aspell` を先に実行
#
# 実行方法:
#   bash nvim/dict_setup.sh
#
# 再生成タイミング:
#   - 初回セットアップ時
#   - aspell のバージョンアップ後(辞書語彙が更新された場合)
#   通常のnvim利用時には再実行不要(辞書ファイルは静的で安定)

set -euo pipefail

# 全体構成に対する詳細パス定義
DICT_DIR="$HOME/.config/nvim/dict"
DICT_FILE="$DICT_DIR/english.txt"

# 前提条件チェック: aspell が利用可能か
if ! command -v aspell &> /dev/null; then
  echo "Error: aspell が見つかりません。先に 'brew install aspell' を実行してください" >&2
  exit 1
fi

# 出力ディレクトリの作成(存在すれば何もしない)
mkdir -p "$DICT_DIR"

# 辞書生成
# - aspell -d en dump master: 英語(en)主辞書から原形のリストを出力
# - aspell -l en expand: 各原形を「原形 活用形1 活用形2 ...」の形式で展開
# - tr ' ' '\n': スペース区切りを改行区切りに変換(1単語1行に正規化)
# - sort -u: ソート + 重複排除(複数原形に共通する活用形を1件にまとめる)
echo "辞書ファイルを生成中: $DICT_FILE"
aspell -d en dump master \
  | aspell -l en expand \
  | tr ' ' '\n' \
  | sort -u \
  > "$DICT_FILE"

# 結果サマリ
WORD_COUNT=$(wc -l < "$DICT_FILE" | tr -d ' ')
FILE_SIZE=$(du -h "$DICT_FILE" | cut -f1)
echo "完了: ${WORD_COUNT} 単語 (${FILE_SIZE}) を ${DICT_FILE} に書き出しました"