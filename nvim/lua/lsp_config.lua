-- LSP関連の設定

-- ==============================
-- 1. キーマップヘルパー関数の定義
-- ==============================
-- 'keymap' 関数は、LSPAttachオートコマンド内で使用される前に定義されている必要があります。
-- これは 'keymaps.lua' など、別のファイルで定義されている場合が多いです。
-- もし定義されていない場合は、以下を追加してください。
local default_keymap_opts = { noremap = true, silent = true }

local function keymap(mode, lhs, rhs, opts)
  opts = opts or default_keymap_opts
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- ==============================
-- 2. 診断表示のグローバル設定
-- ==============================
-- `vim.diagnostic.config` は、Neovimの起動時に一度だけ設定されれば良いです。
-- これはファイル全体に影響を与えるため、LSPAttachのコールバック内ではなく、
-- ファイルの先頭近くに配置するのが一般的です。
vim.diagnostic.config({
  severity_sort = true,
  float = {
    source = true,
    focusable = false,
    border = "single",
    header = "",
    prefix = "",
  },
  signs = {
    active = true,
    -- signsはLSPアイコンの表示を制御します。
    -- 個別のアイコンは通常、colorschemeまたは別の診断プラグインで設定します。
  },
  underline = true,
  update_in_insert = false,
  -- virtual_textに関するコメントは削除または有効化してください。
  -- virtual_text = {
  --   enabled = true,
  --   spacing = 4,
  --   severity = { min = vim.diagnostic.severity.WARN },
  --   prefix = "●",
  -- },
})

-- 診断を更新するタイミング: カーソルが静止したときにquickfixリストを更新
vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.setqflist()]]

-- 診断関連のグローバルキーマップ
-- これらのキーマップはLSPアタッチとは関係なく、常に利用可能です。
keymap("n", "<leader>d", function() vim.diagnostic.open_float() end, { desc = "Show diagnostic" })
keymap("n", "[d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Go to previous diagnostic" })
keymap("n", "]d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Go to next diagnostic" })


-- ==============================
-- 3. LSPサーバアタッチ時の処理とバッファローカルキーマップ
-- ==============================
-- LSPサーバがバッファにアタッチされたときにのみ実行される設定。
-- ここでは、LSPの機能に特化したキーマップを設定します。
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ctx)
    -- バッファごとのオプション: このキーマップが現在のバッファでのみ有効であることを保証します。
    local bufopts = { noremap = true, silent = true, buffer = ctx.buf }

    -- LSP基本機能
    keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", bufopts)
    keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", bufopts)
    keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", bufopts)
    keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", bufopts)
    keymap("n", "<space>k", "<cmd>lua vim.lsp.buf.signature_help()<CR>", bufopts)
    keymap("n", "<space>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", bufopts)
    keymap("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", bufopts)
    keymap("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", bufopts)
    keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", bufopts)
    keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.format()<CR>", bufopts) -- フォーマッタ設定が別途必要

    -- ワークスペース関連
    keymap("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", bufopts)
    keymap("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", bufopts)
    keymap("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", bufopts)

    -- 診断関連
    -- show_line_diagnostics() は非推奨なので open_float() に変更
    keymap("n", "<space>e", "<cmd>lua vim.diagnostic.open_float()<CR>", bufopts)
    keymap("n", "<space>q", "<cmd>lua vim.diagnostic.set_loclist()<CR>", bufopts)

    -- 分割ウィンドウでの定義ジャンプ (オプション)
    -- keymap('n', 'gd<Space>', ':split | lua vim.lsp.buf.definition()<CR>', bufopts)
    -- keymap('n', 'gd<CR>', ':vsplit | lua vim.lsp.buf.definition()<CR>', bufopts)
  end,
})
