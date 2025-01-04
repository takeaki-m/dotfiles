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

-- buffer
keymap ('n', '<C-H>', ':ls<CR>:buf', opts)

-- 補完表示時のEnterで改行をしない
keymap('i', '<CR>', 'pumvisible() ? "<C-y>" : "<CR>"', { expr = true, noremap = true })

-- 補完表示時の<C-n>と<C-p>の挙動を設定
keymap('i', '<C-n>', 'pumvisible() ? "<Down>" : "<C-n>"', { expr = true, noremap = true })
keymap('i', '<C-p>', 'pumvisible() ? "<Up>" : "<C-p>"', { expr = true, noremap = true })

-- うまく後かないからコメントアウトする
-- コマンドラインモードでc-n,c-pでも補完を有効にするために方向キーに割り当てる
--keymap('c', '<C-p>', '<Up>', opts)
--keymap('c', '<C-n>', '<Down>', opts)

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


-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
keymap('n', '<space>e', '<cmd>:lua vim.diagnostic.open_float()<CR>', opts)
keymap('n', '[d', '<cmd>:lua vim.diagnostic.goto_prev()<CR>', opts)
keymap('n', ']d', '<cmd>:lua vim.diagnostic.goto_next()<CR>', opts)


-- LSPサーバアタッチ時の処理
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ctx)
    keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
    keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
    keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    keymap("n", "<space>k", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    keymap("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
    keymap("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
    keymap("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
    keymap("n", "<space>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
    keymap("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    keymap("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
    keymap("n", "<space>e", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", opts)
    keymap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
    keymap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
    keymap("n", "<space>q", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)
    keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.format()<CR>", opts)
    --keymap('n', 'gd<Space>', ':split | lua vim.lsp.buf.definition()<CR>', opts)
    --keymap('n', 'gd<CR>', ':vsplit | lua vim.lsp.buf.definition()<CR>', opts)
  end,
})
