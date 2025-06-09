vim.api.nvim_create_user_command('CopyFullBufferPath', "let @+=expand('%:p')", {})
vim.api.nvim_create_user_command('CopyBufferName', "let @* = expand('%:t')",{})
vim.api.nvim_create_user_command('IndentMarkdownList', "let @* = expand('%:t')",{})

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
        local replacement_pattern = '\\1  \\2' -- 置換パターン

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
