local options = {
  encoding = 'utf-8',
  fileencoding = 'utf-8',
  title = true,
  backup = false,
  showcmd = true,
  -- cmdheight = 0 は隙間を無くせるが、nvim-tree等で不具合が発生するため採用しない。
  -- 1行 分のコマンドライン領域はNeovimの機能として必要なスペースである。
  cmdheight = 1,
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
  -- visualize space and tabs
  list = true,
  listchars = "eol:$,tab:>.,trail:-",
  -- menuone:対象が1件しかなくても常に補完ウィンドウを表示
  -- noinsert:補完ウィンドウを表示時に挿入しない
  completeopt = 'menu,menuone,noinsert,noselect',
  -- 外部ファイルで編集されたら自動的に読み込む(claudecodeなどで編集された場合を想定)
  autoread = true,
  -- 確認を有効化(外部更新とローカル編集が衝突した場合)
  confirm = true,
  -- nvim 12からのオプション
  -- pumborder = true,
  -- vimのtemirnalにおいて、zshのbind機能を入力できるようにtimeoutを設定
  -- 他のvimの機能には影響なし
  ttimeout = true,
  ttimeoutlen = 10,
  -- set mac dictonary
  dictionary = "/usr/share/dict/words",
  -- 補完候補のソースを指定
  -- デフォルト(.,w,b,u,t,i)に加えて、kで辞書ファイルを参照
  complete = ".,w,b,u,t,i,k",
  -- --------------------
  -- folding
  -- --------------------
  -- 折りたたみの制御を、式評価モード'expr'に設定
  -- manualやindentではなく、計算された結果を利用する
  foldmethod = "expr",
  -- 折りたたみの計算ロジックに、treesitterを利用
  -- 関数のブロックなど、コードの構造に基づいた正確な折りたたみを可能とする。
  foldexpr = "v:lua.vim.treesitter.foldexpr()",
  -- ファイルを開いた際には、全て展開した状態とする
  foldlevel = 99,
  foldlevelstart = 99,
  -- 折りたたみ状態を表す列を表示する
  -- 一旦表示を無しにする
  --foldcolumn = "1",
  foldtext = "",
  -- 微小だが有効signsの有無でカラムの表示/非表示が切り替わるとレイアウトシフトが発生し再描画が走る。
  -- "yes"で固定すればそのコストがなくなる。gitsignsやLSP
  -- diagnosticsを使っている現在の構成では合理的。
  signcolumn = "yes",
}

-- active all options
for k, v in pairs(options) do
  vim.opt[k] = v
end

-- 全体: 全モードでカーソル点滅を無効化
-- 詳細: neovim内蔵ターミナル（snacks.terminal含む）でGhosttyと同様にカーソル点滅を無効化
-- 背景: guicursorのデフォルト値にはターミナルモードで点滅が有効な設定が含まれているため上書き
vim.opt.guicursor:append("a:blinkon0")
-- vim上で起動したterminalにおいてもzshを読み込ませるために設定
vim.o.shell = "zsh -l"

-- netrwを表示しない
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- line number at terminal buffer
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.relativenumber = true
  end,
})

-- osがdark modeかどうかを判定する
local function is_os_dark_mode()
  local handle = io.popen(
    'osascript -e \'tell application "System Events" to tell appearance preferences to return dark mode\'')
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("true") ~= nil
  end
  -- default is dark mode
  return true
end

vim.defer_fn(function ()
  local lazygit_theme_file = is_os_dark_mode()
    and vim.fn.expand("$HOME/Library/Application Support/lazygit/theme_dark.yml")
    or vim.fn.expand("$HOME/Library/Application Support/lazygit/theme_light.yml")
  local lazygit_config_file = vim.fn.expand("$HOME/Library/Application Support/lazygit/config.yml")
  vim.g.lazygit_use_custom_config_file_path = 1 -- config file path is evaluated if this value is 1
  vim.g.lazygit_config_file_path = { lazygit_theme_file, lazygit_config_file }
  vim.g.lazygit_floating_window_scaling_factor = 1 -- scaling factor for floating window
end, 0)

-- claudecodeなどで編集された場合に備えて、編集をチェックする
-- フォーカスを戻した時やバッファ切り替え時に更新チェック
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  command = "silent! checktime",
})

-- 読込完了メッセージ（CUIだとコマンドラインに表示されるだけ）
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function()
    vim.notify("Reloaded: " .. vim.fn.expand("<afile>"))
  end,
})

--開いたbufferをトリガーにして、treesitterを有効化する
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
  callback = function(ctx)
    -- 必要に応じて`ctx.match`に入っているファイルタイプの値に応じて挙動を制御
    -- `pcall`でエラーを無視することでパーサーやクエリがあるかどうかを気にしなくて済む
    pcall(vim.treesitter.start)
  end,
})

-- 全体: markdown固有の表示設定
-- 詳細: nvim-markdownプラグインの設定を上書きし、markdown編集時の表示を調整
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- コードブロックの```を表示するため、conceallevelを1に設定
    -- 0に設定するとobsidianからwarningが出るため1に設定
    vim.opt_local.conceallevel = 1
    -- 全体: markdownファイルは見出し単位で折りたたんだ状態で開く
    -- 詳細: 長いドキュメントの全体構造を把握しやすくする。展開はzRで可能
    vim.opt_local.foldlevel = 0
  end,
})
