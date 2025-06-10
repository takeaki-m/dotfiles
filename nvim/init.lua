require("command")
require("keymaps")
require("options")
require("lsp_config")

-- activate vim loader to use plugin manager
vim.loader.enable()

-- activate pkcr vim
local function bootstrap_pckr()
  local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"
---@diagnostic disable-next-line: undefined-field
  if not (vim.ur or vim.loop).fs_stat(pckr_path) then
    vim.fn.system({
      'git',
      'clone',
      "--filter=blob:none",
      'https://github.com/lewis6991/pckr.nvim',
      pckr_path
    })
  end
  vim.opt.rtp:prepend(pckr_path)
end

bootstrap_pckr()

require('pckr').add{
  'nvim-treesitter/nvim-treesitter';
  'nvim-lua/plenary.nvim';
  'nvim-telescope/telescope.nvim';
  'lukas-reineke/indent-blankline.nvim';
  'lambdalisue/fern.vim';
  'lewis6991/gitsigns.nvim';
  'nvim-lualine/lualine.nvim';
  'kdheepak/lazygit.nvim';
  'neovim/nvim-lspconfig';
  'williamboman/mason.nvim';
  'williamboman/mason-lspconfig.nvim';
  'L3MON4D3/LuaSnip';
  'kylechui/nvim-surround';
  'ixru/nvim-markdown';
  'folke/lazydev.nvim'; -- luaのcomplitionにnvimの設定を読み込ませる
  -- complition
  'hrsh7th/nvim-cmp';
  'hrsh7th/cmp-nvim-lsp';
  'hrsh7th/cmp-buffer';
  'saadparwaiz1/cmp_luasnip';
  -- lsp
  'artempyanykh/marksman';
  -- colortheme
  "folke/tokyonight.nvim";
  "rebelot/kanagawa.nvim";
  "EdenEast/nightfox.nvim";
  "catppuccin/nvim";
}

require("colorscheme")
-- luaのlsp server(lua_ls)が、vim関連の関数を認識できるように、他のライブラリよりも優先的に読み込む
require("lazydev").setup()
-- nvim-surround
require("nvim-surround").setup()
-- activate indent-blankline.nvim
require('ibl').setup()
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
      refresh_time = 16, -- ~60fps
      events = {
        'WinEnter',
        'BufEnter',
        'BufWritePost',
        'SessionLoadPost',
        'FileChangedShellPost',
        'VimResized',
        'Filetype',
        'CursorMoved',
        'CursorMovedI',
        'ModeChanged',
      },
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}
-- lsp
require("mason").setup()

-- mason-lspconfigの推奨される設定方法
-- capabilitiesはmason-lspconfigではなく、cmp-nvim-lspから取得します
local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason-lspconfig").setup({
  -- 自動インストールしたいLSPサーバーがあればここに記述
  -- 以下の名称はmason.nvimで使われる名称名ではなく、nvim-lspconfigで一般的に使われるサーバー名を指定する必要あり
  automatic_enable = {};
  ensure_installed = {
    "lua_ls",
    "marksman",
    "pylsp",
    "terraformls",
    --"bashls",
  },
})

-- lspconfig で LSP サーバーを設定
-- mason-lspconfig は lspconfig と連携して、インストールされた LSP サーバーを自動的に設定します。
-- 個別のLSPサーバーの設定は lspconfig を通して行います。
local lspconfig = require('lspconfig')

-- lua_ls の設定例 (もし必要なら)
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    Lua = {
      workspace = {
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- marksman の設定
lspconfig.marksman.setup({
  capabilities = capabilities,
})

lspconfig.terraformls.setup({})

-- LSP設定後に追加 (cmpの設定)
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  })
})

