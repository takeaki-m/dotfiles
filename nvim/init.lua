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
      'nvim-treesitter/nvim-treesitter',
      config = function()
        require("nvim-treesitter").setup()
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
    -- nvim-treesitter-textobjects: treesitterの構文木を利用してコード構造単位で選択・移動する
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      config = function()
        require("nvim-treesitter.configs").setup({
          -- treesitter本体の設定（型定義の必須フィールド）
          modules = {},
          sync_install = false,
          ensure_installed = {},
          ignore_install = {},
          auto_install = false,
          textobjects = {
            -- コード構造単位で選択する（visual/operatorモード）
            -- af: 関数全体, if: 関数内部, aa: 引数全体, ia: 引数内部
            select = {
              enable = true,
              lookahead = true,  -- カーソル前方のオブジェクトも対象にする
              keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["aa"] = "@parameter.outer",
                ["ia"] = "@parameter.inner",
              },
            },
            -- コード構造単位でカーソル移動する
            -- ]f: 次の関数先頭, [f: 前の関数先頭
            move = {
              enable = true,
              set_jumps = true,  -- ジャンプリストに記録する
              goto_next_start = {
                ["]f"] = "@function.outer",
              },
              goto_previous_start = {
                ["[f"] = "@function.outer",
              },
            },
          },
        })
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
          }
        })
        -- 2. キーマッピング (vim.keymap.set を使用)
        -- Normal mode (n) と Terminal mode (t) の両方でトグルできるようにする
        vim.keymap.set({ "n", "t" }, "<C-\\>", function()
          snacks.terminal.toggle()
        end, { desc = "Toggle Terminal" })
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
        require('render-markdown').setup({})
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
