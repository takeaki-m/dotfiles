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
-- Ctrl系キーはIMEをバイパスするため、日本語入力中でも確実にESCできる
keymap('i', '<C-j>', '<Cmd>stopinsert<CR>', { silent = true, desc = "Escape" })

-- Claude Code の terminal バッファでのみ jj→ESCバイト送信
-- 全体構成: terminal mode のキーマップは子プロセスへの入力を変換する。
--           nvim 自身の insert mode `jj`→ESC と感覚を揃えて、Claude Code の
--           vim mode で normal mode に戻りやすくする。
-- 詳細    : <C-j>(=LF=改行) は ASCII規格上Claude Code側で必ず改行になるため代替が必要。
--           適用対象を bufname が `term://...claude` で終わるバッファに限定する。
--           snacks_terminal の filetype だけで絞ると <C-\> のトグルターミナル(shell)も
--           巻き込むため、claude を起動したバッファ名で更に絞り込む (claude.lua の
--           is_claude_code_buffer と同じ判定基準)。これで lazygit・トグルターミナル・
--           通常 shell での `jj` 操作には影響しない。
--           shell経由で claude を起動するケース (bufname末尾が /bin/zsh) は識別
--           不可能なため対象外 (利用頻度が低いため許容)。
-- Claude CodeのESCキーも発行されてしまい、意図せずClaude Codeを停止してしまうためコメントアウトする
-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = 'snacks_terminal',
--   callback = function(args)
--     -- bufname は端末ジョブ起動時に確定するが、FileType 発火時点で未確定な場合に
--     -- 備えて schedule で 1 tick 遅延させてから判定する
--     vim.schedule(function()
--       if not vim.api.nvim_buf_is_valid(args.buf) then
--         return
--       end
--       local name = vim.api.nvim_buf_get_name(args.buf)
--       if name:match('^term://.*claude$') then
--         vim.keymap.set('t', 'jj', '<Esc>', {
--           buffer = args.buf,
--           silent = true,
--           desc = "Send ESC to Claude Code (vim mode)",
--         })
--       end
--     end)
--   end,
-- })

-- copy buffer all pages
keymap('n', '<Leader>y', ':%y<CR>', with_desc("Yank entire buffer"))
-- 文字数・単語数・行数のカウント
-- 全体: 標準の `g<C-g>` を押しやすい leader 系キーに割り当て直したもの
-- 詳細: normal はバッファ全体、visual は選択範囲を集計して表示する。
--       remap=true にして標準の g<C-g> へ委譲するため、自前で集計は実装していない。
--       <Leader>w は保存に使っており、<Leader>wc だと保存が timeoutlen 分遅延するため <Leader>cw とした。
keymap({ 'n', 'x' }, '<Leader>cw', 'g<C-g>', { remap = true, silent = false, desc = "Count words/chars (g<C-g>)" })
-- increment and decrement
keymap('n', '+', '<C-a>', with_desc("Increment number"))
keymap('n', '-', '<C-x>', with_desc("Decrement number"))

-- hilight off in two ESC times
keymap('n', '<Esc><Esc>', ':nohlsearch<CR>', with_desc("Clear search highlight"))
-- terminalのescと重複して操作が不便になるためコメントアウトする
-- keymap('n', '<C-j>', ':bnext<CR>', with_desc("Next buffer"))
-- keymap('n', '<C-k>', ':bprev<CR>', with_desc("Previous buffer"))

keymap('n', 'g:', 'g;', with_desc("Go to older change"))

-- 全体: 折り返された行を「表示行」単位で上下移動できるようにする
-- 背景: wrap 有効時、既定の j/k は「論理行」単位で動き、折り返された行内を
--       1ステップで飛び越える。長文(折り返し前提のテキスト)では行内移動がしづらい。
-- 詳細: ただし j/k を単純に gj/gk へ置換すると、relativenumber を使った
--       カウント付き相対ジャンプ(例: 5j)まで表示行基準になり壊れる。
--       そこで count が無い素の j/k のときだけ gj/gk にする expr マッピングとし、
--       5j 等の論理行ジャンプは従来どおり維持する。
--keymap({ 'n', 'x' }, 'j', function() return vim.v.count == 0 and 'gj' or 'j' end,
--  { expr = true, silent = true, desc = "Down by display line (no count)" })
--keymap({ 'n', 'x' }, 'k', function() return vim.v.count == 0 and 'gk' or 'k' end,
--  { expr = true, silent = true, desc = "Up by display line (no count)" })

