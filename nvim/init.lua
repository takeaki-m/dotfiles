-- activate vim loader to use plugin manager
-- set file top to enable module cachs
vim.loader.enable()
require("command")
require("options")
require("keymaps")
require("lsp")
require("claude")


-- =====================================================================
-- プラグイン管理: vim.pack (Neovim 0.12 組み込み)
-- =====================================================================
-- 全体構成:
--   1) 即時ロード群を vim.pack.add で一括登録する。配列順がそのまま plugin/ の
--      ロード順かつ依存順になる(mason→mason-lspconfig, treesitter→render-markdown 等)。
--   2) vim.pack には pckr の config フィールドが無いため、各 setup は add の後に手動で呼ぶ。
--   3) 遅延ロード群(telescope 等)は起動時には add せず、pack_lazy 経由で
--      cmd / ft / event 発火時に add+setup する。
--      背景: vim.pack は「起動時に add したプラグイン」は load=false であっても
--        起動末尾の load-plugins ステップで plugin/ を必ず source する。そのため
--        真の遅延読み込みには「起動時には add しない」必要がある(詳細は lua/pack_lazy.lua)。
--
-- 変更後の反映手順:
--   init.lua を編集後 :source % で再読込すれば良い。vim.pack.add は名前で冪等なため、
--   pckr 時代に必要だった __pckr_initialized ガードや bootstrap 処理は不要になった。
-- =====================================================================
local lazy = require("pack_lazy")

-- GitHub の "owner/repo" から vim.pack の spec を組み立てるヘルパ。
-- src の "https://github.com/" は全プラグイン共通のため、ここで一元化して重複を排除する。
-- 即時ロード群(vim.pack.add)と遅延ロード群(lazy.on_*)の両方で使う。
--- @param repo string "owner/repo" 形式
--- @param version? string 追従する branch/tag(任意。例: "main" / "harpoon2")
--- @return table vim.pack spec
local function gh(repo, version)
  return { src = "https://github.com/" .. repo, version = version }
end

-- ---------------------------------------------------------------------
-- 1) 即時ロード群(配列順 = plugin/ ロード順 = 依存順)
-- ---------------------------------------------------------------------
vim.pack.add({
  gh("folke/lazydev.nvim"),
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  -- nvim-treesitter / textobjects は main branch(フルリライト版)を使う
  gh("nvim-treesitter/nvim-treesitter", "main"),
  gh("nvim-treesitter/nvim-treesitter-textobjects", "main"),
  gh("folke/flash.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("nvim-lualine/lualine.nvim"),
  gh("kdheepak/lazygit.nvim"),
  gh("tpope/vim-fugitive"),
  gh("neovim/nvim-lspconfig"),
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  gh("L3MON4D3/LuaSnip"),
  gh("kylechui/nvim-surround"),
  gh("ixru/nvim-markdown"),
  gh("numToStr/Comment.nvim"),
  gh("lukas-reineke/indent-blankline.nvim"),
  gh("stevearc/aerial.nvim"),
  gh("folke/snacks.nvim"),
  gh("coder/claudecode.nvim"),
  -- harpoon は harpoon2 branch を使う(setup はファイル末尾でまとめて行う)
  gh("ThePrimeagen/harpoon", "harpoon2"),
  -- 補完(nvim-cmp 本体と各ソース。setup はファイル末尾の cmp.setup 周辺で行う)
  gh("hrsh7th/nvim-cmp"),
  gh("hrsh7th/cmp-nvim-lsp"),
  gh("hrsh7th/cmp-buffer"),
  gh("saadparwaiz1/cmp_luasnip"),
  gh("uga-rosa/cmp-dictionary"),
  -- render-markdown は treesitter の後にロードする(配列順で担保)
  gh("MeanderingProgrammer/render-markdown.nvim"),
})

-- nvim-treesitter(main): インストール/更新時にパーサーを最新化する
-- 背景: pckr の run=':TSUpdate' 相当。vim.pack では plugin の状態変化を通知する
--   PackChanged イベントで代替する(kind は install/update/delete)。
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" and (ev.data.kind == "install" or ev.data.kind == "update") then
      pcall(function()
        local ts = require("nvim-treesitter")
        if type(ts.update) == "function" then ts.update() end
      end)
    end
  end,
})

-- ---------------------------------------------------------------------
-- 2) 即時ロード群の setup(vim.pack には config フィールドが無いため手動で呼ぶ)
-- ---------------------------------------------------------------------

-- lazydev: luaのcompletionにnvimの設定を読み込ませる
-- luaのlsp server(lua_ls)が vim 関連の関数を認識できるよう、他より優先的に読み込む
require("lazydev").setup()

