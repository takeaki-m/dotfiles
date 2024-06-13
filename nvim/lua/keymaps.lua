local opts = {
  noremap = true,
  silent = true,
}
local keymap = vim.api.nvim_set_keymap

-- use space as Leader
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Save file with space + w
keymap('n', '<Leader>w', ':w<CR>', opts)

-- increment and decrement
keymap('n', '+', '<C-a>', opts)
keymap('n', '-', '<C-x>', opts)

-- hilight off in two ESC times
keymap('n', '<Esc><Esc>', ':nohlsearch<CR>', opts)
keymap('n', '<C-j>', ':bnext<CR>', opts)
keymap('n', '<C-k>', ':bprev<CR>', opts)
-- telescope find files
keymap('n', '<C-p>', ':Telescope find_files<CR>', opts)
-- telescope find character
keymap('n', '<C-s>', ':Telescope live_grep<CR>', opts)

-- fern
keymap('n', '<C-n>', ':Fern . -reveal=% -drawer -toggle -width=30<CR>', opts)

-- 補完表示時のEnterで改行をしない
keymap('i', '<CR>', 'pumvisible() ? "<C-y>" : "<CR>"', { expr = true, noremap = true })

-- 補完表示時の<C-n>と<C-p>の挙動を設定
keymap('i', '<C-n>', 'pumvisible() ? "<Down>" : "<C-n>"', { expr = true, noremap = true })
keymap('i', '<C-p>', 'pumvisible() ? "<Up>" : "<C-p>"', { expr = true, noremap = true })

-- move to specified line with <CR> insted of G
-- keymap('n', '<CR>', 'G', opts)
-- move top of file with <BS> instead of gg
-- keymap('n', '<BS>', 'gg', opts)

--vim.cmd([[
--  augroup AddNewlineOnSave
--    autocmd!
--    autocmd BufWritePre * lua _G.add_new_line()
--  augroup END
--]])

-- vp doesn't replace paste buffer
keymap('x', 'p', '"_dP', {noremap = true})

function PasteCommandOutput(command)
  local output = vim.fn.system(command)
  output = output:gsub("[\r\n]+", "")  -- 改行を削除する
  output = output:gsub("%z", "")  -- NUL文字を削除する
  vim.api.nvim_put({output}, '', true, true)
end

vim.api.nvim_set_keymap('n', '<Leader>rp', ':lua PasteCommandOutput("readlink -f " .. vim.fn.expand("%"))<CR>', {noremap = true, silent = true})