-- terminal
keymap('n', '<Leader>ter', ':vert botright term<CR>', with_desc("Open terminal (vertical)"))
keymap('n', '<Leader>ster', ':bo term<CR>', with_desc("Open terminal (horizontal)"))

-- telescope
keymap('n', '<Leader>ff', ':Telescope find_files<CR>', with_desc("Find files"))
keymap('n', '<Leader>fg', ':Telescope live_grep<CR>', with_desc("Live grep"))
keymap('n', '<Leader>fb', ':Telescope buffers<CR>', with_desc("Find buffers"))
keymap('n', '<Leader>b', ':Telescope buffers<CR>', with_desc("Find buffers"))
keymap('n', '<Leader>fr', ':Telescope registers<CR>', with_desc("Select registers"))
keymap('n', '<Leader>fs', ':Telescope lsp_document_symbols<CR>', with_desc("Find document symbols"))
-- aerial outline を telescope で検索。markdown の見出しを階層インデント付き・ファイル出現順で表示するため、
-- レベルが見えずソート順が逆になる lsp_document_symbols の代替として使う
-- sorting_strategy=ascending を明示する理由:
--   aerial拡張は telescope のデフォルト(descending)時に結果を反転してファイル順に揃えるが、
--   シンボル0件のファイルだと default_selection_index が 0 となり nvim_win_set_cursor が
--   "Invalid cursor line: out of range" で失敗する。ascending を渡すと反転処理を回避でき、
--   0件でもエラーにならず、かつ ascending 自体がファイル出現順(上→下)表示になる。
keymap('n', '<Leader>fa', ':Telescope aerial sorting_strategy=ascending<CR>', with_desc("Find outline (aerial)"))