-- nvim-treesitter (main branch): フルリライト版
-- 全体構成: 旧master系のAPI(ensure_installed/auto_install/highlightモジュール等)は廃止され、
--   1) このプラグインは「パーサーと query の取得」だけを担当
--   2) ハイライト/折りたたみは Neovim ネイティブ (vim.treesitter.start / foldexpr) を使う(options.lua側)
--   3) パーサーは setup ではなく明示インストール (require('nvim-treesitter').install) で入れる
do
  -- 防御的記述: main 専用 API (install) が存在しないことがあるため pcall + 関数存在チェックで吸収する
  local ok, ts = pcall(require, "nvim-treesitter")
  if ok then
    if type(ts.setup) == "function" then ts.setup() end
    if type(ts.install) == "function" then
      -- 普段使うパーサーを明示インストール (既にインストール済みなら no-op、非同期)
      -- markdown / markdown_inline は render-markdown の injection 評価で必須
      ts.install({
        "lua", "vim", "vimdoc", "bash",
        "markdown", "markdown_inline",
        "json", "yaml", "toml", "regex",
        -- sql は PostgreSQL/MySQL 等の方言を含め1つのパーサーでカバーする
        "sql",
        -- 普段の開発言語。foldexpr(treesitter折りたたみ)と textobjects(af/if/aa/ia)も機能する
        "typescript", "tsx", "javascript", -- tsx は .tsx 用の別パーサー
        "terraform", "hcl",                -- .tf は terraform、.hcl は hcl
        "html", "css", "csv", "zsh",       -- zsh は専用パーサー(bash転用ではない)
        "python",
      })
    end
  end
end

