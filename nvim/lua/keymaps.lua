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

-- move to specified line with <CR> insted of G
keymap('n', '<CR>', 'G', opts)
-- move top of file with <BS> instead of gg
keymap('n', '<BS>', 'gg', opts)

-- add newline at endofthefile
_G.add_new_line = function()
  local n_lines = vim.api.nvim_buf_line_count(0)
  local last_nonblank = vim.fn.prevnonblank(n_lines)
  if last_nonblank <= n_lines then vim.api.nvim_buf_set_lines(0, last_nonblank, n_lines, true, { '' }) end
end

vim.cmd([[
  augroup AddNewlineOnSave
    autocmd!
    autocmd BufWritePre * lua _G.add_new_line()
  augroup END
]])

-- vp doesn't replace paste buffer
keymap('x', 'p', '"_dP', {noremap = true})

function PasteCommandOutput(command)
  local output = vim.fn.system(command)
  output = output:gsub("[\r\n]+", "")  -- 改行を削除する
  output = output:gsub("%z", "")  -- NUL文字を削除する
  vim.api.nvim_put({output}, '', true, true)
end

vim.api.nvim_set_keymap('n', '<Leader>rp', ':lua PasteCommandOutput("readlink -f " .. vim.fn.expand("%"))<CR>', {noremap = true, silent = true})

