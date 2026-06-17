-- activate vim loader to use plugin manager
-- set file top to enable module cachs
vim.loader.enable()
require("command")
require("options")
require("keymaps")
require("lsp")
require("claude")


-- activate pkcr vim
local function bootstrap_pckr()
  local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"
  ---@diagnostic disable-next-line: undefined-field
  if not (vim.uv or vim.loop).fs_stat(pckr_path) then
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

-- # 背景
-- pckr の plugin 登録を初回のみ実施するために、ローカル関数として定義する
-- require('pckr').add {} をそのまま定義しておくと、`source %`の実行時にpluginが再登録され、pluginによっては次の警告が出るため
-- [pckr.nvim[WARN  09:52:04] plugin.lua:195: Plugin "nvim-autopairs" is specified more than once!
-- ※呼び出す関数は、この定義の後に存在
--
-- # 変更後の反映手順
-- 一時的に初回作成のフラグをnilとして、再読み込み実施する
-- 次のコマンドをターミナルで実行すること
--  :lua vim.g.__pckr_initialized = nil
--  :source %
--  :PckrSync
local function setup_plugins()
  require('pckr').add {
    {
      'folke/lazydev.nvim', -- luaのcompletionにnvimの設定を読み込ませる
      -- luaのlsp server(lua_ls)が、vim関連の関数を認識できるように、他のライブラリよりも優先的に読み込む
      config = function()
        require("lazydev").setup()
      end
    },
    {
      -- nvim-treesitter (main branch): フルリライト版
      -- 全体構成: 旧master系のAPI(ensure_installed/auto_install/highlightモジュール等)は廃止され、
      --   1) このプラグインは「パーサーと query の取得」だけを担当
      --   2) ハイライト/折りたたみは Neovim ネイティブ (vim.treesitter.start / foldexpr) を使う(options.lua側)
      --   3) パーサーは setup ではなく明示インストール (require('nvim-treesitter').install) で入れる
      -- 背景: master branchは Neovim 0.12 のクエリディレクティブAPI変更(match[id]がTSNode→TSNode[]へ)
      --   に未対応で、markdown injection 評価時に query_predicates.lua:141 で落ちる。
      --   公式が master を locked 扱いにし main branch への移行を推奨している。
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      run = ':TSUpdate',  -- インストール/更新時にパーサーを最新化
      config = function()
        -- 防御的記述: ブートストラップ時はまだ master branch のままで config が走るため、
        --   main 専用 API (install) が存在しないことがある。
        --   主に「初回 :PckrSync 前」「branch 切替直後の最初の起動」で発生する一過性問題。
        --   pcall + 関数存在チェックで吸収し、:PckrSync 完了後の再起動で本来のパスに乗る。
        local ok, ts = pcall(require, 'nvim-treesitter')
        if not ok then return end
        if type(ts.setup) == 'function' then ts.setup() end
        if type(ts.install) == 'function' then
          -- 普段使うパーサーを明示インストール (既にインストール済みなら no-op、非同期)
          -- markdown / markdown_inline は markview.nvim の injection 評価で必須
          ts.install({
            'lua', 'vim', 'vimdoc', 'bash',
            'markdown', 'markdown_inline',
            'json', 'yaml', 'toml', 'regex',
          })
        end
      end
    },
    -- flash.nvim: 画面内の任意の位置に2-3キーストロークでジャンプする
    -- s を押すと検索文字の入力後、画面上にラベルが表示され、ラベル文字を入力するとその位置に飛ぶ
    {
      "folke/flash.nvim",
      config = function()
        require("flash").setup()
        -- Vimデフォルトの s（1文字置換）は cl、ビジュアルモードの s は c で代替可能なため上書きする
        -- ビジュアルモードではジャンプ先まで選択範囲を拡張する用途で使う
        local flash = require("flash")
        vim.keymap.set('n', 's', function() flash.jump() end, { noremap = true, silent = true, desc = "Flash jump" })
        vim.keymap.set('x', 's', function() flash.jump() end, { noremap = true, silent = true, desc = "Flash jump" })
        vim.keymap.set('o', 's', function() flash.jump() end, { noremap = true, silent = true, desc = "Flash jump" })
      end
    },
    -- nvim-treesitter-textobjects (main branch):
    --   treesitterの構文木を利用してコード構造単位で選択・移動する
    -- 全体構成:
    --   1) setup() でグローバル挙動 (lookahead / set_jumps) のみ宣言
    --   2) キーマップは旧版の keymaps = {...} 宣言ではなく、vim.keymap.set で個別に書く
    --      (main branch の設計方針: マッピングの責務をユーザー側に明示化)
    --   3) select_textobject / goto_* の第2引数 'textobjects' は queries/<lang>/textobjects.scm を指す
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      branch = 'main',
      config = function()
        require('nvim-treesitter-textobjects').setup({
          select = {
            lookahead = true,  -- カーソル前方のオブジェクトも対象にする
          },
          move = {
            set_jumps = true,  -- ジャンプリストに記録する
          },
        })

        local select = require('nvim-treesitter-textobjects.select')
        local move   = require('nvim-treesitter-textobjects.move')

        -- 選択（visual/operatorモード）
        -- af: 関数全体, if: 関数内部, aa: 引数全体, ia: 引数内部
        vim.keymap.set({ 'x', 'o' }, 'af',
          function() select.select_textobject('@function.outer', 'textobjects') end,
          { desc = 'Select around function' })
        vim.keymap.set({ 'x', 'o' }, 'if',
          function() select.select_textobject('@function.inner', 'textobjects') end,
          { desc = 'Select inside function' })
        vim.keymap.set({ 'x', 'o' }, 'aa',
          function() select.select_textobject('@parameter.outer', 'textobjects') end,
          { desc = 'Select around parameter' })
        vim.keymap.set({ 'x', 'o' }, 'ia',
          function() select.select_textobject('@parameter.inner', 'textobjects') end,
          { desc = 'Select inside parameter' })

        -- 移動: ]f 次の関数先頭, [f 前の関数先頭
        vim.keymap.set({ 'n', 'x', 'o' }, ']f',
          function() move.goto_next_start('@function.outer', 'textobjects') end,
          { desc = 'Goto next function start' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[f',
          function() move.goto_previous_start('@function.outer', 'textobjects') end,
          { desc = 'Goto previous function start' })
      end
    },
    'nvim-lua/plenary.nvim',
    -- insert modeでのCtrl-Oが動作しなくなるためコメントアウトする
    -- {
    --   "folke/which-key.nvim",
    --   event = "VeryLazy",
    --   opts = {
    --     -- your configuration comes here
    --     -- or leave it empty to use the default settings
    --     -- refer to the configuration section below
    --   },
    --   keys = {
    --     {
    --       "<leader>?",
    --       function()
    --         require("which-key").show({ global = false })
    --       end,
    --       desc = "Buffer Local Keymaps (which-key)",
    --     },
    --   },
    -- },
    {
      'nvim-telescope/telescope.nvim',
      cmd = { 'Telescope' },
      config = function()
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
                -- defaultのEscだと、タイプしてから閉じるまで時間がかかるため
                ["<C-c>"] = actions.close,
              },
              n = {
                -- Insert Mode で <C-c> を押すと、ラグなしで即座に閉じる
                -- defaultのEscだと、タイプしてから閉じるまで時間がかかるため
                ["<C-c>"] = actions.close,
              }
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
              end
            },
          },
        })
        -- aerialがruntimepathに存在する場合のみ拡張を登録
        -- pckrの読み込み順序によってはaerialが未登録の場合があるためpcallで保護
        pcall(require("telescope").load_extension, "aerial")
      end
    },
    {
      'lewis6991/gitsigns.nvim',
      config = function()
        require('gitsigns').setup {
          on_attach = function(bufnr)
            local gs = package.loaded.gitsigns
            local function map(mode, l, r, opts)
              opts = opts or {}
              opts.buffer = bufnr
              vim.keymap.set(mode, l, r, opts)
            end
            -- Navigation（移動用の設定）
            map('n', ']c', function()
              if vim.wo.diff then return ']c' end
              vim.schedule(function() gs.next_hunk() end)
              return '<Ignore>'
            end, { expr = true, desc = "Next git hunk" })
            map('n', '[c', function()
              if vim.wo.diff then return '[c' end
              vim.schedule(function() gs.prev_hunk() end)
              return '<Ignore>'
            end, { expr = true, desc = "Previous git hunk" })
            -- 対象行の変更内容をフロートウィンドウで見る
            map('n', '<leader>hp', gs.preview_hunk, { desc = "Preview git hunk" })
          end
        }
      end
    },
    {
      'nvim-lualine/lualine.nvim',
      config = function()
        require('lualine').setup {
          options = {
            globalstatus = false,
            icons_enabled = false,   --アイコンを無効にする
            theme = 'auto',
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
          },
          sections = {
            lualine_a = { 'mode' },
            lualine_b = { '' },
            lualine_c = {
              'filename',
              -- fugitive提供のstatusline表記を追加。
              -- 背景: :Gdiffsplit (dv/dh) でdiff bufferを開いた際、
              --   working tree側とindex/HEAD側はどちらも同じファイル内容を表示するため
              --   見た目では判別できない。FugitiveStatusline()は
              --     - working tree buffer: 空文字列
              --     - index buffer:        [Git(0)]
              --     - HEAD/blob buffer:    [Git(HEAD)] や [Git(<sha>)]
              --   を返すので、statuslineに出すだけでどちらのバッファにいるか一目で分かる。
              function() return vim.fn.FugitiveStatusline() end,
            },
            lualine_x = { 'filetype' },     -- encoding formatを削除
            lualine_y = { 'progress' },     -- ファイル全体に対するカーソル位置の割合(Top/xx%/Bot)
            lualine_z = { 'location' }
          }
        }
      end
    },
    'kdheepak/lazygit.nvim',
    {
      -- fugitive: 軽量なgit操作UI。lazygitほど多機能ではないが、
      -- in-process(telescope並に高速)で起動するため、
      -- 複数ファイル横断でのhunk単位のstage/commit運用に向く
      'tpope/vim-fugitive',
      config = function()
        -- :Git status バッファ内のキーを安全寄りにカスタマイズ
        -- 背景: fugitiveのデフォルトでは `X` が checkout(作業ツリー破棄) に割り当てられ、
        --   新規追加ファイルなど undo 不能な操作の誤爆リスクがある
        -- 解決: fugitive filetype の buffer 内でのみ `X` を無効化する
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "fugitive",
          callback = function()
            vim.keymap.set("n", "X", "<Nop>", {
              buffer = true,
              desc = "Disabled: use CLI for checkout to avoid accidental reset",
            })
          end,
        })
      end,
    },
    'neovim/nvim-lspconfig',
    { 'williamboman/mason.nvim',
      config = function()
        -- lsp
        require("mason").setup()
      end
    },
    {
      -- mason-lspconfigは必ずmasonの後に初期化する
      'williamboman/mason-lspconfig.nvim',
      config = function()
        -- masonでinstallしたlsp serverとnvim-lspconfigを繋ぐ役割
        -- optionを記載しないでも、defaultでinstallしてlspが有効化される
        require("mason-lspconfig").setup({
          ensure_installed = {
            'lua_ls',
            'marksman',
            'terraformls',
            'ts_ls',
            'biome',
            'gh_actions_ls',
            'tailwindcss',
            'yamlls',
            'astro',
          }
        })
      end
    },
    'L3MON4D3/LuaSnip',
    {
      'kylechui/nvim-surround',
      config = function()
        require("nvim-surround").setup()
      end
    },
    'ixru/nvim-markdown',
    {
      'numToStr/Comment.nvim',
      config = function()
        require('Comment').setup()
      end
    },
    {
      'lukas-reineke/indent-blankline.nvim',
      config = function()
        require('ibl').setup()
      end
    },
    {
      -- aerial自身のコストは~1.5msのため遅延化せず起動時に読み込む
      -- telescope拡張の登録はtelescope側で行う（telescopeは遅延読み込み）
      "stevearc/aerial.nvim",
      config = function()
        require("aerial").setup()
      end
    },
    {
      'linrongbin16/gitlinker.nvim',
      cmd = { 'GitLink' },
      config = function()
        require("gitlinker").setup()
      end,
    },
    -- Snacks.nvim の定義
    {
      'folke/snacks.nvim',
      -- config 関数の中で setup を呼ぶのが pckr の正しい作法です
      config = function()
        local snacks = require("snacks")

        -- scratch メモの「昇格(永続化)」処理
        -- 全体設計: scratchは普段は使い捨て(自動保存はsnacks任せでファイル名管理不要)だが、
        --   稀に正式に残したい時だけ、現在のバッファ内容をプロジェクト直下(cwd)へ
        --   タイムスタンプ付き .md として書き出す。これにより「使い捨て感」と
        --   「オンデマンド永続化」を両立する。
        -- 詳細:
        --   - 書き出し先は vim.fn.getcwd()。作業中リポジトリのルートに置かれるため、
        --     そのコードに紐づくメモとして近くに残せる。
        --   - 注意: cwd直下はgit管理対象に混ざりうる。コミット汚染を避けたい場合は
        --     リポジトリの .gitignore に `memo_*.md` を追加すること。
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
              }
            }
          },
          -- scratch: コード確認中のメモ用フローティングウィンドウ
          -- 全体設計: cwd/ブランチ単位で自動保存される器を用意し、UX上は使い捨てに見せる。
          --   ファイル名を付ける操作が不要なため体感は使い捨てだが、内部的には保存されるので
          --   誤って閉じてもロストしない(安全網)。
          scratch = {
            ft = "markdown", -- render-markdown.nvim / treesitter の装飾をそのまま活かす
            win = {
              border = "rounded",
              -- scratchバッファ内専用のキー。markdownのフロート上でのみ有効なので
              -- グローバルキーマップを汚さずに「昇格」操作を割り当てられる。
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
    },
    {
      "pwntester/octo.nvim",
      cmd = { 'Octo' },
      requires = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        -- OR "ibhagwan/fzf-lua",
        -- OR "folke/snacks.nvim",
        "nvim-tree/nvim-web-devicons",
      },
      config = function()
        require("octo").setup({
          picker = "telescope",
        })
      end
    },
    -- filer
    {
      'nvim-tree/nvim-tree.lua',
      cmd = { 'NvimTreeToggle', 'NvimTreeFindFileToggle', 'NvimTreeFindFile', 'NvimTreeFocus' },
      requires = {
        'nvim-tree/nvim-web-devicons', -- icons
      },
      config = function()
        local function nvim_tree_attach(bufnr)
          local api = require "nvim-tree.api"
          local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end
          -- default mappings（旧API: api.config.mappings.default_on_attach は非推奨）
          api.map.on_attach.default(bufnr)
          -- nvim-tree固有のcustom mappings
          vim.keymap.set('n', 'l', api.node.open.edit, opts('Open'))
          vim.keymap.set('n', 'h', api.node.open.edit, opts('Close'))
        end
        require("nvim-tree").setup({
          on_attach = nvim_tree_attach,
          -- git 統合を有効化
          -- 全体構成: フロート有効化 → サイズと位置を screen から動的計算 → border を rounded
          -- 詳細: open_win_config はトグルのたびに screen サイズから再計算するため、
          -- ターミナルをリサイズしても常に中央に表示される
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
            -- フロート時は float.open_win_config の width が使われるが、
            -- nvim-tree が内部的に view.width を参照する箇所と整合させる
            width = function()
              return math.floor(vim.opt.columns:get() * 0.7)
            end,
          },
          git = {
            enable = true,  -- git関連の情報を有効にする
            ignore = false, --.gitignore対象のファイルも表示する
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
            }
          },
          -- ライブフィルタ(`f`キー)の挙動
          -- always_show_folders = false にすると、フィルタに一致しない兄弟ディレクトリを
          -- 非表示にできる。マッチしたノードに至るパス上のフォルダのみ残るため、
          -- telescope風にノイズの少ない絞り込み結果になる
          live_filter = {
            prefix = "[FILTER]: ",
            always_show_folders = false,
          },
          -- レンダラー設定
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
          -- ファイル操作の設定
          actions = {
            open_file = {
              quit_on_open = true, -- ファイルを開いてもツリーを閉じない
            },
          },
        })
      end
    },
    -- claude
    {
      "coder/claudecode.nvim",
      requires = { "folke/snacks.nvim" },
      config = function()
        require("claudecode").setup({
          -- 全体: リアルタイム選択トラッキングを無効化してカーソル遅延を回避する
          -- 詳細: 選択送信は手動コマンド側で範囲を直接送るため、追跡は不要
          track_selection = false,
          -- もしvisual modeの入力時の問題が続くようであれば以下のコメントアウトを解除して設定を有効化しチューニングする
          visual_demotion_delay_ms = 100,
          log_level = "warn",
          -- 全体: claude codeターミナル固有のキーマップ設定
          -- 詳細: snacks.nvimのターミナルウィンドウオプションを通じて設定
          -- 注意: 他の必須フィールドはプラグイン内部でデフォルト値とマージされる
          ---@diagnostic disable-next-line: missing-fields
          terminal = {
            snacks_win_opts = {
              -- 全体: 表示はプラグインデフォルト(右側 30% の vsplit)に任せる。
              --       幅の動的変更は lua/claude.lua の cycle_claude_width(<M-w>) で行う。
              keys = {
                -- 全体: Control-Dを無効化して誤終了を防ぐ
                -- 詳細: ターミナルモードでControl-Dを押すとEOFシグナルが送信されclaude codeが終了するため、
                --       テキスト入力中の削除操作と誤って押してしまう問題を回避する
                -- disable_ctrl_d = {
                --   "<C-d>",
                --   function() end, -- 何もしない
                --   mode = "t",
                --   desc = "Disable Ctrl-D (prevent accidental close)",
                -- },
              },
            },
          },
        })
      end,
    },
    -- obsidian
    {
      "obsidian-nvim/obsidian.nvim",
      -- markdownファイルを開いた時に読み込む
      -- cmd だと wiki link補完やUI装飾が手動コマンド実行まで無効になるため ft を使用
      ft = { 'markdown' },
      config = function()
        local obsidian_valut_path = "/Users/take/Documents/obsidian"
        require("obsidian").setup({
          -- 旧コマンド形式(ObsidianXxx)を無効化し、新形式(Obsidian xxx)のみ使用する
          legacy_commands = false,
          -- 全体: markdownの見た目(チェックボックス/箇条書き/conceal等)の描画は
          --       render-markdown.nvim に一本化する
          -- 詳細: obsidian.nvimもデフォルトで同種のUI描画を行うため、両方有効だと
          --       描画が二重になりアイコンとテキストの位置がずれる
          --       (例: "- [ ] test" が "- [ ] st" のように先頭文字が隠れる)。
          --       そのためobsidian側のUI描画を無効化して競合を避ける。
          ui = { enable = false },
          workspaces = {
            {
              name = "personal",
              path = obsidian_valut_path,
              ---@diagnostic disable-next-line: missing-fields
              overrides = {
                notes_subdir = "inbox",
              },
            }
          },
          daily_notes = {
            folder = "daily",
            template = obsidian_valut_path .. '/template/frontmatter.md'
          },
          ---@diagnostic disable-next-line: missing-fields
          templates = {
            enabled = true,
            folder = "template",
          },
          frontmatter = {
            enabled = function (path)
             local excluded_dir = vim.fs.normalize(obsidian_valut_path .. "/blogs/articles")
             -- ファイルパスも標準化
             path = vim.fs.normalize(path)
             if path:sub(1, #excluded_dir) == excluded_dir then
               return true -- Zenn記事ではfrontmatterを無効化
             end
             return false  -- それ以外のファイルではfrontmatterを有効化
            end
          },
          note_id_func = function(title)
            if title ~= nil then
              return title
            end
            return tostring(os.time())
          end,
        })
      end
    },
    -- harpoon: よく使うファイルをピンして1キーで切り替える
    {
      "ThePrimeagen/harpoon",
      branch = "harpoon2",
      requires = { "nvim-lua/plenary.nvim" },
    },
    -- completion
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'saadparwaiz1/cmp_luasnip',
    -- 辞書補完: 一般的な英単語をnvim-cmpの候補として自動表示する
    -- 全体構成: 起動時に辞書ファイルを読み込み → trieにインデックス → prefix検索で候補返却
    -- 詳細: 辞書ファイルは aspell から生成する(nvim/dict_setup.sh 参照)
    'uga-rosa/cmp-dictionary',
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = function()
        require("nvim-autopairs").setup {}
      end
    },
    {
      'MeanderingProgrammer/render-markdown.nvim',
      after = { 'nvim-treesitter' },
      requires = { 'nvim-tree/nvim-web-devicons', opt = true }, -- if you prefer nvim-web-devicons
      config = function()
        -- 全体: 完了済みTODOを未完了と一目で区別できるようにする
        -- 詳細: render-markdown.nvim のデフォルトはアイコンの色しか変わらず、
        --       チェック済みタスクのテキストが未完了と同じ見た目で判別しにくい。
        --       そこで完了タスク行全体に当てる専用ハイライト(取り消し線+グレー)を
        --       定義し、checkbox.checked.scope_highlight に指定する。
        vim.api.nvim_set_hl(0, 'RenderMarkdownCheckedScope', {
          fg = '#6c7086', -- グレーアウト。カラースキームに合わせて調整可
          strikethrough = true,
        })
        require('render-markdown').setup({
          checkbox = {
            checked = {
              -- 枠なしの太いチェックマーク。セル内の余白が少なく大きく見えるため、
              -- 未チェックの枠アイコンとの対比で完了状態が判別しやすい
              icon = '󰄬 ',
              highlight = 'RenderMarkdownChecked',
              -- 完了タスクのテキスト全体を取り消し線+グレーで弱める
              scope_highlight = 'RenderMarkdownCheckedScope',
            },
            unchecked = {
              -- 幾何学記号の四角。Nerd Fontの枠アイコン(余白が大きい)より
              -- 枠線がセル端近くまで描かれるため大きく見える
              icon = '□ ',
              highlight = 'RenderMarkdownUnchecked',
            },
          },
          -- 全体: コードブロックを本文から見分けやすくする
          -- 詳細: 「本文との区別(背景+境界線)」「言語の明示(ヘッダ)」「範囲の明示(余白)」
          --       の3点で可読性を上げる。背景色はカラースキームの RenderMarkdownCode を尊重する。
          code = {
            -- 言語アイコン+名前のヘッダと背景の両方を表示
            style = 'full',
            -- 言語名・アイコンをブロック左上に表示
            position = 'left',
            -- 背景をコード内容の幅に合わせる(行末まで間延びさせない)
            width = 'block',
            -- 短いブロックでも最低幅を確保し、ヘッダが潰れないようにする
            min_width = 40,
            -- 上下に境界線を描いてブロックの範囲を明示する
            border = 'thick',
            -- ブロック内側の左右余白。コードが枠に接しないようにする
            left_pad = 2,
            right_pad = 2,
            -- 左の sign 列に言語アイコンを表示
            sign = true,
          },
        })
      end,
    },
  }
end

-- 初回実行時のみ plugin のinstallを呼び出す関数
if not vim.g.__pckr_initialized then
  setup_plugins();
  vim.g.__pckr_initialized = true;
end

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
