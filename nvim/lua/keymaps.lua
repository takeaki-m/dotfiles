local opts = {
  noremap = true,
  silent = true,
}

-- which-key.nvim で説明を表示するためのヘルパー関数
-- 共通オプション(opts)に desc を追加したテーブルを返す
local function with_desc(desc)
  return vim.tbl_extend("force", opts, { desc = desc })
end

local keymap = vim.keymap.set

-- use space as Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Save file with space + w
keymap('n', '<Leader>w', ':w<CR>', with_desc("Save file"))

-- Esc
-- with_desc未使用: silent のみ必要で noremap は不要なため、opts と構造が異なる
keymap('i', 'jj', '<ESC>', { silent = true, desc = "Escape" })
--keymap('i', '<C-j>', '<ESC>', { silent = true })
keymap('i', 'っj', '<ESC>', { silent = true, desc = "Escape (Japanese)" })

-- copy buffer all pages
keymap('n', '<Leader>y', ':%y<CR>', with_desc("Yank entire buffer"))
-- increment and decrement
keymap('n', '+', '<C-a>', with_desc("Increment number"))
keymap('n', '-', '<C-x>', with_desc("Decrement number"))

-- hilight off in two ESC times
keymap('n', '<Esc><Esc>', ':nohlsearch<CR>', with_desc("Clear search highlight"))
keymap('n', '<C-j>', ':bnext<CR>', with_desc("Next buffer"))
keymap('n', '<C-k>', ':bprev<CR>', with_desc("Previous buffer"))

keymap('n', 'g:', 'g;', with_desc("Go to older change"))

-- terminal
keymap('n', '<Leader>ter', ':vert botright term<CR>', with_desc("Open terminal (vertical)"))
keymap('n', '<Leader>ster', ':bo term<CR>', with_desc("Open terminal (horizontal)"))

-- telescope
keymap('n', '<Leader>ff', ':Telescope find_files<CR>', with_desc("Find files"))
keymap('n', '<Leader>fg', ':Telescope live_grep<CR>', with_desc("Live grep"))
keymap('n', '<Leader>fb', ':Telescope buffers<CR>', with_desc("Find buffers"))
keymap('n', '<Leader>b', ':Telescope buffers<CR>', with_desc("Find buffers"))
keymap('n', '<Leader>fr', ':Telescope registers<CR>', with_desc("Select registers"))

keymap('n', '<C-n>', ':NvimTreeFindFileToggle<CR>', with_desc("Toggle NvimTree"))
keymap('n', '<Leader>nf', ':NvimTreeFindFile<CR>', with_desc("Find file in NvimTree"))
keymap('n', '<Leader>nt', ':NvimTreeFocus<CR>', with_desc("Focus to NvimTree"))

-- terminal
keymap('n', '<Leader>tv', ':vertical term<CR>', with_desc("Open Terminal Buffer verticacal"))
keymap('n', '<Leader>ts', ':horizontal term<CR>', with_desc("Open Terminal Buffer horizontal"))

-- 補完表示時のEnterで改行をしない
-- with_desc未使用: expr オプションが必要で opts と構造が異なる
keymap('i', '<CR>', 'pumvisible() ? "<C-y>" : "<CR>"', { expr = true, noremap = true, desc = "Confirm completion or Enter" })

-- 補完表示時の<C-n>と<C-p>の挙動を設定
-- with_desc未使用: expr オプションが必要で opts と構造が異なる
keymap('i', '<C-n>', 'pumvisible() ? "<Down>" : "<C-n>"', { expr = true, noremap = true, desc = "Next completion item" })
keymap('i', '<C-p>', 'pumvisible() ? "<Up>" : "<C-p>"', { expr = true, noremap = true, desc = "Previous completion item" })

---- indent
keymap('n', '<C-l>', '>>', with_desc("Indent line"))
keymap('n', '<C-h>', '<<', with_desc("Unindent line"))
keymap('v', '<C-l>', '>gv', with_desc("Indent selection"))
keymap('v', '<C-h>', '<gv', with_desc("Unindent selection"))

