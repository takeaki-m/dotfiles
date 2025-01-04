vim.api.nvim_create_user_command('CopyFullBufferPath', "let @+=expand('%:p')", {})
vim.api.nvim_create_user_command('CopyBufferName', "let @* = expand('%:t')",{})