-- nvim-treesitter-textobjects (main branch):
--   treesitterの構文木を利用してコード構造単位で選択・移動する
-- 全体構成:
--   1) setup() でグローバル挙動 (lookahead / set_jumps) のみ宣言
--   2) キーマップは vim.keymap.set で個別に書く(main branch の設計方針)
--   3) select_textobject / goto_* の第2引数 'textobjects' は queries/<lang>/textobjects.scm を指す
do
  require("nvim-treesitter-textobjects").setup({
    select = {
      lookahead = true, -- カーソル前方のオブジェクトも対象にする
    },
    move = {
      set_jumps = true, -- ジャンプリストに記録する
    },
  })

  local select = require("nvim-treesitter-textobjects.select")
  local move = require("nvim-treesitter-textobjects.move")

  -- 選択（visual/operatorモード）
  -- af: 関数全体, if: 関数内部, aa: 引数全体, ia: 引数内部
  vim.keymap.set({ "x", "o" }, "af",
    function() select.select_textobject("@function.outer", "textobjects") end,
    { desc = "Select around function" })
  vim.keymap.set({ "x", "o" }, "if",
    function() select.select_textobject("@function.inner", "textobjects") end,
    { desc = "Select inside function" })
  vim.keymap.set({ "x", "o" }, "aa",
    function() select.select_textobject("@parameter.outer", "textobjects") end,
    { desc = "Select around parameter" })
  vim.keymap.set({ "x", "o" }, "ia",
    function() select.select_textobject("@parameter.inner", "textobjects") end,
    { desc = "Select inside parameter" })

  -- 移動: ]f 次の関数先頭, [f 前の関数先頭
  vim.keymap.set({ "n", "x", "o" }, "]f",
    function() move.goto_next_start("@function.outer", "textobjects") end,
    { desc = "Goto next function start" })
  vim.keymap.set({ "n", "x", "o" }, "[f",
    function() move.goto_previous_start("@function.outer", "textobjects") end,
    { desc = "Goto previous function start" })
end

-- flash.nvim: 画面内の任意の位置に2-3キーストロークでジャンプする
do
  require("flash").setup()
  -- Vimデフォルトの s（1文字置換）は cl、ビジュアルモードの s は c で代替可能なため上書きする
  local flash = require("flash")
  vim.keymap.set("n", "s", function() flash.jump() end, { noremap = true, silent = true, desc = "Flash jump" })
  vim.keymap.set("x", "s", function() flash.jump() end, { noremap = true, silent = true, desc = "Flash jump" })
  vim.keymap.set("o", "s", function() flash.jump() end, { noremap = true, silent = true, desc = "Flash jump" })
end

-- gitsigns: 行単位の git 差分表示とナビゲーション
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end
    -- Navigation（hunk 移動）
    -- 全体構成: git の変更ブロック(hunk)を前後に移動するキーマップ。
    --           Corne v4 では [] がレイヤー操作でコスト高のため、1チョードで押せる
    --           Ctrl+j/k に割り当てる。<C-h>/<C-l>=インデント(横方向)と対を成し、
    --           <C-j>/<C-k>=hunk移動(縦方向)として hjkl 体系を統一する。
    --           旧割当 ]c/[c は、サフィックスの c が change 演算子であるため
    --           前置の ] を取りこぼすと削除事故を起こす危険があり、廃止した。
    -- 競合しない根拠:
    --   1. buffer-local マップ (map ヘルパーが opts.buffer=bufnr を付与)。gitsigns が
    --      アタッチした実ファイルバッファにのみ登録されるため、ターミナル・NvimTree・
    --      Telescope 等の特殊バッファには存在せず、それらの <C-j>/<C-k> を奪わない。
    --   2. Normal モード専用。keymaps.lua の insert 用 <C-j>(=ESC) や、ターミナルの
    --      子プロセスへ送る <C-j> は別モード(i / t)であり、マップテーブルが分離
    --      されているため干渉しない。
    --   3. 潰すのは native <C-j>(= j と同等の下移動)/<C-k>(未割当) のみで実損なし。
    -- 新 API: next_hunk/prev_hunk は非推奨化されており、nav_hunk(方向) に統一された。
    map("n", "<C-j>", function() gs.nav_hunk("next") end, { desc = "Next git hunk" })
    map("n", "<C-k>", function() gs.nav_hunk("prev") end, { desc = "Previous git hunk" })
    -- 対象行の変更内容をフロートウィンドウで見る
    map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview git hunk" })
    -- <C-j>/<C-k> の逐次移動に加え、全 hunk を Telescope 一覧から選んでジャンプする
    -- 全体構成: 現在バッファの hunk を loclist へ流し込み、Telescope の loclist ピッカーで一覧表示する。
    -- 設計意図(自前ピッカーを廃した理由):
    --   hunk 一覧+選択ジャンプは gitsigns と telescope の標準機能だけで実現できる。
    --   gitsigns.setqflist が hunk→リスト整形を、telescope.builtin.loclist が popup+preview+
    --   選択ジャンプを担うため、両者の安定 API を繋ぐだけでよい(自前の finder/previewer 実装が不要)。
    --   use_location_list=true で quickfix ではなく window-local な loclist を使い、グローバルな
    --   quickfix を汚さない。open=false で loclist ウィンドウ自体は開かず telescope 側にのみ見せる。
    map("n", "<leader>hl", function()
      -- telescope は遅延ロードのため未ロードなら先に読み込む(既ロードなら無害)
      if not package.loaded["telescope.builtin"] then
        pcall(function() require("pack_lazy").load("telescope.nvim") end)
      end
      gs.setqflist(0, { use_location_list = true, open = false })
      require("telescope.builtin").loclist()
    end, { desc = "List git hunks (Telescope)" })
  end,
})

-- lualine: ステータスライン
require("lualine").setup({
  options = {
    globalstatus = false,
    icons_enabled = false, -- アイコンを無効にする
    theme = "auto",
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "" },
    lualine_c = {
      "filename",
      -- fugitive提供のstatusline表記を追加。
      -- 背景: :Gdiffsplit (dv/dh) でdiff bufferを開いた際、working tree側と index/HEAD側は
      --   どちらも同じファイル内容を表示するため見た目では判別できない。FugitiveStatusline()は
      --     - working tree buffer: 空文字列 / index buffer: [Git(0)] / HEAD/blob buffer: [Git(HEAD)] 等
      --   を返すので、statuslineに出すだけでどちらのバッファにいるか一目で分かる。
      function() return vim.fn.FugitiveStatusline() end,
    },
    lualine_x = { "filetype" }, -- encoding format を削除
    lualine_y = { "progress" }, -- ファイル全体に対するカーソル位置の割合(Top/xx%/Bot)
    lualine_z = { "location" },
  },
})

-- vim-fugitive: 軽量なgit操作UI。in-process で起動するため hunk 単位の stage/commit 運用に向く
-- :Git status バッファ内のキーを安全寄りにカスタマイズ
-- 背景: fugitiveのデフォルトでは `X` が checkout(作業ツリー破棄) に割り当てられ、誤爆リスクがある
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function()
    vim.keymap.set("n", "X", "<Nop>", {
      buffer = true,
      desc = "Disabled: use CLI for checkout to avoid accidental reset",
    })
  end,
})

-- mason: LSP サーバー等のインストーラ
require("mason").setup()

