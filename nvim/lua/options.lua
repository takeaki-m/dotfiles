local options = {
  encoding = 'utf-8',
  fileencoding = 'utf-8',
  title = true,
  backup = false,
  showcmd = true,
  cmdheight = 2,
  laststatus = 2,
  helplang = 'ja',
  swapfile = false,
  wrap = true,
  -- show line number
  number = true,
  -- show relative line number
  relativenumber = true,
  smartindent = true,
  autoindent = true,
  -- tab with 2 half-width spaces
  expandtab = true,
  -- display width of tab character at the beginning of a line
  tabstop = 2,
  -- display width of tab character outside the beginning of a line
  shiftwidth = 2,
  cursorline = true,
  -- user clipboard
  clipboard = "unnamed",
  -- 途中から検索開始する
  incsearch = true,
  -- Search regardless of case if the search character is lowercase
  ignorecase = true,
  -- case sensitive if search characters are uppercase
  smartcase = true,
  -- hilight search words
  hlsearch = true,
  -- automatically go to next line
  whichwrap = "b,s,h,l,<,>,[,],~",
}

-- active all options
for k, v in pairs(options) do
  vim.opt[k] = v
end
