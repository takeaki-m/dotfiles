" Source your .vimrc
source $HOME/settings/dotfiles/.ide-vimrc


" 以下は過去の設定。最近は利用しないため、全てコメントアウトする
"
" setting
" "if has('vim_starting')
" "    set nocompatible
" "endif
" "
" "if !filereadable(expand('~/.vim/autoload/plug.vim'))
" "    if !executable("curl")
" "        echoerr "You have to install curl or first install vim-plug yourself!"
" "        execute "q!"
" "    endif
" "    echo "Installing Vim-Plug..."
" "    echo ""
" "    silent !\curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" "    let g:not_finish_vimplug = "yes"
" "    autocmd VimEnter * PlugInstall
" "endif
" "
" "" plugin
" "call plug#begin(expand('~/.vim/plugged'))
" "Plug 'mattn/vim-starwars'
" """ space + ne -> sidebar
" "Plug 'scrooloose/nerdtree'
" "Plug 'jistr/vim-nerdtree-tabs'
" """ ryanoasis/vim-devicons
" "Plug 'ryanoasis/vim-devicons'
" """ ga -> align
" "Plug 'junegunn/vim-easy-align'
" """ space + qr -> exec script
" "Plug 'thinca/vim-quickrun'
" "Plug 'Shougo/vimproc.vim', {'do' : 'make'}
" """ gcc -> comment
" "Plug 'tpope/vim-commentary'
" """ option bar
" "Plug 'vim-airline/vim-airline'
" "Plug 'vim-airline/vim-airline-themes'
" """ auto bracket
" """Plug 'Raimondi/delimitMate'
" "Plug 'tpope/vim-surround'
" """ auto format
" "Plug 'Chiel92/vim-autoformat'
" """ error detect
" "Plug 'scrooloose/syntastic'
" """ delete white space
" "Plug 'bronson/vim-trailing-whitespace'
" """ auto complete
" "Plug 'sheerun/vim-polyglot'
" """ Plug 'Valloric/YouCompleteMe'
" "Plug 'ervandew/supertab'
" """ html
" "Plug 'hail2u/vim-css3-syntax'
" "Plug 'gorodinskiy/vim-coloresque'
" "Plug 'tpope/vim-haml'
" "Plug 'mattn/emmet-vim'
" """ javascript
" "Plug 'jelera/vim-javascript-syntax'
" """ php
" "Plug 'arnaud-lb/vim-php-namespace'
" """ python
" "Plug 'davidhalter/jedi-vim'
" "Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
" """ space + sh -> vimshell
" "Plug 'Shougo/vimshell.vim'
" """ snippet
" "Plug 'SirVer/ultisnips'
" "Plug 'honza/vim-snippets'
" "" install tender theme
" "Plug 'jacoborus/tender.vim'
" "
" "" ファイルオープンを便利に
" "Plug 'Shougo/unite.vim'
" "Plug 'Shougo/vimfiler'
" "Plug 'Shougo/vimproc'
" "
" "" Unite.vimで最近使ったファイルを表示できるようにする
" "Plug 'Shougo/neomru.vim'
" "
" "call plug#end()
" "filetype plugin indent on
" "let mapleader="\<Space>"
" "
" """ ultisnip
" "let g:UltiSnipsExpandTrigger="<tab>"
" "let g:UltiSnipsJumpForwardTrigger="<tab>"
" "let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
" "let g:UltiSnipsEditSplit="vertical"
" "
" """ youcompleteme
" """ let g:ycm_server_python_interpreter = '/usr/bin/python2.7'
" """ let g:ycm_python_binary_path = '/usr/bin/python2.7'
" """ let g:ycm_global_ycm_extra_conf = '~/.vim/plugged/YouCompleteMe/.ycm_extra_conf.py'
" """ let g:ycm_auto_trigger = 1
" """ let g:ycm_min_num_of_chars_for_completion = 1
" """ let g:ycm_autoclose_preview_window_after_insertion = 1
" """ let g:ycm_key_list_select_completion = ['<Down>']
" """ let g:ycm_key_list_previous_completion = ['<Up>']
" """ inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "ᐅ"
" """ let g:ycm_key_list_stop_completion = ['<C-y>', '<Enter>']
" """ let g:ycm_seed_identifiers_with_syntax = 1
" """ let g:SuperTabDefaultCompletionType = '<C-n>'
" """ let g:make = 'gmake'
" """ if exists('make')
" """     let g:make = 'make'
" """ endif
" "
" """ auto-format
" "au BufWrite * :Autoformat
" "
" """ vim-airline
" "let g:airline_theme = 'powerlineish'
" "let g:airline#extensions#syntastic#enabled = 1
" "let g:airline#extensions#branch#enabled = 1
" "let g:airline#extensions#tabline#enabled = 1
" "let g:airline#extensions#tagbar#enabled = 1
" "let g:airline_skip_empty_sections = 1
" "
" """ emmet
" "autocmd FileType html imap <buffer><expr><tab>
" "            \ emmet#isExpandable() ? "\<plug>(emmet-expand-abbr)" :
" "            \ "\<tab>"
" "
" """ nerdtree
" "let g:NERDTreeChDirMode=2
" "let g:NERDTreeIgnore=['\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
" "let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
" "let g:NERDTreeShowBookmarks=1
" "let g:nerdtree_tabs_focus_on_files=1
" "let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
" "let g:NERDTreeWinSize = 30
" "let NERDTreeShowHidden=1
" "set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite
" "nnoremap <Leader>dir :NERDTreeTabsToggle<CR>
" "autocmd BufWritePre * :FixWhitespace
" "augroup NERD
" "    au!
" "    autocmd VimEnter * NERDTree
" "    autocmd VimEnter * wincmd p
" "augroup END
" "
" """ quickrun
" "nnoremap <Leader>go :QuickRun<CR>
" "nnoremap <C-U>qr :QuickRun<CR>
" "let g:quickrun_config={'*': {'split': ''}}
" "let g:quickrun_config.cpp = {
" "            \   'command': 'g++',
" "            \   'cmdopt': '-std=c++11'
" "            \ }
" "
" """ vim-easy-align
" "xmap ga <Plug>(EasyAlign)
" "nmap ga <Plug>(EasyAlign)
" "
" """ vimshell
" """ nnoremap <Leader>sh :VimShellPop<CR>
" "nnoremap <Leader>sh :vertical terminal<CR>
" "let g:vimshell_user_prompt = 'fnamemodify(getcwd(), ":~")'
" "let g:vimshell_prompt =  '$ '
" "
" """ syntastic
" "let g:syntastic_always_populate_loc_list=1
" "let g:syntastic_error_symbol='✗'
" "let g:syntastic_warning_symbol='⚠'
" "let g:syntastic_style_error_symbol = '✗'
" "let g:syntastic_style_warning_symbol = '⚠'
" "let g:syntastic_auto_loc_list=1
" "let g:syntastic_aggregate_errors = 1
" "
" """ jedi-vim
" "let g:jedi#popup_on_dot = 0
" "let g:jedi#goto_assignments_command = "<leader>g"
" "let g:jedi#goto_definitions_command = "<leader>d"
" "let g:jedi#documentation_command = "K"
" "let g:jedi#usages_command = "<leader>n"
" "let g:jedi#rename_command = "<leader>r"
" "let g:jedi#show_call_signatures = "0"
" "let g:jedi#completions_command = "<C-Space>"
" "let g:jedi#smart_auto_mappings = 0
" "let g:jedi#force_py_version = 3
" "autocmd FileType python setlocal completeopt-=preview
" "
" """ syntastic
" "let g:syntastic_python_checkers=['python', 'flake8']
" "let g:polyglot_disabled = ['python']
" "let python_highlight_all = 1
" "
" """ vim-airline
" "let g:airline#extensions#virtualenv#enabled = 1
" "if !exists('g:airline_symbols')
" "    let g:airline_symbols = {}
" "endif
" "if !exists('g:airline_powerline_fonts')
" "    let g:airline#extensions#tabline#left_sep = ' '
" "    let g:airline#extensions#tabline#left_alt_sep = '|'
" "    let g:airline_left_sep          = '▶'
" "    let g:airline_left_alt_sep      = '»'
" "    let g:airline_right_sep         = '◀'
" "    let g:airline_right_alt_sep     = '«'
" "    let g:airline#extensions#branch#prefix     = '⤴' "➔, ➥, ⎇
" "    let g:airline#extensions#readonly#symbol   = '⊘'
" "    let g:airline#extensions#linecolumn#prefix = '¶'
" "    let g:airline#extensions#paste#symbol      = 'ρ'
" "    let g:airline_symbols.linenr    = '␊'
" "    let g:airline_symbols.branch    = '⎇'
" "    let g:airline_symbols.paste     = 'ρ'
" "    let g:airline_symbols.paste     = 'Þ'
" "    let g:airline_symbols.paste     = '∥'
" "    let g:airline_symbols.whitespace = 'Ξ'
" "else
" "    let g:airline#extensions#tabline#left_sep = ''
" "    let g:airline#extensions#tabline#left_alt_sep = ''
" "    let g:airline_left_sep = ''
" "    let g:airline_left_alt_sep = ''
" "    let g:airline_right_sep = ''
" "    let g:airline_right_alt_sep = ''
" "    let g:airline_symbols.branch = ''
" "    let g:airline_symbols.readonly = ''
" "    let g:airline_symbols.linenr = ''
" "endif
" "
" "" function
" """ xaml
" "augroup MyXML
" "    autocmd!
" "    autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
" "    autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
" "augroup END
" "
" """ The PC is fast enough, do syntax highlight syncing from start unless 200 lines
" "augroup vimrc-sync-fromstart
" "    autocmd!
" "    autocmd BufEnter * :syntax sync maxlines=200
" "augroup END
" "
" """ Remember cursor position
" "augroup vimrc-remember-cursor-position
" "    autocmd!
" "    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
" "augroup END
" "
" """ txt
" "augroup vimrc-wrapping
" "    autocmd!
" "    autocmd BufRead,BufNewFile *.txt call s:setupWrapping()
" "augroup END
" "if !exists('*s:setupWrapping')
" "    function s:setupWrapping()
" "        set wrap
" "        set wm=2
" "        set textwidth=79
" "    endfunction
" "endif
" "
" """ make/cmake
" "augroup vimrc-make-cmake
" "    autocmd!
" "    autocmd FileType make setlocal noexpandtab
" "    autocmd BufNewFile,BufRead CMakeLists.txt setlocal filetype=cmake
" "augroup END
" "
" """ python
" "augroup vimrc-python
" "    autocmd!
" "    autocmd FileType python setlocal
" "                \ formatoptions+=croq softtabstop=4
" "                \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
" "augroup END
" "
" "" shortcut leader=Space
" """ save
" "nnoremap <Leader>w :w<CR>
" "nnoremap <Leader>qqq :q!<CR>
" "nnoremap <Leader>eee :e<CR>
" "nnoremap <Leader>wq :wq<CR>
" "nnoremap <Leader>nn :noh<CR>
" "
" """ split
" "nnoremap <Leader>s :<C-u>split<CR>
" "nnoremap <Leader>v :<C-u>vsplit<CR>
" "
" """ Tabs
" "nnoremap <Tab> gt
" "nnoremap <S-Tab> gT
" "nnoremap <Leader>t :tabnew<CR>
" "
" """ ignore wrap
" "nnoremap j gj
" "nnoremap k gk
" "nnoremap <Down> gj
" "nnoremap <Up> gk
" "
" """ Sft + y => yunk to EOL
" "nnoremap Y y$
" "
" """ + => increment
" "nnoremap + <C-a>
" "
" """ - => decrement
" "nnoremap - <C-x>
" "
" """ move 15 words
" """# nmap <silent> <Tab> 15<Right>
" """# nmap <silent> <S-Tab> 15<Left>
" """# nmap <silent> ll 15<Right>
" """# nmap <silent> hh 15<Left>
" """# nmap <silent> jj 15<Down>
" """# nmap <silent> kk 15<Up>
" "
" """ pbcopy for OSX copy/paste
" "vmap <C-x> :!pbcopy<CR>
" "vmap <C-c> :w !pbcopy<CR><CR>
" "
" """ move line/word
" "nmap <C-e> $
" "nmap <C-a> 0
" "nmap <C-f> W
" "nmap <C-b> B
" "imap <C-e> <C-o>$
" "imap <C-a> <C-o>0
" "imap <C-f> <C-o>W
" "imap <C-b> <C-o>B
" "
" "" base
" "set encoding=UTF-8
" "set fileencoding=UTF-8
" "set fileencodings=UTF-8
" "set bomb
" "set binary
" "set ttyfast
" "set backspace=indent,eol,start
" "set tabstop=4
" "set softtabstop=0
" "set shiftwidth=4
" "set expandtab
" "set splitright
" "set splitbelow
" "set hidden
" "set hlsearch
" "set incsearch
" "set ignorecase
" "set smartcase
" "set nobackup
" "set noswapfile
" "set fileformats=unix,dos,mac
" "syntax on
" "set ruler
" "set number
" "set gcr=a:blinkon0
" "set scrolloff=3
" "set laststatus=2
" "set modeline
" "set modelines=10
" "set title
" "set titleold="Terminal"
" "set titlestring=%F
" "set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)\
" "set autoread
" "set noerrorbells visualbell t_vb=
" "set clipboard+=unnamed,autoselect
" "set mouse=a
" "set whichwrap=b,s,h,l,<,>,[,]
" ""
" "" settings for tender theme
" "" If you have vim >=8.0 or Neovim >=0.1.5
" "" if (has("termguicolors"))
" ""     set termguicolors
" "" endif
" "
" ""syntax enabled
" "" set background=dark
" "" colorscheme gruvbox
" "" colorscheme miramare
" "" colorscheme simple-dark
" "" colorscheme wombat256grf
" "" colorscheme tender
" "" colorscheme molokai
" "" colorscheme github
" "" colorscheme abstract
" "" colorscheme angr
" "" colorscheme challenger_deep
" "" 256_noir
" "" abstract
" "" afterglow
" "" alduin
" "" anderson
" "" angr
" "" apprentice
" "" archery
" "" atom
" "" ayu
" "" carbonized-dark
" "" carbonized-light
" "" challenger_deep
" "" deep-space
" "" deus
" "" dogrun
" "" flattened_dark
" "" flattened_light
" "" focuspoint
" "" fogbell
" "" fogbell_light
" "" fogbell_lite
" "" github
" "" gotham
" "" gotham256
" "" gruvbox
" "" happy_hacking
" "" hybrid
" "" hybrid_material
" "" hybrid_reverse
" "" iceberg
" "" jellybeans
" "" lightning
" "" lucid
" "" colorscheme lucius
" "" materialbox
" "" colorscheme meta5
" "" minimalist
" "" molokai
" "" molokayo
" "" mountaineer-grey
" "" mountaineer-light
" "" mountaineer
" "" nord
" "" oceanic_material
" "" OceanicNext
" "" OceanicNextLight
" "" one-dark
" "" one
" "" onedark
" "" orange-moon
" "" colorscheme orbital
" "" colorscheme PaperColor
" "" paramount
" "" parsec
" "" pink-moon
" "" purify
" "" pyte
" "" rakr
" "" rdark-terminal2
" "" colorscheme scheakur
" "" seoul256-light
" "" seoul256
" "" sierra
" "" snow
" "" solarized8
" "" solarized8_flat
" "" solarized8_high
" "" solarized8_low
" "" sonokai
" "" space-dark
" "" spacecamp
" "" spacecamp_lite
" "" stellarized
" "" sunbather
" "" tender
" "" termschool
" "" twilight256
" "" two-firewatch
" "" wombat256mod
" "" yellow-moon
" "" set lighline theme inside lihgtline config
" "let g:lightline = { 'colorscheme': 'tender'}
" "" set airline theme
" "" comment out for other airline theme setting
" "" let g:airline_theme = { 'colorscheme': 'tender'}
" "
" "" template
" "augroup templateGroup
" "    autocmd!
" "    autocmd BufNewFile *.html :0r ~/vim-template/t.html
" "    autocmd BufNewFile *.cpp :0r ~/vim-template/t.cpp
" "    autocmd BufNewFile *.py :0r ~/vim-template/t.py
" "augroup END
" "" snippet
" "let g:UltiSnipsSnippetDirectories=["~/vim-snippets/"]
" "" settings of devicons
" "" guifontを設定しないと文字化けになる。terminalで行ったフォントの設定と同様
" "" 公式サイトではLinuxとmacOSの設定が若干異なるが、Linuxの設定でもmacOSで問題なし
" "set guifont=Droid\ Sans\ Mono\ for\ Powerline\ Nerd\ Font\ Complete\ 12
" "
" "" フォルダアイコンを表示
" "let g:WebDevIconsNerdTreeBeforeGlyphPadding = ""
" "let g:WebDevIconsUnicodeDecorateFolderNodes = v:true
" "" after a re-source, fix syntax matching issues (concealing brackets):
" "if exists('g:loaded_webdevicons')
" "    call webdevicons#refresh()
" "endif
" "inoremap <silent> jj <ESC>
" "
" "" Split window
" "nmap ss :split<Return><C-w>w
" "nmap sv :vsplit<Return><C-w>w
" "" Move window
" "nmap <Space> <C-w>w
" "map s<left> <C-w>h
" "map s<up> <C-w>k
" "map s<down> <C-w>j
" "map s<right> <C-w>l
" "map sh <C-w>h
" "map sk <C-w>k
" "map sj <C-w>j
" "map sl <C-w>l
" "" Resize window
" "nmap <C-w><left> <C-w><
" "nmap <C-w><right> <C-w>>
" "nmap <C-w><up> <C-w>+
" "nmap <C-w><down> <C-w>-
" "
" "" VimFiler
" "nmap sf :VimFilerBufferDir<Return>
" "nmap sF :VimFilerExplorer -find<Return>
" "nmap sb :Unite buffer<Return>
" "let g:vimfiler_as_default_explorer = 1
" "let g:vimfiler_safe_mode_by_default = 0
" "let g:vimfiler_enable_auto_cd = 0
" "let g:vimfiler_tree_leaf_icon = ''
" "let g:vimfiler_tree_opened_icon = '▾'
" "let g:vimfiler_tree_closed_icon = '▸'
" "let g:vimfiler_marked_file_icon = '✓'
" "
" "" open current directory
" "nmap te :tabedit
" "" List tabs
" "nmap tl :Unite tab
" "
" "" カーソルの移動を速くする
" "set nocursorline
" "set norelativenumber
" "
" "
" "" ECSが入力された時にIMEをオフとする
" "if has('mac')
" "    set ttimeoutlen=1
" "    let g:imeoff = 'osascript -e "tell application \"System Events\" to key code 102"'
" "    augroup MyIMEGroup
" "        autocmd!
" "        autocmd InsertLeave * :call system(g:imeoff)
" "    augroup END
" "    noremap <silent> <ESC> <ESC>:call system(g:imeoff)<CR>
" "endif

