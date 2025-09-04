local opts = {
  noremap = true,
  silent = true,
}

local keymap = vim.keymap.set

-- use space as Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Save file with space + w
keymap('n', '<Leader>w', ':w<CR>', opts)

--Esc
keymap('i', 'jj', '<ESC>', { silent = true })
--keymap('i', '<C-j>', '<ESC>', { silent = true })
keymap('i', 'っj', '<ESC>', { silent = true })

-- copy buffer all pages
keymap('n', '<Leader>y', ':%y<CR>', opts)
-- increment and decrement
keymap('n', '+', '<C-a>', opts)
keymap('n', '-', '<C-x>', opts)

-- hilight off in two ESC times
keymap('n', '<Esc><Esc>', ':nohlsearch<CR>', opts)
keymap('n', '<C-j>', ':bnext<CR>', opts)
keymap('n', '<C-k>', ':bprev<CR>', opts)

-- telescope
-- telescope find files
keymap('n', '<Leader>ff', ':Telescope find_files<CR>', opts)
-- telescope find character
keymap('n', '<Leader>fg', ':Telescope live_grep<CR>', opts)
-- telescope find buffers
keymap('n', '<Leader>fb', ':Telescope buffers<CR>', opts)

-- telescope find buffers
keymap('n', '<Leader>fb', ':Telescope buffers<CR>', opts)
-- telescope select registers
keymap('n', '<Leader>fr', ':Telescope registers<CR>', opts)

-- fern keybinding
keymap('n', '<Leader>ft', ':Fern . -reveal=% -drawer -toggle -width=30<CR>', opts)

-- <C-n> のキーマッピング
vim.keymap.set('n', '<C-n>', function()
  -- 1. 現在のファイルのフルパスを変数に保存しておく
  --    vim.fn.expand('%') はカレントバッファのファイル名を取得する関数
  local current_file_path = vim.fn.expand('%:p')

  -- 2. 'fern' のfiletypeを持つウィンドウを探す
  local fern_win_id = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'fern' then
      fern_win_id = win
      break
    end
  end

  if fern_win_id then
    -- 3. Fernウィンドウが見つかった場合の処理
    --    a. 既存のFernウィンドウにフォーカスを移動する
    vim.api.nvim_set_current_win(fern_win_id)

    --    b. 保存しておいたパスを使ってrevealを実行する
    --       vim.fn.fnameescape() はパス中の特殊文字をエスケープするのに役立つ
    --       この時点ではカレントウィンドウがFernなので、'%'は使えない。
    if current_file_path ~= '' then
      vim.cmd('Fern . -reveal=' .. vim.fn.fnameescape(current_file_path))
    end
  else
    -- 4. Fernウィンドウが見つからなかった場合の処理
    --    新しくDrawerとして開く（このときは'%'が使える）
    vim.cmd('Fern . -reveal=% -drawer -toggle -width=30')
  end
end, opts)

-- buffer
--keymap ('n', '<C-b>', ':ls<CR>:buf', opts)
--keymap ('n', '<Leader>b', ':b<Space>', opts)

-- 補完表示時のEnterで改行をしない
keymap('i', '<CR>', 'pumvisible() ? "<C-y>" : "<CR>"', { expr = true, noremap = true })

-- 補完表示時の<C-n>と<C-p>の挙動を設定
keymap('i', '<C-n>', 'pumvisible() ? "<Down>" : "<C-n>"', { expr = true, noremap = true })
keymap('i', '<C-p>', 'pumvisible() ? "<Up>" : "<C-p>"', { expr = true, noremap = true })

---- indent
keymap('n', '<C-l>', '>>', opts)
keymap('n', '<C-h>', '<<', opts)
keymap('v', '<C-l>', '>gv', opts)
keymap('v', '<C-h>', '<gv', opts)
--keymap('i', '<C-l>', '<C-o>>>', opts) -- 挿入モードからノーマルモードに戻る
--keymap('i', '<C-h>', '<C-o><<', opts) -- 挿入モードからノーマルモードに戻る

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
keymap("t", "<C-g>", "<C-\\><C-n>", opts)

keymap('n', '<Leader>lg', ':LazyGit<CR>', opts)
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
keymap('x', 'p', '"_dP', { noremap = true })

function PasteCommandOutput(command)
  local output = vim.fn.system(command)
  output = output:gsub("[\r\n]+", "") -- 改行を削除する
  output = output:gsub("%z", "")      -- NUL文字を削除する
  vim.api.nvim_put({ output }, '', true, true)
end

keymap('n', '<Leader>rp', ':lua PasteCommandOutput("readlink -f " .. vim.fn.expand("%"))<CR>',
  { noremap = true, silent = true })

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
