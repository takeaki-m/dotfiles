vim.api.nvim_create_user_command('CopyFullBufferPath', "let @+=expand('%:p')", {})
vim.api.nvim_create_user_command('CopyBufferName', "let @* = expand('%:t')", {})
vim.api.nvim_create_user_command('IndentMarkdownList', "let @* = expand('%:t')", {})

-- Markdownリストのインデントを2スペースから4スペースに変換するコマンド
-- ユーザーが ':IndentMarkdownList c' のように 'c' オプションを追加可能
vim.api.nvim_create_user_command(
  'IndentMarkdownList', -- コマンド名
  function(opts)
    -- `string.format` に渡す前に、VimLの正規表現におけるバックスラッシュをエスケープ
    -- Luaの文字列内では、バックスラッシュは `\\` と書く必要がある
    -- 正規表現中の `\(` や `\)` は VimL の正規表現であり、Luaの `string.format` が直接解釈すべきではない
    -- %d,%ds/\( \+\)\(\*\s\)/\\1  \\2/gc
    -- この部分を文字列として構築する
    local regex_pattern = '^\\(\\s\\{2\\}\\)\\%([*\\-]\\s\\)' -- 検索パターン
    local replacement_pattern = '\\1  \\2'                    -- 置換パターン

    -- opts.args に 'c' が含まれている場合は 'c' を追加する
    local confirm_option = ''
    if opts.args and string.find(opts.args, 'c') then
      confirm_option = 'c'
    end

    -- cmd は VimL のコマンド文字列として構築される
    -- string.format は %d, %s などの書式指定子のみを解釈する
    local cmd = string.format('%d,%d%s/%s/%s/g%s',
      opts.line1,
      opts.line2,
      's', -- substituteコマンド
      regex_pattern,
      replacement_pattern,
      confirm_option)

    vim.cmd(cmd) -- VimLコマンドを実行
  end,
  {
    range = true,
    nargs = '*',
    desc = 'Markdownリストのインデントを2スペースから4スペースに変換'
  }
)

-- 2つのターミナルを左右に並べて開き、それぞれにコマンドを送信する
-- :term コマンドは非同期で実行されるため、直後に vim.b.terminal_job_id を取得すると
-- nil になる場合がある。jobstart({ term = true }) は同期的に job_id を返すため安定する
local function open_dual_terminals(cmd1, cmd2)
  -- 新規tabを作成
  vim.cmd('tabnew')
  -- jobstart with term=true でターミナルを起動し、job_id を直接取得
  -- vim.fn.termopen は非推奨のため jobstart を使用
  local job1 = vim.fn.jobstart(vim.o.shell, { term = true })
  -- 垂直分割して新しいウィンドウを作成
  vim.cmd('vsplit')
  -- 新しい空バッファを作成（jobstart は現在のバッファを使用するため必要）
  vim.cmd('enew')
  local job2 = vim.fn.jobstart(vim.o.shell, { term = true })
  -- シェルが起動完了するのを待ってからコマンドを送信
  -- 即座に送信するとシェルが準備できておらずコマンドが無視される場合がある
  vim.defer_fn(function()
    if cmd1 and job1 then
      vim.api.nvim_chan_send(job1, cmd1 .. "\n")
    end
    if cmd2 and job2 then
      vim.api.nvim_chan_send(job2, cmd2 .. "\n")
    end
  end, 100) -- 100ms 待機
  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('RunDual', function (opts)
  local args = vim.split(opts.args, " ")
  local cmd1 = args[1] or "echo 'No command 1'"
  local cmd2 = args[2] or "echo 'No command 2'"
  open_dual_terminals(cmd1, cmd2)
end, { nargs = '*' }) -- 引数の指定を許可


-- フロントエンドとバックエンドの開発サーバーを同時に起動するコマンド
-- backend:dev は OPENAI_API_KEY が必要なため、事前に set_openai を呼び出す
vim.api.nvim_create_user_command('RunApps', function (opts)
  local args = vim.split(opts.args, " ")
  local cmd1 = args[1] or "set_openai && pnpm run backend:dev"
  local cmd2 = args[2] or "pnpm run frontend:dev"
  open_dual_terminals(cmd1, cmd2)
end, { nargs = '*' }) -- 引数の指定を許可

