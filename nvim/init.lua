require("options")
require("keymaps")

-- colorscheme settings
vim.cmd 'set background=dark'
vim.cmd 'colorscheme lunaperche'



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
  -- colortheme
  'rose-pine/neovim';
  'craftzdog/solarized-osaka.nvim';
}
-- activate indent-blankline.nvim
require('ibl').setup()