-- []系ナビゲーションの入力コスト対策(leader をブラケットのプレフィックスに再マップ)
-- 全体構成:
--   Vim の [ ] は「前/次の◯◯へ移動」の一貫した名前空間(標準の [b/]b, [q/]q, [d/]d,
--   組み込みモーション [{/]}/[z, treesitter の [f/]f 等)を持つが、Corne ではレイヤー
--   操作でコストが高い。そこで leader(=Space, サムキー)を [ / ] に展開し、
--   Space→j/k→suffix で名前空間全体を打てるようにする。
-- 設計判断(なぜ leader なのか):
--   他の押しやすいプレフィックスは全て塞がっている。C-n/C-p は macOS/Emacs 流の
--   readline と衝突、; は Karabiner で : に入替済み、,f/t/F/T は flash.nvim が使用中、
--   他の記号は Corne でどのみちレイヤー上。leader 直後の名前空間だけが空いている。
-- 仕組み(remap=true が肝):
--   noremap ではなく remap=true にすることで、展開後の [ / ] が「組み込みモーション」や
--   「既存の [f/]f 等のマップ」へ再委譲される。これにより 2 行で名前空間全体が有効になる。
-- キー割当:
--   <Leader>j = ](next), <Leader>k = [(prev)。既存の <C-j>=次hunk / <C-k>=前hunk と
--   同じ「j=下=次 / k=上=前」イディオムに揃え、学習コストを最小化する。
-- 使用例: Space j b=]b(次buffer), Space k d=[d(前診断), Space j f=]f(次関数), Space k {=[{
vim.keymap.set('n', '<Leader>j', ']', { remap = true, desc = "] prefix (next ...)" })
vim.keymap.set('n', '<Leader>k', '[', { remap = true, desc = "[ prefix (prev ...)" })

-- aerial サイドバー(常時表示のアウトラインツリー)
-- 全体設計: <Leader>fa の telescope 検索が「単発でシンボルへ飛ぶ」用途なのに対し、
--   こちらは画面横にツリーを常駐させ、レビュー中に「今どの関数/クラスの中か」を
--   カーソル追従で把握し続けるための用途。両者は補完関係にあり使い分ける。
-- 詳細:
--   - <Leader>ao: サイドバーの開閉(AerialToggle)
--   - <Leader>an: 現在位置周辺だけを表示するフローティングナビ(AerialNavToggle)
keymap('n', '<Leader>ao', ':AerialToggle<CR>', with_desc("Toggle outline (aerial)"))
keymap('n', '<Leader>an', ':AerialNavToggle<CR>', with_desc("Outline nav (aerial)"))

-- 旧 <C-n>。<C-n>/<C-p> は CodeDiff のファイル送りに使うため移した
-- (CodeDiff のタブで codediff の割り当てが無いバッファに当たると NvimTree が開閉され、
--  そのバッファが削除イベント無しで消えて treesitter 折りたたみのエラーの原因になった)
keymap('n', '<Leader>nn', ':NvimTreeFindFileToggle<CR>', with_desc("Toggle NvimTree"))
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
keymap('n', '<Leader>oy', ":Obsidian yesterday<CR>", with_desc('Open Obsidian yesterday'))
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
-- C-/でターミナルモード脱出
-- 端末によってはC-/が C-_ (0x1F) として送信されるため両方マップ
-- C-jは入れ子Neovim(lazygit内の編集等)のinsert mode ESCと競合するため使用不可
keymap("t", "<C-/>", "<C-\\><C-n>", with_desc("Exit terminal mode"))
keymap("t", "<C-_>", "<C-\\><C-n>", with_desc("Exit terminal mode (C-/ fallback)"))

-- LazyGit起動前にOSテーマを再検出し、テーマ設定を更新してから起動する
-- options.luaで定義したグローバル関数を参照
---@diagnostic disable-next-line: undefined-field
local refresh_lazygit_theme = _G.refresh_lazygit_theme
-- `<Leader>g*` プレフィックスをfugitiveに譲るため、LazyGitBufは`<Leader>lb`に移動
-- `<Leader>lg` (LazyGit floating) との対称性 (l=lazygit, b=buffer / g=floating) も担保
keymap('n', '<Leader>lb', function() refresh_lazygit_theme(); vim.cmd('LazyGitBuf') end, with_desc("Open LazyGit buffer"))
keymap('n', '<Leader>lg', function() refresh_lazygit_theme(); vim.cmd('LazyGit') end, with_desc("Open LazyGit"))
-- fugitive: `:Git` status バッファを開く。以後はバッファ内のデフォルトキー (s, u, =, cc) で操作
keymap('n', '<Leader>gs', ':Git<CR>', with_desc("Open Git status (fugitive)"))
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

-- vim.pack には「未使用 plugin の一括削除」がないため自前で用意する。
-- 設定から外れた plugin は active=false になるので、それを対象に削除する。
-- ただし遅延ロード群(pack_lazy)は未発火だと active=false のままなため、
-- 登録済みのものは「設定で宣言済み」として除外する(除外しないと telescope 等が毎回再インストールされる)。
vim.api.nvim_create_user_command('PackClean', function()
  local lazy = require('pack_lazy')
  local names = vim.iter(vim.pack.get())
    :filter(function(p) return not p.active and not lazy.is_registered(p.spec.name) end)
    :map(function(p) return p.spec.name end)
    :totable()
  if #names == 0 then
    vim.notify('削除対象の plugin はありません')
    return
  end
  vim.pack.del(names)
end, {})
-- Octo
-- keymaps
-- GitHub操作を機能別に短縮（i=issue, p=PR, d=discussion, n=notification, G=GitHub）
-- G を大文字にするのは、小文字の <leader>g をローカル git(fugitive)用に空けておくため。
-- (以前は <leader>gs が fugitive の :Git と重複し、後から定義したこちらが上書きしていた)
vim.keymap.set("n", "<leader>il", "<CMD>Octo issue list<CR>", { desc = "List GitHub Issues" })
vim.keymap.set("n", "<leader>ic", "<CMD>Octo issue create<CR>", { desc = "Create GitHub Issue" })
vim.keymap.set("n", "<leader>pl", "<CMD>Octo pr list<CR>", { desc = "List GitHub PullRequests" })
vim.keymap.set("n", "<leader>dl", "<CMD>Octo discussion list<CR>", { desc = "List GitHub Discussions" })
vim.keymap.set("n", "<leader>nl", "<CMD>Octo notification list<CR>", { desc = "List GitHub Notifications" })
-- Octo は :Octo 実行時に遅延ロードする(init.lua の lazy.on_cmd)。キーマップから octo.* を
-- 直接 require すると、:Octo を一度も実行していない状態では module not found になる。
-- そのため呼ぶ前に pack_lazy.load で読み込む(<leader>hl の telescope と同じ方式。読み込み済みなら何もしない)
vim.keymap.set("n", "<leader>Gs", function()
  require("pack_lazy").load("octo.nvim")
  require("octo.utils").create_base_search_command({ include_current_repo = true })
end, { desc = "Search GitHub" })
-- 「今の作業コンテキスト(カレントブランチ/cwd)から issue・PR を番号入力なしで開く」機能。
--   全体構成: <leader>pp = ブランチに紐づく PR を Octo で開く
--             <leader>ii = ブランチ名/cwd 名から Issue 番号を推定して Octo で開く
--             <leader>Gd = gh-dash(俯瞰用 TUI)を terminal タブで開く
--   背景: Octo の pr/issue edit は番号が必須で、毎回調べて入力するのが手間だったため。
--         gh は git remote とブランチから対象を自動解決できるので、番号は人が入力せず導出する。

-- 名前から Issue 番号を抽出する。claude/statusline.js の parseIssueNumber と同じ規則
-- (issue-123 / gh-123 / #123 / 123-foo / feature-1510-foo。app2 や v2.1 は誤検出しない)。
local function parse_issue_number(name)
  if not name or name == "" then
    return nil
  end
  local function try(pat)
    return name:match(pat)
  end
  -- Lua のパターンは alternation が無いため、区切り文字の有無を分けて順に試す
  for _, kw in ipairs({ "issues", "issue", "gh", "#" }) do
    local escaped = vim.pesc(kw)
    local n = try("^" .. escaped .. "[-_]?(%d+)$") or try("^" .. escaped .. "[-_]?(%d+)[_.%-]")
      or try("[_.%-]" .. escaped .. "[-_]?(%d+)$") or try("[_.%-]" .. escaped .. "[-_]?(%d+)[_.%-]")
    if n then
      return tonumber(n)
    end
  end
  -- 先頭の番号、または「英字の種別 + 区切り」に続く番号(例: 123-foo, feature-1510-foo)
  local n = name:match("^#?(%d+)$") or name:match("^#?(%d+)[_.%-]")
    or name:match("^%a+[-_]#?(%d+)$") or name:match("^%a+[-_]#?(%d+)[_.%-]")
  return n and tonumber(n) or nil
end

-- Octo は遅延ロードのため、:Octo をコマンド経由で実行して読み込みを発火させる
local function octo_open(kind, number)
  vim.cmd(("Octo %s edit %d"):format(kind, number))
end

vim.keymap.set("n", "<leader>pp", function()
  -- gh pr view はカレントブランチに紐づく PR を解決する(無ければ非0終了)
  vim.system({ "gh", "pr", "view", "--json", "number", "-q", ".number" }, { text = true }, function(res)
    vim.schedule(function()
      local number = tonumber(vim.trim(res.stdout or ""))
      if res.code ~= 0 or not number then
        vim.notify("このブランチに紐づく PR がありません", vim.log.levels.WARN)
        return
      end
      octo_open("pr", number)
    end)
  end)
end, { desc = "Open PR for current branch (Octo)" })

vim.keymap.set("n", "<leader>ii", function()
  -- ブランチ名(末尾セグメント) → ブランチ全体 → cwd 名(worktree 名を想定) の順で番号を探す
  local branch = vim.trim(vim.fn.system({ "git", "branch", "--show-current" }))
  local candidates = { branch:match("[^/]+$"), branch, vim.fs.basename(vim.fn.getcwd()) }
  for _, name in ipairs(candidates) do
    local number = parse_issue_number(name)
    if number then
      octo_open("issue", number)
      return
    end
  end
  vim.notify("ブランチ名/ディレクトリ名から Issue 番号を推定できません", vim.log.levels.WARN)
end, { desc = "Open Issue inferred from branch/cwd (Octo)" })

-- gh-dash は git リポジトリ内で起動すると、そのリポジトリに自動で絞り込む(smartFilteringAtLaunch)。
-- nvim の terminal を新規タブで開き、終了(q)したらタブごと閉じる。
vim.keymap.set("n", "<leader>Gd", function()
  vim.cmd("tabnew")
  vim.fn.jobstart({ "gh", "dash" }, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(0) then
          vim.cmd("bwipeout!")
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end, { desc = "Open gh-dash (GitHub TUI)" })

-- カーソル下のissue/PRリンク・@user・リアクションのポップアップを即時表示する。
-- Octo標準の CursorHold ホバー(updatetime=4秒待ち)と同じ処理を手動で呼び出すもの。
-- on_cursor_hold は octoバッファ以外では早期returnするためグローバルマップでも安全。
-- octo バッファは Octo を読み込んだ後でしか存在しないので、未ロードなら何もせずに終える
-- (ホバーのためだけに Octo を読み込まない)
vim.keymap.set("n", "<leader>Gh", function()
  if not package.loaded["octo"] then
    return
  end
  require("octo").on_cursor_hold()
end, { desc = "Show GitHub link/user popup (Octo hover)" })
