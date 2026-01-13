#!/bin/bash
# claude-tmux-status.sh
# tmuxウィンドウを一覧表示し、選択したウィンドウに移動する
#
# 機能:
#   - 全tmuxウィンドウをブランチ名・パスと共に一覧表示
#   - プレビューで各ウィンドウの現在の表示内容を確認
#   - 選択するとそのウィンドウに移動
#   - Ctrl-R でリストを更新
#
# 注意:
#   Claude Codeがnvim内のバッファとして動作している場合、
#   tmuxレベルでは検出できないため、シンプルな一覧表示のみ提供

set -e

SCRIPT_PATH="${BASH_SOURCE[0]}"

# fzfがインストールされているか確認
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is required but not installed."
    echo "Install with: brew install fzf"
    exit 1
fi

# tmuxセッション内で実行されているか確認
if [ -z "$TMUX" ]; then
    echo "Error: This script must be run inside a tmux session."
    exit 1
fi

# メイン処理: 全ウィンドウの情報を収集
collect_windows() {
    while IFS= read -r line; do
        local target pane_path

        # パース: session:window | path
        target=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
        pane_path=$(echo "$line" | cut -d'|' -f2 | tr -d ' ')

        # gitブランチを取得
        local branch
        branch=$(git -C "$pane_path" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "-")

        # パスを短縮表示（ホームディレクトリを~に）
        local short_path
        short_path=$(echo "$pane_path" | sed "s|$HOME|~|")

        # 出力フォーマット: target | branch | path
        printf "%-12s │ %-30s │ %s\n" "$target" "$branch" "$short_path"

    done < <(tmux list-windows -a -F "#{session_name}:#{window_index}|#{pane_current_path}")
}

# fzfで選択してウィンドウに移動
main() {
    local selected

    # ヘッダー
    local header="tmux Window Selector
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Window       │ Branch                         │ Path
─────────────┼────────────────────────────────┼──────────────────
[Ctrl-R: refresh] [Enter: switch] [Esc: cancel]"

    # fzfで選択
    selected=$(collect_windows | fzf \
        --ansi \
        --height 100% \
        --header "$header" \
        --preview 'tmux capture-pane -t $(echo {} | cut -d"│" -f1 | tr -d " ") -p -S -100 | tail -50' \
        --preview-window=down:60% \
        --bind "ctrl-r:reload(bash '$SCRIPT_PATH' --collect)" \
        --prompt "Select > " \
        || true)

    # 選択がなければ終了
    if [ -z "$selected" ]; then
        exit 0
    fi

    # 選択したウィンドウに移動
    local target
    target=$(echo "$selected" | cut -d'│' -f1 | tr -d ' ')

    tmux switch-client -t "$target"
}

# コマンドライン引数の処理
case "${1:-}" in
    --collect)
        # リスト更新用: ウィンドウ一覧を出力
        collect_windows
        ;;
    *)
        # デフォルト: メイン処理
        main
        ;;
esac