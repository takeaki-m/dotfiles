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

-- AI/Claude Code キーマップ
keymap('n', '<leader>a', '', vim.tbl_extend('force', opts, { desc = 'AI/Claude Code' }))
keymap('n', '<leader>ac', '<cmd>ClaudeCode<cr>', vim.tbl_extend('force', opts, { desc = 'Toggle Claude' }))
keymap('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', vim.tbl_extend('force', opts, { desc = 'Focus Claude' }))
keymap('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', vim.tbl_extend('force', opts, { desc = 'Resume Claude' }))
keymap('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', vim.tbl_extend('force', opts, { desc = 'Continue Claude' }))
keymap('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', vim.tbl_extend('force', opts, { desc = 'Select Claude model' }))
keymap('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', vim.tbl_extend('force', opts, { desc = 'Add current buffer' }))
keymap('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', vim.tbl_extend('force', opts, { desc = 'Send to Claude' }))

-- ファイルツリー用の特別なキーマップ設定
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "NvimTree", "neo-tree", "oil", "minifiles" },
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', '<leader>as', '<cmd>ClaudeCodeTreeAdd<cr>',
    vim.tbl_extend('force', opts, { desc = 'Add file' }))
  end,
})

-- Diff管理
keymap('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', vim.tbl_extend('force', opts, { desc = 'Accept diff' }))
keymap('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', vim.tbl_extend('force', opts, { desc = 'Deny diff' }))

