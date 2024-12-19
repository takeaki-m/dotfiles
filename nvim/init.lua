require("options")
require("colorscheme")
require("command")
require("keymaps")
require("options")

--vim.cmd 'set background=dark'

-- activate vim loader to use plugin manager
vim.loader.enable()

--local cmd = require('pckr.loader.cmd')
--local keys = require('pckr.loader.keys')


-- activate pkcr vim
local function bootstrap_pckr()
  local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"

  if not vim.loop.fs_stat(pckr_path) then
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
  'BurntSushi/ripgrep';
  'sharkdp/fd';
  'nvim-telescope/telescope.nvim';
  'lukas-reineke/indent-blankline.nvim';
  'lambdalisue/fern.vim';
  'lewis6991/gitsigns.nvim';
  'nvim-lualine/lualine.nvim';
  'kdheepak/lazygit.nvim';
  'neovim/nvim-lsp';
  'neovim/nvim-lspconfig';
  'williamboman/mason.nvim';
  'williamboman/mason-lspconfig.nvim';
  'L3MON4D3/LuaSnip';
  'hrsh7th/nvim-cmp';
  'hrsh7th/cmp-nvim-lsp';
  'hrsh7th/cmp-buffer';
  'saadparwaiz1/cmp_luasnip';
  -- colortheme
  'rose-pine/neovim';
  'craftzdog/solarized-osaka.nvim';
}
-- activate indent-blankline.nvim
require('ibl').setup()
require('lualine').setup()
-- lsp
require("mason").setup()
require("mason-lspconfig").setup()
require("mason-lspconfig").setup_handlers {
  function(server_name)
    require("lspconfig")[server_name].setup {}
  end,
}
-- lspのハンドラーに設定
CAPABILITIES = require("cmp_nvim_lsp").default_capabilities()

-- lspの設定後に追加

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