-- mason-lspconfig: mason でインストールした LSP サーバーと nvim-lspconfig を繋ぐ
-- 必ず mason の後に初期化する(配列順・setup順の双方で担保)
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "marksman",
    "terraformls",
    "ts_ls",
    "biome",
    "gh_actions_ls",
    "tailwindcss",
    "yamlls",
    "astro",
  },
})

-- nvim-surround: 囲み文字の追加/変更/削除
require("nvim-surround").setup()

-- Comment.nvim: コメントのトグル
require("Comment").setup()

-- indent-blankline: インデントガイド
require("ibl").setup()

-- aerial: コードのアウトライン表示
-- aerial自身のコストは~1.5msのため遅延化せず起動時に読み込む
-- (telescope拡張の登録は telescope 側で行う。telescope は遅延読み込み)
-- filter_kind: アウトラインに表示するシンボル種別のホワイトリスト。
-- 全体設計:
--   aerialのデフォルトは Class/Function/Method など8種のみを表示し、Variable/Constant を除外する。
--   このため TypeScript の `export const foo = ...`(drizzleのテーブル定義や定数配列)が
--   アウトラインに出ず、レビュー時に構造を追えなかった。
--   → ファイルタイプ別マップ("_"が既定フォールバック)で TS系だけ許可種別を広げる。
--     他言語は既定のまま(全表示にすると他言語のアウトラインがノイズ化するため対象をTSに限定)。
-- 詳細:
--   - Variable/Constant: `export const ...` の定義本体。tsserverが版により両種別を使い分けるため両方許可。
--   - Object: オブジェクトリテラルで組む定義(スキーマ等)を拾うため。
local ts_kinds = {
  "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct",
  "Constant", "Variable", "Object",
}
require("aerial").setup({
  filter_kind = {
    -- 既定(TS以外の全ファイルタイプ)。aerialのデフォルト8種を維持する
    ["_"] = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct" },
    typescript = ts_kinds,
    typescriptreact = ts_kinds,
  },
})

