--[[
  Claude Code統合用Neovimキーマップ設定
  
  このファイルはClaude CodeとNeovimを統合するためのキーマップを定義します。
  
  主な機能:
  - 基本操作: Claude Codeの起動、フォーカス、再開、継続
  - モデル選択: 使用するClaudeモデルの切り替え
  - コンテキスト管理: 現在のバッファやビジュアル選択範囲の送信
  - ファイルツリー統合: NvimTree等のファイルエクスプローラからのファイル追加
  - Diff管理: Claude Codeが提案する変更の承認/却下
  
  キーマップのプレフィックス: <leader>a (AI/Claude Code用)
--]]

-- Claude関連のキーマップ設定
local opts = {
  noremap = true,
  silent = true,
}

local keymap = vim.keymap.set

-- ヘルパー関数: コマンド実行後にフォーカス
local function with_focus(cmd)
  return function ()
    vim.cmd(cmd)
    vim.cmd('ClaudeCodeFocus')
  end
end

-- AI/Claude Code キーマップ
keymap('n', '<leader>a', '', vim.tbl_extend('force', opts, { desc = 'AI/Claude Code' }))
-- 基本的な操作
keymap('n', '<leader>ac', '<cmd>ClaudeCode<cr>', vim.tbl_extend('force', opts, { desc = 'Toggle Claude' }))
keymap('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', vim.tbl_extend('force', opts, { desc = 'Focus Claude' }))
keymap('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', vim.tbl_extend('force', opts, { desc = 'Resume Claude' }))
keymap('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', vim.tbl_extend('force', opts, { desc = 'Continue Claude' }))
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
  vim.schedule(function()
    vim.cmd('ClaudeCodeFocus')
  end)
end, vim.tbl_extend('force', opts, { desc = 'Send to Claude' }))
-- 現在行を選択してClaudeに送信
-- feedkeysの第3引数をtrueにすると、キューを即座に処理する
keymap('n', '<leader>al', function ()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  send_range_to_claude(line, line)
  vim.schedule(function()
    vim.cmd('ClaudeCodeFocus')
  end)
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
