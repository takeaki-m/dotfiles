require("command")
require("keymaps")
require("options")
require("lsp")
require("claude")

-- activate vim loader to use plugin manager
vim.loader.enable()

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

require('pckr').add {
  'nvim-treesitter/nvim-treesitter',
  'nvim-lua/plenary.nvim',
  'nvim-telescope/telescope.nvim',
  'lewis6991/gitsigns.nvim',
  'nvim-lualine/lualine.nvim',
  'kdheepak/lazygit.nvim',
  'neovim/nvim-lspconfig',
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',
  'L3MON4D3/LuaSnip',
  'kylechui/nvim-surround',
  'ixru/nvim-markdown',
  'folke/lazydev.nvim',            -- luaのcompletionにnvimの設定を読み込ませる
  'numToStr/Comment.nvim',
  'lukas-reineke/indent-blankline.nvim',
  "stevearc/aerial.nvim",
  'linrongbin16/gitlinker.nvim',
  {
    "pwntester/octo.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      -- OR "ibhagwan/fzf-lua",
      -- OR "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  },
  -- filer
  {
    'nvim-tree/nvim-tree.lua',
    requires ={
      'nvim-tree/nvim-web-devicons',   -- icons
    },
  },
  -- markdown
  {
    'iamcco/markdown-preview.nvim',
    build = 'cd app && npm install',
    config = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_auto_start = 0
    end,
    ft = { 'markdown', 'md' },
  },
  -- claude
  {
    "coder/claudecode.nvim",
    requires = { "folke/snacks.nvim" },
    -- commented out
    --config = true,
    opt = {
      terminal_cmd = "/opt/homebrew/bin/claude",
    },
  },
  -- obsidian
  {
      "epwalsh/obsidian.nvim",
      requires = "nvim-lua/plenary.nvim",
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

require("claudecode").setup()
require("colorscheme")
-- luaのlsp server(lua_ls)が、vim関連の関数を認識できるように、他のライブラリよりも優先的に読み込む
require("lazydev").setup()
-- nvim-surround
require("nvim-surround").setup()
-- activate indent-blankline.nvim
--require('ibl').setup()
require('lualine').setup {
  options = {
    icons_enabled = false, --アイコンを無効にする
    theme = 'auto',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { '' },
    lualine_c = { 'filename' },
    lualine_x = { 'filetype' }, -- encoding formatを削除
    lualine_y = { }, -- progressを削除
    lualine_z = { 'location' }
  },
}
-- lsp
require("mason").setup()
-- common conf for all language server
vim.lsp.config('*', {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

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

-- lspconfig で LSP サーバーを設定
-- mason-lspconfig は lspconfig と連携して、インストールされた LSP サーバーを自動的に設定します。
-- 個別のLSPサーバーの設定は lspconfig を通して行います。

-- lua_ls の設定例
vim.lsp.enable('lua_ls')
-- marksman の設定
vim.lsp.enable('marksman')
vim.lsp.enable('terraformls')
vim.lsp.enable('ts_ls')
vim.lsp.enable('biome')
vim.lsp.enable('gh_actions_ls')
vim.lsp.enable('tailwindcss')
vim.lsp.enable('postgres_lsp')
-- lua language severに対して、'vim'はglobal変数なので警告しないように設定
-- lua language serverは通常のLua環境を前提としているため、vimという変数を未定義として警告するから
vim.lsp.config.lua_ls = {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
}

-- 過去にdebugした際に以下設定したが不要と思われるのでコメントアウトする。しばらくして問題なければ削除する
--lspconfig.terraformls.setup({
--  settings = { terraform = { logLevel = "DEBUG", } } })
-- LSP設定後に追加 (cmpの設定)
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
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  })
})
require("nvim-web-devicons").setup()
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
        ["<C-c>"] = "close",
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
require("telescope").load_extension("aerial")

require('Comment').setup()
require('ibl').setup()

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
  disable_frontmatter = function (path)
    -- path: 現在書き込もうとするファイルのパス
    -- zennに連携するディレクトでは、frontmatterを無効化する
    local excluded_dir = vim.fs.normalize(obsidian_valut_path .. "/blogs/articles")
    -- ファイルパスも標準化
    path = vim.fs.normalize(path)

    if path:sub(1, #excluded_dir) == excluded_dir then
      return true -- Zenn記事ではfrontmatterを無効化
    end
      return false -- それ以外のファイルではfrontmatterを有効化
  end,
})

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
      quit_on_open = false,  -- ファイルを開いてもツリーを閉じない
    },
  },
})
require("nvim-treesitter").setup()
require("aerial").setup()
require("gitlinker").setup()
require("octo").setup({
  picker = "telescope",
})
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
    end, {expr=true, desc = "Next git hunk"})

    map('n', '[c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, {expr=true, desc = "Previous git hunk"})
    -- 対象行の変更内容をフロートウィンドウで見る
    map('n', '<leader>hp', gs.preview_hunk, { desc = "Preview git hunk" })
  end
}
