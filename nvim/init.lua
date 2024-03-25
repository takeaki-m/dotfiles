require("options")
require("keymaps")

-- colorscheme settings
vim.cmd 'set background=dark'
-- vim.cmd 'colorscheme default'
vim.cmd 'colorscheme koehler'


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
  'folke/tokyonight.nvim';

  -- My plugins here
  -- 'foo1/bar1.nvim';
  -- 'foo2/bar2.nvim';
}

