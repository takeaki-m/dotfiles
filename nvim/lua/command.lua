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

vim.api.nvim_create_user_command("CopySelectedRangeLines", function ()
  -- 現在のファイルの絶対ぱすをカレントディレクトリからの相対パスに変換
  local path = vim.fn.expand("%:p:.")
  -- カーソル位置の行番号と、ヴィジュアルモード開始位置の行番号
  local s, e = vim.fn.line("."), vim.fn.line("v")

  -- 選択方向によって、s>eになりうるので、常に小さい方をsにswap
  if s > e then s, e = e, s end
  local lines = s .. "-" .. e
  local copied = path .. "#L" .. lines
  vim.fn.setreg("+", copied)
  vim.notify('Range Copied "' .. copied .. '" to the clipboard!')
end, { range = true})
