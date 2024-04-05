require("options")
require("keymaps")
-- to use indent-blankline
-- require("ibl").setup()

-- colorscheme settings
vim.cmd 'set background=dark'
vim.cmd 'colorscheme lunaperche'



-- activate vim loader to use plugin manager
vim.loader.enable()


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

local cmd = require('pckr.loader.cmd')
local keys = require('pckr.loader.keys')

require('pckr').add{
  'nvim-treesitter/nvim-treesitter';
  'nvim-lua/plenary.nvim';
  'BurntSushi/ripgrep';
  'sharkdp/fd';
  'nvim-telescope/telescope.nvim';
  'lukas-reineke/indent-blankline.nvim';
  'lambdalisue/fern.vim'
  -- My plugins here
  -- 'foo1/bar1.nvim';
  -- 'foo2/bar2.nvim';
}