-- Claude Code の設定ファイルをフローティングウィンドウで開く
-- Snacks.win を利用して、どのプロジェクトからでも同じ設定ファイルに即座にアクセス可能
keymap('n', '<Leader>cs', function()
  Snacks.win({
    file = vim.fn.expand("~/.claude/settings.json"),
    width = 0.8,
    height = 0.8,
    border = "rounded",
    -- ウィンドウを閉じるためのキーマップ
    keys = {
      q = "close",
      ["<Esc>"] = "close",
    },
  })
end, { noremap = true, silent = true, desc = "Edit Claude settings" })

-- Snacksを利用してzoomin / zoomout
keymap('n', '<Leader>z', ":lua Snacks.zen.zoom()<CR>", with_desc("Toggle zoom"))

-- Obsidian
keymap('v', '<Leader>oo', ":'<,'>Obsidian link<CR>", with_desc('Create Obsidian link to exist note'))
keymap('v', '<Leader>on', ":'<,'>Obsidian link_new<CR>", with_desc('Create Obsidian link with create new note'))
keymap('n', '<Leader>ot', ":Obsidian today<CR>", with_desc('Open Obsidian today'))
-- =============================================================================
-- ビジュアルモードで選択したテキストを検索するキーマッピング
--
-- 通常、ノーマルモードの `*` や `#` はカーソル下の単語を検索しますが、
-- この設定により、ビジュアルモードで選択した任意の範囲のテキストを
-- 検索できるようになります。
--
-- ファイルパスなど `/` や `\` を含む文字列でも正しく検索できるように、
-- `escape()` 関数を使用して堅牢な実装にしています。
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 前方検索 (*): ビジュアルモードで選択したテキストを前方に検索します。
-- -----------------------------------------------------------------------------
vim.cmd([[
  " xnoremap: ビジュアルモード (v, V, <C-v>) での非再帰的なキーマッピングを定義します。
  " *: マッピング対象のキーです。
  " y: 現在選択しているテキストをヤンク (コピー) します。
  " /: 前方検索を開始します。
  " \V: "Very Nomagic" モード。正規表現の特殊文字のほとんどを無効にし、
  "     ヤンクしたテキストをリテラルな文字列として検索できるようにします。
  " <C-r>=: 式レジスタを呼び出します。Vim scriptの関数を実行し、その結果を挿入できます。
  " escape(@", '/\'):
  "   - @": デフォルトレジスタの内容 (先ほどヤンクしたテキスト) を指します。
  "   - escape(...): 第一引数の文字列に含まれる、第二引数の文字 (ここでは '/' と '\') を
  "                  バックスラッシュでエスケープします。これにより検索コマンドが壊れるのを防ぎます。
  " <CR>: 式の評価を完了し、エスケープされた文字列を検索プロンプトに挿入します。
  " <CR>: 検索を実行します。
  xnoremap * y/\V<C-r>=escape(@",'/\')<CR><CR>
]])

-- -----------------------------------------------------------------------------
-- 後方検索 (#): ビジュアルモードで選択したテキストを後方に検索します。
-- -----------------------------------------------------------------------------
vim.cmd([[
  " 上記の * のマッピングとほぼ同じですが、後方検索を行う点が異なります。
  " ?: 前方検索の `/` の代わりに、後方検索を開始します。
  xnoremap # y?\V<C-r>=escape(@",'/\')<CR><CR>
]])

-- うまく後かないからコメントアウトする
-- コマンドラインモードでc-n,c-pでも補完を有効にするために方向キーに割り当てる
--keymap('c', '<C-p>', '<Up>', opts)
--keymap('c', '<C-n>', '<Down>', opts)
keymap("t", "<C-]>", "<C-\\><C-n>", with_desc("Exit terminal mode"))

keymap('n', '<Leader>g', ':LazyGitBuf<CR>', with_desc("Open LazyGit"))
keymap('n', '<Leader>lg', ':LazyGit<CR>', with_desc("Open LazyGit"))
-- move to specified line with <CR> insted of G
-- keymap('n', '<CR>', 'G', opts)
-- move top of file with <BS> instead of gg
-- keymap('n', '<BS>', 'gg', opts)

--vim.cmd([[
--  augroup AddNewlineOnSave
--    autocmd!
--    autocmd BufWritePre * lua _G.add_new_line()
--  augroup END
--]])

-- vp doesn't replace paste buffer
-- with_desc未使用: silent が不要なため、opts と構造が異なる
keymap('x', 'p', '"_dP', { noremap = true, desc = "Paste without replacing register" })

function PasteCommandOutput(command)
  local output = vim.fn.system(command)
  output = output:gsub("[\r\n]+", "") -- 改行を削除する
  output = output:gsub("%z", "")      -- NUL文字を削除する
  vim.api.nvim_put({ output }, '', true, true)
end

keymap('n', '<Leader>rp', ':lua PasteCommandOutput("readlink -f " .. vim.fn.expand("%"))<CR>',
  with_desc("Paste absolute file path"))

keymap('n', '<Leader>tt', ':RunApps<CR>', with_desc("run frontend and backend apps"))
keymap('v', '<Leader>cc', ':CopySelectedRangeLines<CR>', with_desc(" copy selected line numbers in Visual mode"))
keymap('v', '<Leader>cb', ':CodeBlock<CR>', with_desc("Insert Codeblock mark at selected lines"))
-- コマンドラインwindowでの動作を設定する
--normal modeでも動作してしまい、telescopeの動作と被るためコメントアウト
--vim.api.nvim_create_autocmd("CmdwinEnter", {
--    callback = function()
--        local opts_cursol = { buffer = true, noremap = true }
--        keymap("n", "<C-p>", "<Up>", opts_cursol)
--        keymap("n", "<C-n>", "<Down>", opts_cursol)
--        keymap("n", "<C-b>", "<Left>", opts_cursol)
--        keymap("n", "<C-f>", "<Right>", opts_cursol)
--        keymap("n", "<C-a>", "<Home>", opts_cursol)  -- 行頭に移動
--        keymap("n", "<C-e>", "<End>", opts_cursol)   -- 行末に移動
--    end,
--})
-- 全体: nvim-markdownのTab fold機能を無効化し、代替キーで fold を実行する
-- 背景: Tab と Ctrl-i はターミナルレベルで同一バイト(0x09)のため区別できない
--       Tab に fold をマッピングすると Ctrl-i（ジャンプリスト前方移動）も奪われる
--       そのため、fold を別キーに移し、Tab/Ctrl-i をデフォルト動作（ジャンプリスト）に戻す
-- 仕組み: hasmapto('<Plug>Markdown_Fold') を真にして、プラグインの自動 <Tab> マッピングを抑止する
vim.cmd [[map <Plug> <Plug>Markdown_Fold]]
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "<Leader>mm", function()
      require("markdown").fold()
    end, { buffer = true, silent = true, desc = "Fold markdown heading" })
  end,
})

-- Octo
-- keymaps
-- GitHub操作を機能別に短縮（i=issue, p=PR, d=discussion, n=notification, g=GitHub）
vim.keymap.set("n", "<leader>il", "<CMD>Octo issue list<CR>", { desc = "List GitHub Issues" })
vim.keymap.set("n", "<leader>ic", "<CMD>Octo issue create<CR>", { desc = "Create GitHub Issue" })
vim.keymap.set("n", "<leader>pl", "<CMD>Octo pr list<CR>", { desc = "List GitHub PullRequests" })
vim.keymap.set("n", "<leader>dl", "<CMD>Octo discussion list<CR>", { desc = "List GitHub Discussions" })
vim.keymap.set("n", "<leader>nl", "<CMD>Octo notification list<CR>", { desc = "List GitHub Notifications" })
vim.keymap.set("n", "<leader>gs", function()
  require("octo.utils").create_base_search_command({ include_current_repo = true })
end, { desc = "Search GitHub" })