-- snacks.nvim: ターミナル / scratch メモ等のユーティリティ群
do
  local snacks = require("snacks")

  -- scratch メモの「昇格(永続化)」処理
  -- 全体設計: scratchは普段は使い捨てだが、稀に正式に残したい時だけ現在のバッファ内容を
  --   プロジェクト直下(cwd)へタイムスタンプ付き .md として書き出す。
  -- 詳細:
  --   - 書き出し先は vim.fn.getcwd()。作業中リポジトリのルートに置かれる。
  --   - 注意: cwd直下はgit管理対象に混ざりうる。汚染を避けたい場合は .gitignore に `memo_*.md` を追加する。
  local function promote_scratch(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- 空メモの誤昇格を防ぐ(全行が空白なら何もしない)
    local has_content = false
    for _, l in ipairs(lines) do
      if l:match("%S") then has_content = true break end
    end
    if not has_content then
      vim.notify("scratch が空のため昇格しません", vim.log.levels.WARN)
      return
    end
    local path = vim.fn.getcwd() .. "/" .. os.date("memo_%Y%m%d_%H%M%S.md")
    vim.fn.writefile(lines, path)
    vim.notify("scratch を永続化しました: " .. path, vim.log.levels.INFO)
  end

  -- 1. Setup
  snacks.setup({
    terminal = {
      enabled = true,
      -- フローティングウィンドウとして表示（lazygit風）
      win = {
        style = "float",
        position = "float",
        border = "rounded",
        width = 0.8,  -- 画面幅の80%
        height = 0.8, -- 画面高さの80%
        -- Snacks floatingウィンドウはデフォルトで行番号を非表示にするため、明示的に有効化
        wo = {
          number = true,
          relativenumber = true,
        },
      },
    },
    -- scratch: コード確認中のメモ用フローティングウィンドウ
    -- 全体設計: cwd/ブランチ単位で自動保存される器を用意し、UX上は使い捨てに見せる。
    scratch = {
      ft = "markdown", -- render-markdown.nvim / treesitter の装飾をそのまま活かす
      win = {
        border = "rounded",
        -- scratchバッファ内専用のキー。markdownのフロート上でのみ有効。
        keys = {
          promote = {
            "<leader>ms",
            function(self) promote_scratch(self.buf) end,
            desc = "scratchをプロジェクト直下に永続化",
            mode = "n",
          },
        },
      },
    },
  })

  -- 2. キーマッピング (vim.keymap.set を使用)
  -- Normal mode (n) と Terminal mode (t) の両方でトグルできるようにする
  vim.keymap.set({ "n", "t" }, "<C-\\>", function()
    snacks.terminal.toggle()
  end, { desc = "Toggle Terminal" })

  -- scratch メモ: <Leader>. でトグル開閉(1キーでメモ⇔コードを往復)
  vim.keymap.set("n", "<Leader>.", function()
    snacks.scratch()
  end, { desc = "Toggle scratch memo" })
  -- 過去のscratchメモを一覧から選んで開く(cwd/ブランチ別に蓄積されたもの)
  vim.keymap.set("n", "<Leader>S", function()
    snacks.scratch.select()
  end, { desc = "Select scratch memo" })
end

-- claudecode.nvim: Claude Code 連携
require("claudecode").setup({
  -- 全体: リアルタイム選択トラッキングを無効化してカーソル遅延を回避する
  -- 詳細: 選択送信は手動コマンド側で範囲を直接送るため、追跡は不要
  track_selection = false,
  visual_demotion_delay_ms = 100,
  log_level = "warn",
  -- 全体: claude codeターミナル固有のキーマップ設定(snacks.nvim のターミナルウィンドウ経由)
  ---@diagnostic disable-next-line: missing-fields
  terminal = {
    -- 全体: 実ウィンドウ(vsplit)として開く。フロートは使わない。
    --   起動時の全画面表示は lua/claude.lua 側で、開いた直後に wincmd T で専用タブへ移して実現する。
    snacks_win_opts = {
      position = "right",
      width = 0.40,
      keys = {
        -- Control-D 無効化は claude.lua 側の事情に応じて調整(現状は未設定)
      },
    },
  },
})

-- render-markdown.nvim: markdown のインライン装飾(treesitter の後にロード済み)
do
  -- 全体: 完了済みTODOを未完了と一目で区別できるようにする
  -- 詳細: 完了タスク行全体に当てる専用ハイライト(取り消し線+グレー)を定義し、
  --   checkbox.checked.scope_highlight に指定する。
  vim.api.nvim_set_hl(0, "RenderMarkdownCheckedScope", {
    fg = "#6c7086", -- グレーアウト
    strikethrough = true,
  })
  require("render-markdown").setup({
    -- 全体: 見出しレベルを示す先頭アイコンを視認しやすくする
    -- 詳細: 既定の丸数字グリフは小さく見づらいため素のテキスト "N)" 表記へ変更する。
    heading = {
      icons = { "1) ", "2) ", "3) ", "4) ", "5) ", "6) " },
    },
    checkbox = {
      checked = {
        icon = "󰄬 ",
        highlight = "RenderMarkdownChecked",
        -- 完了タスクのテキスト全体を取り消し線+グレーで弱める
        scope_highlight = "RenderMarkdownCheckedScope",
      },
      unchecked = {
        icon = "□ ",
        highlight = "RenderMarkdownUnchecked",
      },
    },
    -- 全体: コードブロックを本文から見分けやすくする
    code = {
      style = "full",
      position = "left",
      width = "block",
      min_width = 40,
      border = "thick",
      left_pad = 2,
      right_pad = 2,
      sign = true,
    },
  })

  -- 全体: light モードで見出し/コード背景のコントラスト不足を補正する(colorscheme 依存を増やさない)
  -- 詳細: render-markdown 専用ハイライトグループを淡い色へ上書きする。
  --   dark モードでは既定色を尊重し、light のときだけ補正。ColorScheme 契機でも再適用する。
  local function tune_markdown_hl()
    if vim.o.background ~= "light" then return end
    local set = vim.api.nvim_set_hl
    set(0, "RenderMarkdownCode", { bg = "#e6e9ef" })
    set(0, "RenderMarkdownCodeInline", { bg = "#e6e9ef" })
    -- 見出し1(シアン)・2(グリーン)は既定色を尊重。3〜6 のみ寒色グラデーションへ変更する。
    local headings = {
      [3] = { fg = "#0ca678", bg = "#d6efe7" }, -- emerald/teal
      [4] = { fg = "#1098ad", bg = "#d6ecef" }, -- cyan
      [5] = { fg = "#1971c2", bg = "#d8e6f5" }, -- blue
      [6] = { fg = "#6741d9", bg = "#e2dcf7" }, -- indigo
    }
    for level, c in pairs(headings) do
      set(0, "RenderMarkdownH" .. level, { fg = c.fg, bold = true })
      set(0, "RenderMarkdownH" .. level .. "Bg", { bg = c.bg })
    end
  end
  tune_markdown_hl()
  -- setup() 後に登録するため render-markdown 自身の再リンクより後に走り、上書きが勝つ
  vim.api.nvim_create_autocmd("ColorScheme", { callback = tune_markdown_hl })
end

-- ---------------------------------------------------------------------
-- 3) 遅延ロード群(pack_lazy 経由で cmd/ft/event 発火時に add+setup)
-- ---------------------------------------------------------------------

