--[[
  Claude Code統合用Neovimキーマップ設定

  このファイルはClaude CodeとNeovimを統合するためのキーマップを定義します。

  主な機能:
  - 基本操作: Claude Codeの起動、フォーカス、再開、継続
  - モデル選択: 使用するClaudeモデルの切り替え
  - コンテキスト管理: 現在のバッファやビジュアル選択範囲の送信
  - ファイルツリー統合: NvimTree等のファイルエクスプローラからのファイル追加
  - Diff管理: Claude Codeが提案する変更の承認/却下
  - レイアウト切替: タブ全画面 ⇔ 右側split を切替 (<leader>aw)
  - 幅サイクル: split表示時の幅を 30%/50%/70% で順送り (<M-w>)

  キーマップのプレフィックス: <leader>a (AI/Claude Code用)

  表示レイアウトの考え方:
  - フロートは使わない。Claude は常に「実ウィンドウ」として表示する。
  - 既定は専用タブでの全画面表示。snacks で vsplit として開いた直後に wincmd T で
    専用タブへ移して全画面化する(snacks には「タブ全画面」position が無いため)。
  - 他バッファと並べたい/相対表示したいときは、タブ内で :vsplit するか、
    <leader>aw で「コードタブ内の右側 split」に切り替える。どちらも実ウィンドウなので
    :vsplit やバッファ追加など vim 標準機能がそのまま効く。
--]]

-- Claude関連のキーマップ設定
local opts = {
  noremap = true,
  silent = true,
}

local keymap = vim.keymap.set

-- Claude terminal バッファ名のパターン(term://...claude)
-- lazygit等の他の terminal バッファと区別するために使う
local CLAUDE_BUF_PATTERN = '^term://.*claude$'

-- Claude Codeのterminalバッファかどうかを判定する
local function is_claude_code_buffer()
  return vim.api.nvim_buf_get_name(0):match(CLAUDE_BUF_PATTERN) ~= nil
end

-- ============================================================================
-- 実行環境(マルチプレクサ)による Claude 連携モードの判定
-- ============================================================================
-- 全体: claude をどこで動かすかは実行環境で決まる(判定ロジックの詳細は claude_env.lua)。
--   - "pane"  : herdr 配下。別 pane の claude と WebSocket でやり取りし、nvim 側は
--               terminal を一切開かず、表示・フォーカス・レイアウトの管理もしない。
--   - "buffer": tmux 配下や素の端末。従来どおり nvim buffer 内で claude を扱う。
-- 連携の要点(モード非依存): 送信(at_mention)や diff 承認は WebSocket ベースで、
--   マルチプレクサや buffer の有無に依存せず動く。pane モードで無効化するのは
--   「terminal を開く/フォーカスする/レイアウトを変える」といった buffer 前提の操作のみ。
-- ※ init.lua 側でも同モジュールを使い、pane モードでは terminal provider を "none" にして
--   プラグイン内部(send_at_mention 成功後の ensure_visible)による buffer 起動も抑止する。
local claude_env = require("claude_env")

-- pane モードか(= herdr 配下で nvim buffer を使わない)
local function is_pane_mode()
  return claude_env.is_pane_mode()
end

-- pane モードで buffer 前提の操作(表示・フォーカス・起動・レイアウト)が呼ばれた時の通知。
-- 黙って無視せず理由を伝えることで、誤操作(=nvim 側 claude が起動して pane 側と二重接続し、
-- 送信が両方へブロードキャストされる状態)を防ぐ。
local function notify_pane_mode()
  vim.notify("herdr(pane)モード: claude は別 pane 側で操作してください", vim.log.levels.INFO)
end

-- ============================================================================
-- Claude 表示レイアウト管理 (タブ全画面 ⇔ 右側split)
-- ============================================================================
-- 全体: フロートは使わず、Claude を「実ウィンドウ」として表示する。既定は専用タブでの
--   全画面表示。他バッファと並べたいときは <leader>aw で右側 split に切り替える。
-- 設計の要点:
--   snacks プロバイダには「タブ全画面」という position が無い。そこで snacks には
--   通常どおり vsplit で開かせ、その直後に Vim 標準の `wincmd T` で専用タブへ移動して
--   全画面化する。タブ全画面なら、閉じるときにタブごと閉じてコードタブに戻れるため、
--   「最後のウィンドウは閉じられない(E444)」問題が起きない。
--   タブ内では :vsplit やバッファ追加など Vim 標準機能がそのまま使えるので、
--   「他バッファとの相対表示」も自由に行える。
-- current_layout: "tab"(専用タブ全画面) または "split"(コードタブ内の右側split)
local current_layout = "tab"

-- 指定タブページ内で Claude を表示しているウィンドウ id を返す(無ければ nil)
local function claude_win_in_tab(tabpage)
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):match(CLAUDE_BUF_PATTERN) then
      return w
    end
  end
  return nil
