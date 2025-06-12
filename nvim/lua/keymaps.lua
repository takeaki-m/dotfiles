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

--Esc
keymap('i', 'jj', '<ESC>', { silent = true })
keymap('i', '<C-j>', '<ESC>', { silent = true })
keymap('i', 'っj', '<ESC>', { silent = true })

-- increment and decrement
keymap('n', '+', '<C-a>', opts)
keymap('n', '-', '<C-x>', opts)

-- hilight off in two ESC times
keymap('n', '<Esc><Esc>', ':nohlsearch<CR>', opts)
keymap('n', '<C-j>', ':bnext<CR>', opts)
keymap('n', '<C-k>', ':bprev<CR>', opts)

-- telescope
-- telescope find files
keymap('n', '<Leader>ff', ':Telescope find_files<CR>', opts)
-- telescope find character
keymap('n', '<Leader>fg', ':Telescope live_grep<CR>', opts)
-- telescope find buffers
keymap('n', '<Leader>fb', ':Telescope buffers<CR>', opts)


-- fern keybinding
keymap('n', '<C-n>', ':Fern . -reveal=% -drawer -toggle -width=30<CR>', opts)

-- buffer
--keymap ('n', '<C-b>', ':ls<CR>:buf', opts)
--keymap ('n', '<Leader>b', ':b<Space>', opts)

-- 補完表示時のEnterで改行をしない
keymap('i', '<CR>', 'pumvisible() ? "<C-y>" : "<CR>"', { expr = true, noremap = true })

-- 補完表示時の<C-n>と<C-p>の挙動を設定
keymap('i', '<C-n>', 'pumvisible() ? "<Down>" : "<C-n>"', { expr = true, noremap = true })
keymap('i', '<C-p>', 'pumvisible() ? "<Up>" : "<C-p>"', { expr = true, noremap = true })

---- indent
keymap('n', '<C-l>', '>>', opts)
keymap('n', '<C-h>', '<<', opts)
keymap('v', '<C-l>', '>gv', opts)
keymap('v', '<C-h>', '<gv', opts)
--keymap('i', '<C-l>', '<C-o>>>', opts) -- 挿入モードからノーマルモードに戻る
--keymap('i', '<C-h>', '<C-o><<', opts) -- 挿入モードからノーマルモードに戻る

-- うまく後かないからコメントアウトする
-- コマンドラインモードでc-n,c-pでも補完を有効にするために方向キーに割り当てる
--keymap('c', '<C-p>', '<Up>', opts)
--keymap('c', '<C-n>', '<Down>', opts)
keymap("t", "fj", "<C-\\><C-n>", opts)

keymap('n', '<Leader>lg', ':LazyGit<CR>', opts)
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
keymap('x', 'p', '"_dP', { noremap = true })

function PasteCommandOutput(command)
  local output = vim.fn.system(command)
  output = output:gsub("[\r\n]+", "") -- 改行を削除する
  output = output:gsub("%z", "")      -- NUL文字を削除する
  vim.api.nvim_put({ output }, '', true, true)
end

keymap('n', '<Leader>rp', ':lua PasteCommandOutput("readlink -f " .. vim.fn.expand("%"))<CR>',
  { noremap = true, silent = true })

-- コマンドラインwindowでの動作を設定する
--normal modeでも動作してしまい、telescopeの動作と被るためコメントアウト
--vim.api.nvim_create_autocmd("CmdwinEnter", {
--    callback = function()
--        local opts_cursol = { buffer = true, noremap = true }
--        keymap("n", "<C-p>", "<Up>", opts_cursol)
--        keymap("n", "<C-n>", "<Down>", opts_cursol)
--        keymap("n", "<C-b>", "<Left>", opts_cursol)
--        keymap("n", "<C-f>", "<Right>", opts_cursol)
--        keymap("n", "<C-a>", "<Home>", opts_cursol)  -- 行頭に移動
--        keymap("n", "<C-e>", "<End>", opts_cursol)   -- 行末に移動
--    end,
--})