-- telescope: :Telescope 発火時にロード
local function setup_telescope()
  local actions = require("telescope.actions")
  require("telescope").setup({
    defaults = {
      -- 検索対象から除外するファイル
      file_ignore_patterns = {
        "%.git/",
      },
      mappings = {
        i = {
          -- Insert Mode で <C-c> を押すと、ラグなしで即座に閉じる
          ["<C-c>"] = actions.close,
        },
        n = {
          ["<C-c>"] = actions.close,
        },
      },
    },
    -- 隠しファイル表示する
    pickers = {
      find_files = {
        hidden = true,
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
    },
  })
  -- aerial がruntimepathに存在する場合のみ拡張を登録(未登録でも落ちないよう pcall で保護)
  pcall(require("telescope").load_extension, "aerial")
end
lazy.on_cmd(gh("nvim-telescope/telescope.nvim"), { "Telescope" }, setup_telescope)

-- gitlinker: :GitLink 発火時にロード(行範囲対応のため pack_lazy 側で range を引き継ぐ)
lazy.on_cmd(gh("linrongbin16/gitlinker.nvim"), { "GitLink" }, function()
  require("gitlinker").setup()
end)

-- octo: :Octo 発火時にロード。picker backend に telescope を使うため先にロードする
lazy.on_cmd(gh("pwntester/octo.nvim"), { "Octo" }, function()
  -- 依存(plenary / nvim-web-devicons)は即時ロード済み。telescope のみ遅延なのでここで確実にロード。
  lazy.load("telescope.nvim")
  require("octo").setup({
    picker = "telescope",
  })
end)

-- nvim-tree: :NvimTree* 発火時にロード(filer)
local function setup_nvimtree()
  local function nvim_tree_attach(bufnr)
    local api = require("nvim-tree.api")
    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end
    -- default mappings
    api.map.on_attach.default(bufnr)
    -- nvim-tree固有のcustom mappings
    vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
    vim.keymap.set("n", "h", api.node.open.edit, opts("Close"))
  end
  require("nvim-tree").setup({
    on_attach = nvim_tree_attach,
    -- git 統合を有効化
    -- 全体構成: フロート有効化 → サイズと位置を screen から動的計算 → border を rounded
    view = {
      float = {
        enable = true,
        open_win_config = function()
          local screen_w = vim.opt.columns:get()
          local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
          local window_w = math.floor(screen_w * 0.7)
          local window_h = math.floor(screen_h * 0.8)
          return {
            border = "rounded",
            relative = "editor",
            row = math.floor((screen_h - window_h) / 2),
            col = math.floor((screen_w - window_w) / 2),
            width = window_w,
            height = window_h,
          }
        end,
      },
      width = function()
        return math.floor(vim.opt.columns:get() * 0.7)
      end,
    },
    git = {
      enable = true,  -- git関連の情報を有効にする
      ignore = false, -- .gitignore対象のファイルも表示する
    },
    filters = {
      -- 非表示にしたい項目をvimの正規表現で指定
      custom = {
        "^\\.git$",
        "^node_modules",
        "^\\.idea",
        "^\\.vscode",
        "^\\.DS_Store",
        "^\\.git.nosync",
        "^\\.obsidian",
        "^\\.turbo",
        "^\\.dist",
        "^\\.husky",
      },
    },
    -- ライブフィルタ(`f`キー)の挙動。マッチしたノードに至るパス上のフォルダのみ残す
    live_filter = {
      prefix = "[FILTER]: ",
      always_show_folders = false,
    },
    renderer = {
      icons = {
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true,
        },
      },
      indent_width = 1,
    },
    actions = {
      open_file = {
        quit_on_open = true, -- ファイルを開いたらツリーを閉じる
      },
    },
  })
end
lazy.on_cmd(
  gh("nvim-tree/nvim-tree.lua"),
  { "NvimTreeToggle", "NvimTreeFindFileToggle", "NvimTreeFindFile", "NvimTreeFocus" },
  setup_nvimtree
)

