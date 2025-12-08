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
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    vim.keymap.set("n", "gf", function ()
      vim.lsp.buf.format({async = true})
    end, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    vim.keymap.set("n", "<leader>gt", vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set("n", "gn", vim.lsp.buf.rename, bufopts)
    vim.keymap.set("n", "ga", vim.lsp.buf.code_action, bufopts)
    vim.keymap.set("n", "ge", vim.diagnostic.open_float, bufopts)
    vim.keymap.set("n", "g]", function ()
      vim.diagnostic.jump({ count = 1, float = true})
    end, bufopts)
    vim.keymap.set("n", "g[", function ()
      vim.diagnostic.jump({ count = -1, float = true})
    end, bufopts)
    vim.keymap.set("n", "gh", vim.lsp.buf.signature_help, bufopts)

    -- ワークスペース関連
    keymap("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    keymap("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    keymap("n", "<space>wl", function ()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)

    -- 診断関連
    keymap("n", "<space>e", vim.diagnostic.open_float, bufopts)
    keymap("n", "<space>q", vim.diagnostic.setloclist, bufopts)
    keymap("n", "<space>Q", function()
      vim.diagnostic.setqflist({ open = true })
    end, bufopts)
    -- 分割ウィンドウでの定義ジャンプ (オプション)
    -- keymap('n', 'gd<Space>', ':split | lua vim.lsp.buf.definition()<CR>', bufopts)
    -- keymap('n', 'gd<CR>', ':vsplit | lua vim.lsp.buf.definition()<CR>', bufopts)
  end,
})