end

-- 全タブを横断して Claude を表示しているウィンドウ id を返す(無ければ nil)
local function claude_win_any()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):match(CLAUDE_BUF_PATTERN) then
      return w
    end
  end
  return nil
end

-- 既に表示中の Claude ウィンドウへフォーカスする。表示中でなければ false を返す。
-- nvim_set_current_win は対象ウィンドウの属するタブページへも切り替わるため、
-- 別タブにある全画面 Claude にもこれだけで移動できる。
local function focus_claude_win()
  local w = claude_win_any()
  if not (w and vim.api.nvim_win_is_valid(w)) then
    return false
  end
  vim.api.nvim_set_current_win(w)
  if vim.bo[vim.api.nvim_win_get_buf(w)].buftype == 'terminal' then
    vim.cmd('startinsert')
  end
  return true
end

-- 現在のレイアウトに従って Claude を開く(セッションは buffer 再利用で継続)
-- cmd_args: 起動引数の文字列(例 "--resume")。新規起動時のみ意味を持つ。
--   claudecode.nvim の terminal.open は cmd_args を文字列として claude コマンドに
--   連結する仕様のため、テーブルではなく文字列を渡す必要がある。
local function open_claude(cmd_args)
  -- pane モードでは nvim 側で terminal を開かない(claude は別 pane で起動済み)
  if is_pane_mode() then
    notify_pane_mode()
    return
  end
  local term = require("claudecode.terminal")
  if current_layout == "tab" then
    -- いったん現タブに vsplit で開かせ、その直後に専用タブへ移して全画面化する。
    term.open({}, cmd_args)
    local w = claude_win_in_tab(0)
    -- 現タブに他ウィンドウがある場合のみ wincmd T で新規タブへ移動
    -- (既に単独なら移動不要。単独ウィンドウに対する wincmd T はエラーになる)
    if w and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      vim.api.nvim_set_current_win(w)
      vim.cmd('wincmd T')
    end
  else
    -- 右側 split。コードタブ内で他バッファと並べて表示する。
    term.open({ snacks_win_opts = { position = "right", width = 0.40, height = 0 } }, cmd_args)
  end
end

-- Claude を表示してフォーカスする(既に表示中なら集中するだけ)
local function show_claude()
  -- pane モードでは表示すべき nvim buffer が無いので何もしない
  if is_pane_mode() then
    notify_pane_mode()
    return
  end
  if focus_claude_win() then
    return
  end
  open_claude(nil)
end

-- 送信後のフォーカス移動。
-- buffer モードでは claude を表示してフォーカスする(従来 UX)。
-- pane モードでは送信自体が主目的で完了しているため、何もしない(通知も出さない。
-- 送信のたびに通知が出ると煩わしいため、明示的な表示操作とは区別する)。
local function focus_after_send()
  if is_pane_mode() then
    return
  end
  show_claude()
end

-- 外部起動(dotfiles エイリアス等)から、現在のレイアウト(既定=タブ全画面)で Claude を開くコマンド。
-- 背景: dotfiles エイリアスは従来ネイティブの :ClaudeCode を呼んでいたが、これは snacks の
--   右 split で開くだけで、独自の全画面ロジック(open_claude の wincmd T)を通らない。
--   起動直後も全画面で開くため、show_claude を呼ぶ専用コマンドを公開し、エイリアス側で使う。
vim.api.nvim_create_user_command("ClaudeStart", function()
  show_claude()
end, { desc = "Open Claude in current layout (default: fullscreen tab)" })

-- Claude を非表示にする。表示中の Claude ウィンドウを閉じる。
-- 全画面タブの場合は唯一のウィンドウなのでタブごと閉じてコードタブに戻る
-- (他タブが存在するため E444 にはならない)。buffer/ジョブは残りセッションは継続。
local function hide_claude()
  local w = claude_win_any()
  if w and vim.api.nvim_win_is_valid(w) then
    pcall(vim.api.nvim_win_close, w, false)
    return true
  end
  return false
