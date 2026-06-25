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
  -- 折り返しで継続した行の行頭に表示するマーカー。折り返し箇所を視認しやすくする
  -- (wrap=true の実ファイルでの単語境界折り返し・インデント揃えは BufWinEnter の autocmd 側で設定)
  showbreak = "↪ ",
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
  splitbelow = true, -- 新しいウィンドウを下に開き、フォーカスを移動する
  splitright = true, -- 新しいウィンドウを右に開き、フォーカスを移動する
  -- 微小だが有効signsの有無でカラムの表示/非表示が切り替わるとレイアウトシフトが発生し再描画が走る。
  -- "yes"で固定すればそのコストがなくなる。gitsignsやLSP
  -- diagnosticsを使っている現在の構成では合理的。
  signcolumn = "yes",
  guicursor = table.concat({
    "n-v-c:block",     -- Normal/Visual/Command-line normal
    "i-ci-ve:ver25",   -- Insert系
    "r-cr:hor20",      -- Replace系
    "o:hor50",         -- Operator-pending
    "t:block-TermCursor", -- Terminal-Job mode（Claude Code等のterminal内入力）。
                       --   snacks含むnvim内蔵terminalのカーソルはこのt:設定が優先される。
                       --   ver25(細い縦棒)だと入力位置を見失いやすいため、塗り面積が最大の
                       --   blockにして視認性を確保する。
                       --   さらに <C-/> で抜けたNormalモードもblockで形が同じになるため、
                       --   入力可能状態のカーソルだけ専用ハイライト TermCursor(後述)で色分けする。
  }, ","),
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

-- LazyGitのテーマ設定をOSのダーク/ライトモードに応じて更新する
-- LazyGit起動前に毎回呼び出すことで、Nvim起動後のテーマ変更にも対応する
function _G.refresh_lazygit_theme()
  local lazygit_theme_file = is_os_dark_mode()
    and vim.fn.expand("$HOME/Library/Application Support/lazygit/theme_dark.yml")
    or vim.fn.expand("$HOME/Library/Application Support/lazygit/theme_light.yml")
  local lazygit_config_file = vim.fn.expand("$HOME/Library/Application Support/lazygit/config.yml")
  vim.g.lazygit_config_file_path = { lazygit_theme_file, lazygit_config_file }
end

-- 起動直後のLazyGit用に初期値を設定する
vim.defer_fn(function ()
  vim.g.lazygit_use_custom_config_file_path = 1 -- config file path is evaluated if this value is 1
  vim.g.lazygit_floating_window_scaling_factor = 1 -- scaling factor for floating window
  _G.refresh_lazygit_theme()
end, 0)

-- 全体: アクティブなwindowのみcursorlineを表示してフォーカス位置を強調する
-- 詳細: WinEnter/WinLeaveでwindow-localに切り替える、Vim伝統の鉄板パターン
-- 背景: 全window常時ONだと「今いるwindow」が判別しづらいため、active側だけに出す
local cursorline_group = vim.api.nvim_create_augroup("CursorLineOnActiveWin", {})
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = cursorline_group,
  callback = function() vim.opt_local.cursorline = true end,
})
vim.api.nvim_create_autocmd("WinLeave", {
  group = cursorline_group,
  callback = function() vim.opt_local.cursorline = false end,
})

-- 全体: 実ファイルを開いたウィンドウで折り返し(wrap)を必ず有効化する
-- 背景:
--   wrap は window-local 設定。nvim-tree は自分のツリーウィンドウへ window-local の
--   nowrap を適用しており(nvim-tree の view-state.lua: wrap=false)、そこから
--   ファイルを開くと、ファイル側ウィンドウが nowrap を引き継ぎ折り返されなくなる。
--   options の wrap=true はグローバル既定なので、汚染されたウィンドウでは効かない。
-- 詳細:
--   - BufWinEnter(バッファがウィンドウに表示される契機)で、対象ウィンドウに
--     wrap を opt_local で再適用し、汚染を打ち消す。
--   - linebreak/breakindent も併せて設定し、単語境界での折り返し・インデント揃えにする。
--   - 対象は buftype=="" の実ファイルのみ。nofile(nvim-tree等のUI)・terminal・
--     help・quickfix は除外し、それらの nowrap を尊重する。
--   - diff モード(:diffthis 等)は折り返さない方が比較しやすいため除外する。
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    if vim.bo.buftype == "" and not vim.wo.diff then
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true   -- 単語境界(スペース等)で折り返す
      vim.opt_local.breakindent = true -- 折り返し行を元行のインデントに揃える
    end
  end,
})

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