-- obsidian: markdown を開いた時にロード
-- cmd だと wiki link 補完や UI 装飾が手動コマンド実行まで無効になるため ft(markdown) を使う
local function setup_obsidian()
  local obsidian_valut_path = "/Users/take/Documents/obsidian"
  require("obsidian").setup({
    -- 旧コマンド形式(ObsidianXxx)を無効化し、新形式(Obsidian xxx)のみ使用する
    legacy_commands = false,
    -- 全体: markdownの見た目の描画は render-markdown.nvim に一本化する
    -- 詳細: 両方有効だと描画が二重になりアイコンとテキストの位置がずれるため obsidian 側を無効化する
    ui = { enable = false },
    workspaces = {
      {
        name = "personal",
        path = obsidian_valut_path,
        ---@diagnostic disable-next-line: missing-fields
        overrides = {
          notes_subdir = "inbox",
        },
      },
    },
    daily_notes = {
      folder = "daily",
      template = obsidian_valut_path .. "/template/frontmatter.md",
    },
    ---@diagnostic disable-next-line: missing-fields
    templates = {
      enabled = true,
      folder = "template",
    },
    frontmatter = {
      enabled = function(path)
        local excluded_dir = vim.fs.normalize(obsidian_valut_path .. "/blogs/articles")
        path = vim.fs.normalize(path)
        if path:sub(1, #excluded_dir) == excluded_dir then
          return true -- Zenn記事ではfrontmatterを無効化
        end
        return false   -- それ以外のファイルではfrontmatterを有効化
      end,
    },
    note_id_func = function(title)
      if title ~= nil then
        return title
      end
      return tostring(os.time())
    end,
  })
end
lazy.on_ft(gh("obsidian-nvim/obsidian.nvim"), { "markdown" }, setup_obsidian)

-- nvim-autopairs: 初回 InsertEnter でロード(挿入時の括弧自動補完)
lazy.on_event(gh("windwp/nvim-autopairs"), "InsertEnter", function()
  require("nvim-autopairs").setup({})
end)

-- common conf for all language server
vim.lsp.config('*', {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})
-- lsp enableに設定する前に、以下の設定を有効化する
-- lua language severに対して、'vim'はglobal変数なので警告しないように設定
-- lua language serverは通常のLua環境を前提としているため、vimという変数を未定義として警告するから
vim.lsp.config.lua_ls = {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      },
      -- lua_ls の初期化を高速化するための設定
      workspace = {
        -- サードパーティライブラリのチェックを無効化（確認ダイアログをスキップ）
        checkThirdParty = false,
        -- Neovim runtime と設定ファイルのみを対象にする
        -- lazydev.nvim が vim.* の型情報を提供するため、他のライブラリは不要
        library = {
          vim.env.VIMRUNTIME,
        },
        -- ワークスペースのプリロード数を制限して初期化を高速化
        maxPreload = 1000,
        preloadFileSize = 100,
      },
    }
  }
}
-- terraformls の設定
-- 全体構成: fugitive:// 等の仮想バッファでは terraform-ls を起動させない
-- 背景: git worktree 内の .tf を fugitive 経由(:Gdiffsplit や :Git ステータスからの
--   diff/index 表示)で開くと、バッファ名が "fugitive://..." という file 以外のスキームになる。
--   terraform-ls は file:// 前提の実装で、それ以外の URI を MustParseURI で弾いて
--   panic 終了(exit code 2)する既知のバグがある(semantic_tokens 要求時にクラッシュ)。
--   そのため、サーバーの行儀に依存せずエディタ側で file スキーム以外を attach 対象から除外する。
-- 詳細: root_dir をコールバック形式にし、file 以外のスキームでは on_dir を呼ばない
--   = クライアントを起動させない(attach 後の detach 方式だと panic を起こす
--   semanticTokens 要求との競合が残るため、起動させない方が確実)。
vim.lsp.config.terraformls = {
  root_dir = function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    -- 通常ファイルは "/Users/..." だが、fugitive 等の仮想バッファは "scheme://..." になる
    if name:match('^%a[%w+.-]*://') then
      return -- on_dir を呼ばない → クライアントを起動しない
    end
    -- 通常ファイル: .terraform / .git を上方向に探索して root を決める
    on_dir(vim.fs.root(bufnr, { '.terraform', '.git' }) or vim.fs.dirname(name))
  end,
}
-- lspconfig で LSP サーバーを設定
-- mason-lspconfig は lspconfig と連携して、インストールされた LSP サーバーを自動的に設定
-- 個別のLSPサーバーの設定は lspconfig にて設定
-- -- lua_ls の設定例
vim.lsp.enable('lua_ls')
-- marksman の設定
vim.lsp.enable('marksman')
vim.lsp.enable('terraformls')
vim.lsp.enable('ts_ls')
vim.lsp.enable('biome')
vim.lsp.enable('gh_actions_ls')
vim.lsp.enable('tailwindcss')
vim.lsp.enable('postgres_lsp')
vim.lsp.enable('astro')
-- 他のライブラリとの依存関係があるため初期化外で設定する。
-- nvim起動後にsourceでreloadしても問題ないため
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
    -- lazydev.nvim: Neovim Lua API（vim.api, vim.fn, vim.opt等）の補完を提供
    -- group_index = 0 で他のソースより優先される
    -- lua_ls単体ではNeovim固有のAPIの型情報を持たないため、このソースが必要
    { name = "lazydev", group_index = 0 },
    { name = "nvim_lsp" },
    { name = "luasnip" },
    -- 辞書ソース: 第一層に置く理由
    -- cmp.config.sources()は「先頭のグループから候補を集め、空ならば次のグループに進む」仕様。
    -- 第二層(fallback)に置くと、LSPが候補を1件でも返したファイルタイプ(.lua/.ts等)で
    -- dictionaryが完全にsuppressされる。第一層に置くことでLSP候補と並列表示される。
    -- keyword_length = 3: 候補数の爆発を防ぐ。1〜2文字だと候補が数千〜数万件になり
    --   nvim-cmp内部のスコア計算が重くなる + UX上もノイズが多すぎて選択コスト>入力コストになる
    -- max_item_count = 20: ポップアップ表示数の上限。LSP/buffer候補と並べた時の見やすさ優先
    { name = "dictionary", keyword_length = 3, max_item_count = 20 },
  }, {
    { name = "buffer" },
  })
})

