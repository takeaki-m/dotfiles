#!/bin/bash
# claude-notify-list.sh
#
# 【全体構成】
# Claude Code の通知(権限要求 / 作業完了)を「リストに記録」し、
# あとから tmux popup で「一覧→選択→対象windowへ移動」するための仕組み。
#
#   record 役 : Claude Code のフックから呼ばれ、通知1件をログに追記する。
#               あわせて従来どおり macOS 通知(osascript)も発火する。
#   menu   役 : tmux の keybind(prefix + a)から display-popup 経由で呼ばれ、
#               ログを fzf 表示し、選んだ window へ switch-client で移動する。
#
# 【なぜこの方式か(実装背景)】
# claudecode.nvim(Snacks terminal)は Claude Code を nvim の :terminal
# バッファとして起動する多重ネスト構成。この場合ターミナルベル(BEL)は
# nvim が握り潰し、外側の tmux の monitor-bell まで伝播する保証がない。
# そのため BEL に依存せず、フックのサブプロセスが継承する $TMUX_PANE から
# 直接 window を特定してログ化する方式を採る(実測で継承を確認済み)。
#
# 【ログ形式】タブ区切り: epoch \t target(session:window) \t 種別 \t 名前 \t メッセージ
#   同一 window の旧行は record 時に消してから追記するため、
#   「今応答待ちの window 一覧」が常に最新1件/windowに保たれる。

set -eu

# ログの場所(dotfiles配下ではなく実行時ファイルとして ~/.claude 直下に置く)
LOG_FILE="${CLAUDE_NOTIFY_LOG:-$HOME/.claude/claude-notifications.tsv}"
# 追記の競合(複数 Claude 同時発火)を防ぐ簡易ロック。mkdir は atomic。
LOCK_DIR="${LOG_FILE}.lock"

# ---- 共通ヘルパ ----

# ロック取得/解放。取得できなくても最終的に処理は進める(ベストエフォート)。
acquire_lock() {
    local i
    for i in $(seq 1 50); do
        if mkdir "$LOCK_DIR" 2>/dev/null; then
            return 0
        fi
        sleep 0.05
    done
    return 0
}
release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}

# $TMUX_PANE から "session:window" を解決する。tmux 外なら空を返す。
resolve_target() {
    if [ -z "${TMUX:-}" ] || [ -z "${TMUX_PANE:-}" ]; then
        echo ""
        return
    fi
    tmux display-message -t "$TMUX_PANE" -p '#{session_name}:#{window_index}' 2>/dev/null || echo ""
}

# ---- record 役 ----
# 引数: $2 = 種別キー(permission | stop)
# 標準入力: Claude Code フックの JSON ペイロード
do_record() {
    local kind="${1:-}"
    local input name message target label epoch

    input="$(cat)"

    # cwd のbasename(プロジェクト名として使う)
    name="$(printf '%s' "$input" | jq -r '.cwd | split("/") | last' 2>/dev/null || echo "-")"

    # 種別ごとのラベルと、メッセージの既定値
    case "$kind" in
        permission)
            label="要権限"
            message="$(printf '%s' "$input" | jq -r '.message // "権限要求"' 2>/dev/null)"
            ;;
        stop)
            label="完了"
            message="作業が完了しました"
            ;;
        *)
            label="通知"
            message="$(printf '%s' "$input" | jq -r '.message // "通知"' 2>/dev/null)"
            ;;
    esac

    # メッセージ内の改行/タブ/区切り文字(│)を除去してログ1行を壊さないようにする
    message="$(printf '%s' "$message" | tr '\n\t' '  ' | tr '│' '|')"

    target="$(resolve_target)"
    epoch="$(date +%s)"

    # tmux 内で起動している場合のみログ化(window を特定できないと移動できないため)
    if [ -n "$target" ]; then
        acquire_lock
        # 同一 window の旧行を除去してから最新1件を追記
        if [ -f "$LOG_FILE" ]; then
            awk -F'\t' -v t="$target" '$2 != t' "$LOG_FILE" > "${LOG_FILE}.tmp" 2>/dev/null || true
            mv "${LOG_FILE}.tmp" "$LOG_FILE"
        fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$epoch" "$target" "$label" "$name" "$message" >> "$LOG_FILE"
        release_lock
    fi

    # 従来どおり macOS 通知も発火(挙動維持: タイトル/音 Glass)
    if [ "$kind" = "permission" ]; then
        osascript -e "display notification \"$message\" with title \"Claude Code 権限要求 [$name]\" sound name \"Glass\"" >/dev/null 2>&1 || true
    else
        osascript -e "display notification \"作業が完了しました [$name]\" with title \"Claude Code\" sound name \"Glass\"" >/dev/null 2>&1 || true
    fi
}

# ---- menu 役 ----
# tmux display-popup から呼ばれ、fzf でリスト選択 → switch-client で移動。
do_menu() {
    if [ ! -s "$LOG_FILE" ]; then
        tmux display-message "Claude通知はありません" 2>/dev/null || echo "Claude通知はありません"
        return 0
    fi

    # 表示用に整形(新しい順)。target は先頭カラムに置き、後で │ 区切りで取り出す。
    local list
    list="$(sort -t$'\t' -k1,1nr "$LOG_FILE" | awk -F'\t' '{
        # epoch(=$1)を HH:MM に変換
        cmd = "date -r " $1 " +%H:%M 2>/dev/null"
        cmd | getline hhmm
        close(cmd)
        printf "%-14s │ %-6s │ %-16s │ %s │ %s\n", $2, $3, $4, hhmm, $5
    }')"

    local header="Claude 通知リスト  [Enter: 移動 / Esc: 閉じる]
Window         │ 種別   │ 名前             │ 時刻  │ メッセージ
───────────────┼────────┼──────────────────┼───────┼──────────────"

    local selected
    selected="$(printf '%s\n' "$list" | fzf \
        --ansi \
        --height 100% \
        --header "$header" \
        --preview 'tmux capture-pane -pt "$(echo {} | cut -d"│" -f1 | tr -d " ")" -S -60 2>/dev/null | tail -40' \
        --preview-window=down:55% \
        --prompt "Select > " \
        || true)"

    [ -z "$selected" ] && return 0

    local target
    target="$(printf '%s' "$selected" | cut -d'│' -f1 | tr -d ' ')"
    [ -z "$target" ] && return 0

    # 対象 window へ移動(別セッションでも switch-client で追従)
    tmux switch-client -t "$target" 2>/dev/null || tmux select-window -t "$target" 2>/dev/null || true

    # 訪問済みなので該当行をログから削除
    acquire_lock
    if [ -f "$LOG_FILE" ]; then
        awk -F'\t' -v t="$target" '$2 != t' "$LOG_FILE" > "${LOG_FILE}.tmp" 2>/dev/null || true
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
    release_lock
}

# ---- エントリポイント ----
case "${1:-}" in
    record) shift; do_record "$@" ;;
    menu)   do_menu ;;
    clear)  : > "$LOG_FILE" ;;   # 手動全消去用
    *)
        echo "usage: $0 {record <permission|stop>|menu|clear}" >&2
        exit 1
        ;;
esac
