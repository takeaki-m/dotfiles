# editor
# 以下のエディタの設定でnvimを指定すると、不備があるため無効化する
# nvimの拡張機能でclaude codeのpronput入力を外部エディタで実行する機能がある。
# この機能では、EDITORに指定されているエディタが自動的に起動する。
# だが一度起動すると、claude codeの拡張機能での入力に不備が出るため、入力を無効化する
# たとえば以下の不具合など
# - nvimでterminalのinsert modeからぬけるctrl-]を押すと、文字が入力される。
# - チャット入力欄が画面の最下部から、上部に移動してしまう。またこれまでのchat履歴の上に重なるように表示される
#export EDITOR=nvim
#export CVSEDITOR="${EDITOR}"
#export SVN_EDITOR="${EDITOR}"
#export GIT_EDITOR="${EDITOR}"

# include home folder with cd command path
#export CDPATH=$HOME:$HOME/develop:$HOME/doc:/usr/local

# history
# size recorded on memory
export HISTSIZE=1000
# size recorded on record file
export SAVEHIST=1000000
export HISTFILESEIZE=1000000
# exclude dupulicate
setopt hist_ignore_dups
# record start stop 
setopt EXTENDED_HISTORY
# remove old dupulicate histroy
setopt hist_ignore_all_dups
# remove history start with space
setopt hist_ignore_space
# can edit before execute the history command
setopt hist_verify
# remove additional blanks
setopt hist_reduce_blanks
# ignore commands that are identical to old commands
setopt hist_save_no_dups
# inore history commands
setopt hist_no_store
# autommatilally toggle history when saving
setopt hist_expand
setopt share_history

# no beep
setopt no_beep

# set path to toggle mac os backsounds
export PATH=$HOME/settings/dotfiles/macos/:$PATH

# github
# to use vim with github cli
export GIT_EDITOR=nvim
# autocomplete command line
# https://formulae.brew.sh/formula/zsh-autocomplete
# https://github.com/marlonrichert/zsh-autocomplete
