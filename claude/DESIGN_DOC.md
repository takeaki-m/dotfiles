# claude/DESIGN_DOC.md

claude/ 配下の設定における実装背景・決定記録のドキュメント。
CLAUDE.md は Claude への指示書、本ファイルは人間のための背景説明として役割を分ける。

---

## 通知設定 (settings.json の hooks / preferredNotifChannel)

### 動作環境
- ターミナル: Ghostty
- マルチプレクサ: tmux (`allow-passthrough on` 設定済み)
- エディタ: Neovim
- Claude Code 起動方法: **nvim の `:terminal` バッファ内で起動**

### 採用した通知経路
- `preferredNotifChannel: "terminal_bell"` — ベル音のみターミナルに通す
- `Notification` hook (`matcher: "permission_prompt"`) → `osascript` で macOS 通知センターに直接送る
- `Stop` hook → `jq` で `cwd` のベース名を取り出し、`osascript` で「作業が完了しました [<ディレクトリ名>]」を通知 (Glass 音付き)
- 結果: 通知は macOS ホストから直接発火するため、tmux/nvim/Ghostty 経路を完全に迂回する

### Stop hook にディレクトリ名を含める理由
複数の Claude Code セッションを並列で動かすと、音だけでは「どのリポジトリ/ワークツリーが完了したか」が判別できない。
ディレクトリのベース名 (リポジトリ名やワークツリーのブランチ名に相当) を通知タイトルに含めることで、
通知を見たオーナーが該当ディレクトリへ移動して `git log` / `git diff` で変更内容を即座に確認できる。
当初は `afplay` のみのシンプル構成だったが、識別性の不足から `Notification` hook と同じ
`jq` + `osascript` パターンへ統一した。

### OSC 9 経路を採用しなかった理由
Claude Code → nvim → tmux → Ghostty の経路で OSC 9 (デスクトップ通知シーケンス) は届かない。
原因は **nvim の `:terminal` (libvterm ベース) が認識しない OSC をサイレント破棄する設計** にあること。
- Ghostty / iTerm2 / Alacritty: OSC 9 を受信すれば通知可能 (最終受信者として機能)
- tmux: `allow-passthrough on` で OSC を通せる (中継器)
- **nvim: OSC 9 を破棄する。公式に passthrough オプション無し** ← ボトルネック

ターミナルを iTerm2 等に変更しても、nvim の `:terminal` 内で Claude Code を動かす限り
OSC 9 通知は機能しない。

### 不採用にした代替案
`TermRequest` autocmd で OSC 9 を捕捉し `vim.v.stderr` 経由で外側に書き戻す方法は技術的には可能。
だが以下の保守性リスクから採用しない:
- `TermRequest` の event data 仕様が nvim バージョン間で揺れる (0.10→0.11 で破壊的変更あり)
- tmux 内では DCS ラッパー (`\033Ptmux;…\033\\`) で包む必要があり、エスケープ処理が複雑
- 現状の osascript 経路で十分機能しており、追加実装の便益が薄い

### 設計原則
通知のような重要なイベントは中継点が多いほど壊れやすい。
osascript 経路は中継点ゼロで macOS の通知 API に直行するため、最も堅牢。
nvim 経路 (開発体験) と通知経路 (運用イベント) を分離する構成を採用している。

### 参考
- Claude Code Hooks: https://docs.claude.com/en/docs/claude-code/hooks
- neovim issue (terminal passthrough): https://github.com/neovim/neovim/issues/7584