vim.api.nvim_create_user_command("CopySelectedRangeLines", function (opts)
  -- 現在のファイルの絶対ぱすをカレントディレクトリからの相対パスに変換
  local path = vim.fn.expand("%:p:.")
  -- カーソル位置の開始行番号と、ヴィジュアルモード終了位置の行番号
  local s, e = opts.line1, opts.line2
  -- visualの選択方向に関係なく、開始行と終了行は固定されるためswapなどの処理不要
  local lines = s .. "-" .. e
  local copied = path .. "#L" .. lines
  vim.fn.setreg("+", copied)
  vim.notify('Range Copied "' .. copied .. '" to the clipboard!')
end, { range = true})

-- コマンドの出力をクリップボードにコピーするユーザーコマンド :CopyCmd
vim.api.nvim_create_user_command("CopyCmd", function(opts)
  local output = vim.api.nvim_exec2(opts.args, { output = true }).output
  vim.fn.setreg('+', output)
  print("Copied to clipboard!")
end, { nargs = 1, complete = 'command'}
)

-- 全体: lazygitを通常バッファ（:term）として起動するコマンド
-- 背景: :LazyGit はfloating windowで開くため、他のバッファと並べて表示できない
--       :term lazygit は非インタラクティブシェル経由のため .zshrc のテーマ設定関数が読み込まれない
-- 解決: options.lua で設定済みの vim.g.lazygit_config_file_path を利用して
--       --use-config-file 付きで :term 起動することで、テーマ適用 + 通常バッファの両立を実現
vim.api.nvim_create_user_command("LazyGitBuf", function()
  local config_paths = vim.g.lazygit_config_file_path
  if not config_paths or #config_paths == 0 then
    -- フォールバック: 設定未読込の場合は素のlazygitを起動
    vim.cmd("term lazygit")
    return
  end
  -- テーブルをカンマ区切りの文字列に結合
  local config_arg = table.concat(config_paths, ",")
  vim.cmd('term lazygit --use-config-file="' .. config_arg .. '"')
end, { desc = "lazygitを通常バッファとして起動（テーマ設定付き）" })

vim.api.nvim_create_user_command("CodeBlock", function (opts)
  -- カーソル位置の行番号と、ヴィジュアルモード開始位置の行番号
  local s, e = opts.line1, opts.line2
  -- range = trueにより、常に s<=e が保証されるため, swapの操作不要
  -- 先に上の行を挿入すると下の行がずれるため、先に下の行を挿入する
  vim.fn.append(e, "```")
  vim.fn.append(s - 1, "```")
end, { range = true})