end

-- 表示/非表示をトグルする (<leader>ac)
local function toggle_claude()
  -- pane モードでは nvim 側に表示対象が無いのでトグルしない
  if is_pane_mode() then
    notify_pane_mode()
    return
  end
  if not hide_claude() then
    show_claude()
  end
end

-- レイアウトを切り替えて即再表示する (<leader>aw)
-- いったん閉じてから現在のレイアウトで開き直す。
local function toggle_layout()
  -- pane モードでは nvim buffer のレイアウト概念が無いので何もしない
  if is_pane_mode() then
    notify_pane_mode()
    return
  end
  hide_claude()
  current_layout = (current_layout == "tab") and "split" or "tab"
  open_claude(nil)
  vim.notify("Claude layout: " .. current_layout, vim.log.levels.INFO)
end

-- ヘルパー関数: コマンド実行後にフォーカス(現在のレイアウトで表示する)
-- 全体: cmd は ClaudeCodeAdd 等の WebSocket 送信コマンドなので、モードに依らず必ず実行する。
--   フォーカスだけをモードに応じて分岐する(pane モードでは何もしない)。
local function with_focus(cmd)
  return function ()
    vim.cmd(cmd)
    focus_after_send()
  end
end

-- AI/Claude Code キーマップ
keymap('n', '<leader>a', '', vim.tbl_extend('force', opts, { desc = 'AI/Claude Code' }))
-- 基本的な操作
-- 全体: 組み込みコマンドではなく自前のラッパー関数を呼ぶ。
--   これは現在のレイアウト(タブ全画面/右側split)を維持して開閉するため。
keymap('n', '<leader>ac', toggle_claude, vim.tbl_extend('force', opts, { desc = 'Toggle Claude' }))
keymap('n', '<leader>af', show_claude, vim.tbl_extend('force', opts, { desc = 'Focus Claude' }))
-- レイアウト切替: タブ全画面 ⇔ 右側split
keymap('n', '<leader>aw', toggle_layout,
  vim.tbl_extend('force', opts, { desc = 'Toggle Claude layout (tab/split)' }))

-- M-c: Claude Codeバッファとコードバッファ間のフォーカスをトグルする
-- normalモード: Claude Codeバッファなら離脱(タブ全画面なら前タブへ、split なら前ウィンドウへ)、
--   それ以外なら Claude Code にフォーカス
keymap('n', '<M-c>', function()
  -- pane モードでは claude buffer が無く、フォーカス往復は herdr 側の操作で行う
  if is_pane_mode() then
    notify_pane_mode()
    return
  end
  if is_claude_code_buffer() then
    -- 全画面タブ(=タブ内に Claude しかない)なら前のタブへ、そうでなければ前ウィンドウへ
    if #vim.api.nvim_tabpage_list_wins(0) == 1 then
      vim.cmd('tabprevious')
    else
      vim.cmd('wincmd p')
    end
  else
    show_claude()
  end
end, vim.tbl_extend('force', opts, { desc = 'Toggle Claude focus' }))
-- terminalモード: Claude Code内でinsert状態の時にコードバッファへ戻る
-- 全画面タブの場合は前ウィンドウが無いので、その時は前タブへ戻す
keymap('t', '<M-c>', function()
  -- terminalモードを抜けてから移動する
  vim.cmd('stopinsert')
  if #vim.api.nvim_tabpage_list_wins(0) == 1 then
    vim.cmd('tabprevious')
  else
    vim.cmd('wincmd p')
  end
end, opts)
keymap('n', '<leader>ar', function() open_claude("--resume") end,
  vim.tbl_extend('force', opts, { desc = 'Resume Claude' }))
keymap('n', '<leader>aC', function() open_claude("--continue") end,
  vim.tbl_extend('force', opts, { desc = 'Continue Claude' }))