-- カスタムスニペットの読み込み
-- プラグイン初期化後に読み込む必要があるため、cmp.setup の後に配置
require("snippets")

-- 辞書補完(cmp-dictionary)の設定
-- 全体構成: aspellで生成した英単語リストを読み込み、起動時に内部trieを構築する
-- 詳細:
--   - paths: 読み込む辞書ファイル。nvim/dict_setup.sh が ~/.config/nvim/dict/english.txt に生成する
--   - exact_length: trieの完全一致prefixに使う先頭文字数。
--     重要: cmp側の keyword_length と必ず一致させる(または上回る)必要がある。
--     cmp_dictionary内部で req を exact_length で切り詰めた後 keyword_length と比較するため、
--     exact_length < keyword_length だと常に空配列を返してしまうバグがある
--     (cmp_dictionary/source.lua の complete() 参照)。
--   - first_case_insensitive = true: 1文字目の大小を無視する(App入力でappleもヒット)
-- 辞書ファイルが未生成のマシンでもエラーにならないよう filereadable で防御する
local dict_path = vim.fn.stdpath('config') .. '/dict/english.txt'
if vim.fn.filereadable(dict_path) == 1 then
  require("cmp_dictionary").setup({
    paths = { dict_path },
    exact_length = 3,
    first_case_insensitive = true,
  })
else
  -- 通知のみ。エラー扱いにしないのは、辞書ファイル生成はホスト依存(brew + aspell)のため
  -- 新規セットアップ直後など、未生成状態でも他の補完機能は通常通り動かしたい
  vim.schedule(function()
    vim.notify(
      "cmp-dictionary: 辞書ファイルが見つかりません (" .. dict_path .. "). " ..
      "bash nvim/dict_setup.sh で生成してください",
      vim.log.levels.WARN
    )
  end)
end

-- harpoon: よく使うファイルをピンして1キーで切り替える
-- <Leader>ha でピン登録、<Leader>hh でリスト表示、<Leader>1-4 で即ジャンプ
-- keymaps.lua はプラグイン読み込み前にrequireされるため、ここで設定する
local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set('n', '<Leader>ha', function() harpoon:list():add() end, { noremap = true, silent = true, desc = "Harpoon add file" })
vim.keymap.set('n', '<Leader>hh', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { noremap = true, silent = true, desc = "Harpoon menu" })
vim.keymap.set('n', '<Leader>1', function() harpoon:list():select(1) end, { noremap = true, silent = true, desc = "Harpoon file 1" })
vim.keymap.set('n', '<Leader>2', function() harpoon:list():select(2) end, { noremap = true, silent = true, desc = "Harpoon file 2" })
vim.keymap.set('n', '<Leader>3', function() harpoon:list():select(3) end, { noremap = true, silent = true, desc = "Harpoon file 3" })
vim.keymap.set('n', '<Leader>4', function() harpoon:list():select(4) end, { noremap = true, silent = true, desc = "Harpoon file 4" })