-- =============================================================================
-- 全体構成: 自分で定義したキーマップだけ / それ以外(デフォルト/プラグイン)だけを
--           Telescope で一覧表示するカスタムピッカー
--
-- 背景:
--   :Telescope keymaps は登録された全マッピングを表示するため、
--   自分のカスタム定義とNeovim/プラグインのデフォルトが混在して目的のキーを探しづらい。
--
-- 仕組み:
--   1. vim.api.nvim_get_keymap(mode) で登録済みマッピングと sid (script ID) を取得
--   2. vim.fn.getscriptinfo({sid=...}) で sid を実ファイルパスへ解決
--   3. パスが ユーザー設定ディレクトリ (vim.fn.stdpath("config") 配下、または
--      symlink 解決後のパス) であれば「ユーザー定義」と判定
--   4. only_custom 引数で表示対象を切り替えて Telescope ピッカーへ流し込む
--
-- 操作:
--   <CR> で選択したキーマップが定義されているファイル/行にジャンプする。
-- =============================================================================
local function open_keymaps_picker(only_custom)
  -- pckrのcmd遅延読み込み対応:
  --  init.luaで telescope は cmd = { 'Telescope' } として登録されており、
  --  :Telescope系コマンドが一度も叩かれていない状態では rtp に追加されていない。
  --  本コマンドはユーザー定義名 (:MyKeymaps / :DefaultKeymaps) のため遅延発火しないので、
  --  pcall で明示的にロードを試みる(既にロード済みなら何もしないので副作用なし)。
  if not package.loaded["telescope.pickers"] then
    pcall(vim.cmd, "Pckr load telescope.nvim")
  end
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  -- ユーザー定義判定の基準ディレクトリ
  --   user_root          : vim.fn.stdpath("config") (通常 ~/.config/nvim)
  --   user_root_resolved : symlinkを解決した実体パス (例: ~/settings/dotfiles/nvim)
  -- dotfilesをsymlink運用しているとscriptパスは実体側で記録されるため、両方候補に含める。
  local user_root = vim.fn.stdpath("config")
  local user_root_resolved = vim.fn.resolve(user_root)
  local function is_user_path(path)
    if not path or path == "" then return false end
    return path:find(user_root, 1, true) ~= nil
        or path:find(user_root_resolved, 1, true) ~= nil
  end

  -- 対象とするマッピングモード
  -- n=normal, i=insert, v=visual+select, x=visual, s=select, t=terminal, c=cmdline, o=operator-pending
  local modes = { "n", "i", "v", "x", "s", "t", "c", "o" }

  local results = {}
  for _, mode in ipairs(modes) do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      -- sid から定義スクリプトのパスを解決
      -- sid が無い / 0 以下のものはユーザースクリプト由来ではないとみなす
      local path = ""
      if m.sid and m.sid > 0 then
        local info = vim.fn.getscriptinfo({ sid = m.sid })
        if info and info[1] then path = info[1].name end
      end
      local is_user = is_user_path(path)
      if (only_custom and is_user) or (not only_custom and not is_user) then
        -- rhs はLuaコールバック定義の場合、空文字列または nil になるため別表示にする
        local rhs_str
        if type(m.rhs) == "string" and m.rhs ~= "" then
          rhs_str = m.rhs
        elseif m.callback then
          rhs_str = "<lua callback>"
        else
          rhs_str = ""
        end
        table.insert(results, {
          mode = mode,
          lhs = m.lhs,
          rhs = rhs_str,
          desc = m.desc or "",
          path = path,
          lnum = m.lnum or 0,
        })
      end
    end
  end

  pickers.new({}, {
    prompt_title = only_custom and "Custom Keymaps (user defined)" or "Default / Plugin Keymaps",
    finder = finders.new_table({
      results = results,
      entry_maker = function(e)
        -- desc があれば優先表示、無ければ rhs を表示。末尾にファイル位置を付与
        local label = e.desc ~= "" and e.desc or e.rhs
        local display = string.format("[%s] %-22s %-45s | %s:%d",
          e.mode, e.lhs, label, e.path, e.lnum)
        -- ordinalにmode/lhs/desc/pathを全て含めて、どの観点でも絞り込めるようにする
        local ordinal = table.concat({ e.mode, e.lhs, e.desc, e.rhs, e.path }, " ")
        return { value = e, display = display, ordinal = ordinal }
      end,
    }),
    sorter = conf.generic_sorter({}),
    -- <CR>: 選択したキーマップが定義されたファイルの該当行にジャンプ
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and entry.value and entry.value.path ~= "" then
          local lnum = entry.value.lnum > 0 and entry.value.lnum or 1
          vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(entry.value.path))
        end
      end)
      return true
    end,
  }):find()
end

vim.api.nvim_create_user_command("MyKeymaps", function() open_keymaps_picker(true) end,
  { desc = "ユーザー設定ディレクトリ由来のキーマップだけをTelescopeで一覧表示" })
vim.api.nvim_create_user_command("DefaultKeymaps", function() open_keymaps_picker(false) end,
  { desc = "ユーザー定義以外(デフォルト/プラグイン)のキーマップをTelescopeで一覧表示" })