-- 全体: 全角スペース(U+3000)を可視化する
-- 背景:
--   listchars のキー(eol/tab/trail/space/nbsp 等)は全角スペースを対象に取らない。
--   全角スペースは文字カテゴリ上「通常文字」扱いのため、listchars の空白系キーでは捕捉できないため。
--   そこで matchadd() で正規表現マッチに対してハイライトを付与する。
-- 詳細:
--   matchadd() は window-local な仕組みのため、新しい window を開くたびに登録する必要がある。
--   重複登録を避けるため、登録IDを window-local 変数(vim.w)に保持してガードする。
-- 表示形式の選択:
--   背景色塗り(濃い赤)を採用。出現頻度が低いノイズ系の記号は「出たときに即気付ける」表示が合理的。
--   $/>./- は頻出のため控えめな記号にしているが、全角スペースは性格が異なる。
vim.api.nvim_set_hl(0, "ZenkakuSpace", { bg = "#7C2D2D" })

-- 全体: terminal入力可能状態(Terminal-Jobモード)のカーソルを緑ブロックで色分けする。
--   terminalバッファでは <C-/> で抜けたNormalモードもblockのため、入力可能な
--   Terminal-Jobモードと形が同じで見分けにくい。形は両方blockのまま、入力可能状態の
--   カーソル色だけ緑に変えて「カーソルが緑＝今キー入力がClaude Codeに届く」と判別できるようにする。
-- 詳細:
--   blockカーソルでは bg が塗り色、fg がその上に重なる文字色。緑bgでも文字が読めるよう
--   暗い fg を置く。Terminal-Jobモードのカーソルは TermCursor ハイライトを使う(guicursorの
--   t:block-TermCursor で明示)。一方 Normalモードは通常の Cursor ハイライトを使うため影響しない。
--   colorscheme 適用時に TermCursor が再リンクされ色が戻るため、ColorScheme契機でも再適用する。
local function set_term_cursor_hl()
  vim.api.nvim_set_hl(0, "TermCursor", { bg = "#2ea043", fg = "#1e1e1e" })
end
set_term_cursor_hl()
vim.api.nvim_create_autocmd("ColorScheme", { pattern = "*", callback = set_term_cursor_hl })

local zenkaku_group = vim.api.nvim_create_augroup("ZenkakuSpaceHighlight", {})
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "VimEnter" }, {
  group = zenkaku_group,
  callback = function()
    if vim.w.zenkaku_match_id == nil then
      vim.w.zenkaku_match_id = vim.fn.matchadd("ZenkakuSpace", "　")
    end
  end,
})

-- 全体: markdown固有の表示設定
-- 詳細: nvim-markdownプラグインの設定を上書きし、markdown編集時の表示を調整
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- 全体: render-markdown.nvim が conceal 対象(チェックボックスや記号等)を
    --       「完全に隠してアイコンに置き換える」前提で描画するため、
    --       conceallevel は 2 を設定する
    -- 詳細: 1だと conceal 対象が 1文字スペースに潰れ、render-markdown が重ねる
    --       アイコンとテキストの位置がずれて先頭文字が欠ける。
    --       2 にすると conceal 対象が完全に隠れて位置ずれが解消する。
    --       (obsidian の UI 描画は init.lua 側で無効化済みのため warning も出ない)
    vim.opt_local.conceallevel = 2
    -- 全体: markdownファイルは見出し単位で折りたたんだ状態で開く
    -- 詳細: 長いドキュメントの全体構造を把握しやすくする。展開はzRで可能
    vim.opt_local.foldlevel = 0
  end,
})
