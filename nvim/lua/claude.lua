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
keymap('n', '<leader>ac', '<cmd>ClaudeCode<cr>', vim.tbl_extend('force', opts, { desc = 'Toggle Claude' }))
keymap('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', vim.tbl_extend('force', opts, { desc = 'Focus Claude' }))
keymap('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', vim.tbl_extend('force', opts, { desc = 'Resume Claude' }))
keymap('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', vim.tbl_extend('force', opts, { desc = 'Continue Claude' }))
keymap('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', vim.tbl_extend('force', opts, { desc = 'Select Claude model' }))
-- コンテキスト送信(送信後にフォーカス)
keymap('n', '<leader>ab', with_focus('ClaudeCodeAdd %'), vim.tbl_extend('force', opts, { desc = 'Add current buffer' }))
-- ビジュアルモードでは選択範囲を保持するため、feedkeysを使用
-- with_focus関数を利用したことで、visual modeのコンテキストを失っている可能性がある。
--そのため以下のようなシンプルな設定では、visualモードの選択範囲を認識できていない可能性がある
-- keymap('v', '<leader>as', with_focus('ClaudeCodeSend'), vim.tbl_extend('force', opts, { desc = 'Send to Claude' }))
keymap('v', '<leader>as', function()
  -- 以下はvisual modeから実行することで自動的に`:'<,>ClaudeCodeSend`として解釈される
  vim.api.nvim_feedkeys(':ClaudeCodeSend\r', 'nx', true)
  vim.schedule(function()
    vim.cmd('ClaudeCodeFocus')
  end)
end, vim.tbl_extend('force', opts, { desc = 'Send to Claude' }))
-- 現在行を選択してClaudeに送信
-- feedkeysの第3引数をtrueにすると、キューを即座に処理する
keymap('n', '<leader>al', function ()
  -- feedkeysの第3引数true - キー入力を即座に処理
  -- 'nx'フラグ - xが即時実行を指示
  vim.api.nvim_feedkeys('V:ClaudeCodeSend\r', 'nx', true)
  -- vim.schedule - 固定時間の遅延ではなく、次のイベントループで実行
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

-- Diff管理
keymap('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', vim.tbl_extend('force', opts, { desc = 'Accept diff' }))
keymap('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', vim.tbl_extend('force', opts, { desc = 'Deny diff' }))