-- モデル選択: ClaudeCodeSelectModel は選択後に nvim terminal で claude を起動する実装のため、
--   pane モードでは意味を持たない(claude は pane 側で起動済み)。pane 側で /model を使う。
keymap('n', '<leader>am', function()
  if is_pane_mode() then
    notify_pane_mode()
    return
  end
  vim.cmd('ClaudeCodeSelectModel')
end, vim.tbl_extend('force', opts, { desc = 'Select Claude model' }))
-- コンテキスト送信(送信後にフォーカス)
keymap('n', '<leader>ab', with_focus('ClaudeCodeAdd %'), vim.tbl_extend('force', opts, { desc = 'Add current buffer' }))
-- 全体: 選択追跡を使わず範囲だけ送ってカーソル遅延を避ける
-- 詳細: visual の marks と現在行から 0-index 行番号へ変換して送信する
local function send_range_to_claude(start_line, end_line)
  if not start_line or not end_line or start_line <= 0 or end_line <= 0 then
    return
  end
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == "" then
    return
  end
  local claudecode = require("claudecode")
  claudecode.send_at_mention(file_path, start_line - 1, end_line - 1, "ClaudeCodeSend")
end

-- 全体: visual モード中でも確実に範囲を取得できるようにする
-- 詳細: 未確定の '<' '>' ではなく固定アンカー(v)と現在カーソルから算出する
local function get_visual_line_range()
  local anchor = vim.fn.getpos("v")
  if not anchor or anchor[2] == 0 then
    return nil, nil
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line1 = anchor[2]
  local line2 = cursor[1]
  if line1 <= line2 then
    return line1, line2
  end
  return line2, line1
end

keymap('v', '<leader>as', function()
  local start_line, end_line = get_visual_line_range()
  if not start_line or not end_line then
    local line1 = vim.fn.line("'<")
    local line2 = vim.fn.line("'>")
    start_line = math.min(line1, line2)
    end_line = math.max(line1, line2)
  end
  send_range_to_claude(start_line, end_line)
  vim.schedule(focus_after_send)
end, vim.tbl_extend('force', opts, { desc = 'Send to Claude' }))
-- 現在行を選択してClaudeに送信
-- feedkeysの第3引数をtrueにすると、キューを即座に処理する
keymap('n', '<leader>al', function ()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  send_range_to_claude(line, line)
  vim.schedule(focus_after_send)
end, vim.tbl_extend('force', opts, { desc = 'Send line and focus' }))


-- ファイルツリー用の特別なキーマップ設定
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "NvimTree", "neo-tree", "oil", "minifiles" },
  callback = function()
    keymap('n', '<leader>as', with_focus('ClaudeCodeTreeAdd'),
      vim.tbl_extend('force', opts, { desc = 'Add file' }))
  end,
})

-- Diff管理 (dy=yes/accept, dn=no/deny)
keymap('n', '<leader>dy', '<cmd>ClaudeCodeDiffAccept<cr>', vim.tbl_extend('force', opts, { desc = 'Accept diff (yes)' }))
keymap('n', '<leader>dn', '<cmd>ClaudeCodeDiffDeny<cr>', vim.tbl_extend('force', opts, { desc = 'Deny diff (no)' }))

-- ============================================================================
-- Claude window 幅サイクル (30% → 50% → 70% → 30% → ...)
-- ============================================================================
-- 全体: <leader>aw で split レイアウトに切り替えたあと、その幅を微調整するための機能。
--       既存 window の幅だけを動的に変え、window の close/再生成は行わないため
--       claudecode.nvim/snacks の管理状態に干渉せず副作用が小さい。
-- 使い方: 任意の場所から <M-w> を押すと、表示中の claude window の幅が次のステップに循環する。
-- 注意: 既定のタブ全画面表示では幅変更の効果は無い(主に split 表示時に使う想定)。
-- 補足: Vim 標準の以下も併用可能。
--   <C-w>|  現在 window を最大幅に(他は最小化)
--   <C-w>=  全 window を均等再分配(元に戻す)
--   <C-w>T  現在 window を新規タブに移動(=実質フルスクリーン。gT で前タブに戻る)
-- ============================================================================
local width_steps = { 30, 50, 70 }
local width_idx = 1

local function cycle_claude_width()
  -- pane モードでは幅調整対象の nvim window が無い
  if is_pane_mode() then
    notify_pane_mode()
    return
  end
  -- claude buffer を表示している window を探して、その幅だけを変える
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_get_name(buf):match('^term://.*claude$') then
      width_idx = width_idx % #width_steps + 1
      vim.api.nvim_win_set_width(w, math.floor(vim.o.columns * width_steps[width_idx] / 100))
      return
    end
  end
  vim.notify('Claude Code window is not visible', vim.log.levels.INFO)
end

keymap('n', '<M-w>', cycle_claude_width,
  vim.tbl_extend('force', opts, { desc = 'Cycle Claude width (30/50/70%)' }))
