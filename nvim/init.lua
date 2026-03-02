-- activate vim loader to use plugin manager
-- set file top to enable module cachs
vim.loader.enable()
require("command")
require("keymaps")
require("options")
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
            lualine_c = { 'filename' },
            lualine_x = { 'filetype' },     -- encoding formatを削除
            lualine_y = {},                 -- progressを削除
            lualine_z = { 'location' }
          }
        }
      end
    },
    'kdheepak/lazygit.nvim',
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
      "stevearc/aerial.nvim",
      config = function()
        require("aerial").setup()
        -- telescope拡張はaerial初期化後に読み込む
        require("telescope").load_extension("aerial")
      end
    },
    {
      'linrongbin16/gitlinker.nvim',
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
      requires = {
        'nvim-tree/nvim-web-devicons', -- icons
      },
      config = function()
        local function nvim_tree_attach(bufnr)
          local api = require "nvim-tree.api"
          local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end
          -- default mappings
          api.config.mappings.default_on_attach(bufnr)
          -- nvim-tree固有のcustom mappings
          vim.keymap.set('n', 'l', api.node.open.edit, opts('Open'))
          vim.keymap.set('n', 'h', api.node.open.edit, opts('Close'))
        end
        require("nvim-tree").setup({
          on_attach = nvim_tree_attach,
          -- git 統合を有効化
          view = {
            width = 50,
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
            }
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
              quit_on_open = false, -- ファイルを開いてもツリーを閉じない
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
      "epwalsh/obsidian.nvim",
      requires = "nvim-lua/plenary.nvim",
      config = function()
        local obsidian_valut_path = "/Users/take/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian"
        require("obsidian").setup({
          workspaces = {
            {
              name = "personal",
              path = obsidian_valut_path
            }
          },
          overrides = {
            notes_subdir = "inbox",
          },
          daily_notes = {
            folder = "daily",
            template = obsidian_valut_path .. '/template/frontmatter.md'
          },
          templates = {
            folder = "template",
          },
          disable_frontmatter = function(path)
            -- path: 現在書き込もうとするファイルのパス
            -- zennに連携するディレクトでは、frontmatterを無効化する
            local excluded_dir = vim.fs.normalize(obsidian_valut_path .. "/blogs/articles")
            -- ファイルパスも標準化
            path = vim.fs.normalize(path)
            if path:sub(1, #excluded_dir) == excluded_dir then
              return true -- Zenn記事ではfrontmatterを無効化
            end
            return false  -- それ以外のファイルではfrontmatterを有効化
          end,
        })
      end
    },
    -- completion
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'saadparwaiz1/cmp_luasnip',
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = function()
        require("nvim-autopairs").setup {}
      end
    },
    -- colortheme
    "folke/tokyonight.nvim",
    "rebelot/kanagawa.nvim",
    "EdenEast/nightfox.nvim",
    "neanias/everforest-nvim",
  }
end

-- 初回実行時のみ plugin のinstallを呼び出す関数
if not vim.g.__pckr_initialized then
  setup_plugins();
  vim.g.__pckr_initialized = true;
end

-- colorschemaの設定は初期化後に次に定義する必要あり。
require("colorscheme")
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
  }, {
    { name = "buffer" },
  })
})
