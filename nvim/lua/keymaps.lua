
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

