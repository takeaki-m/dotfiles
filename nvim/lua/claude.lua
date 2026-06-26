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
  if focus_claude_win() then
    return
  end
  open_claude(nil)
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
  if not hide_claude() then
    show_claude()
  end
end

-- レイアウトを切り替えて即再表示する (<leader>aw)
-- いったん閉じてから現在のレイアウトで開き直す。
local function toggle_layout()
  hide_claude()
  current_layout = (current_layout == "tab") and "split" or "tab"
  open_claude(nil)
  vim.notify("Claude layout: " .. current_layout, vim.log.levels.INFO)
end

-- ヘルパー関数: コマンド実行後にフォーカス(現在のレイアウトで表示する)
local function with_focus(cmd)
  return function ()
    vim.cmd(cmd)
    show_claude()
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
keymap('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', vim.tbl_extend('force', opts, { desc = 'Select Claude model' }))
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
  vim.schedule(show_claude)
end, vim.tbl_extend('force', opts, { desc = 'Send to Claude' }))
-- 現在行を選択してClaudeに送信
-- feedkeysの第3引数をtrueにすると、キューを即座に処理する
keymap('n', '<leader>al', function ()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  send_range_to_claude(line, line)
  vim.schedule(show_claude)
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
