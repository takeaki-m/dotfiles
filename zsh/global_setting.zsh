

# PROMPT='%n@%m %~ %# '
PROMPT='%~ %# '
# ディレクトリ移動
setopt AUTO_PUSHD #自動的にディレクトリスタックに追加
setopt pushd_ignore_dups #ディレクトリスタックに重複したディレクトリを追加しない
DIRSTACKSIZE=20 #ディレクトリスタックの上限数を20に
# ディレクトリスタックの設定cd -<TAB>で有効化
zstyle ':completion:*' menu select
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*:descriptions' format '%BCompleting%b %U%d%u'

# path名展開
set glob_complete #マッチしたパスを一つずつ挿入
unset case_glob # globeを大文字小文字を区別しない

# correct spell miss
setopt correct  # スペルミスを修正する
setopt correct_all #コマンドライン引数の全てのスペルミスを修正

# コマンド履歴検索で戻るを実現するためにscrelln rockを未定義にする
stty stop undef

# ディレクトリスタックをcdで使えるようにする


# 入力補完
autoload -Uz compinit && compinit
# 大文字小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# git
# git show branch name on terminal
source ~/.zsh/git-prompt.sh
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git*' script ~/.zsh/git-completion.bash

# github cli completion
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
if type brew &>/dev/null
then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

    autoload -Uz compinit compinit
fi
# zsh-autocompleteのinstallによってコメントアウト
#FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
#if type brew &>/dev/null
#then
#    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
#
#    autoload -Uz compinit
#    compinit
#fi
#
## ghqとの連携。ghqの管理化にあるリポジトリを一覧表示する。ctrl - ]にバインド。
function peco-src () {
  local selected_dir=$(ghq list -p | peco --prompt="repositories >" --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src

## prompt options
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWNUPSTREAMS=true

## prompt showing settings
setopt PROMPT_SUBST ; PS1='%F{blue}%~%f %F{cyan}$(__git_ps1 "(%s)")%f
\$ '

# change netrc account
function change-codecommit-credential() {
    local selected_dir=$(find ~/netrc -mindepth 1 -maxdepth 1 | peco --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        \cp -f ${selected_dir} ~/.netrc
    fi
    echo '----------------------------------------'
    echo 'view current "~/.netrc" settings'
    echo '----------------------------------------'
    sed -n 1,3p ~/.netrc
}
alias ccc='change-codecommit-credential'


# Definition for alias
# aliases
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias ls='ls -G'
alias ll='ls -l'
alias la='ls -la'
alias rf='readlink -f'
alias beep='afplay /System/Library/Sounds/Ping.aiff'
# edit clipboard contents with vim
alias cv='vim +"put +"'

# set xterm to TERM for older terminals that does not support xterm-256color
alias term='export TERM=xterm; echo $TERM'

alias vim='nvim'
alias v='vim'

alias g='git'
alias gpoc='git push origin `git rev-parse --abbrev-ref HEAD` | gpb'
alias gpb='git log --oneline | head -1 | awk '\''{print $2" "$3}'\'' | sed -e '\''s/\r\n//g'\'' | pbcopy'
alias gupdev='g fetch origin; g co develop; g pull'
alias gmd='gupdev; g co - ; g merge develop'
alias gbrmd='git branch -d `git branch --merged`'
alias gpr='gh pr create'

alias d='docker'
alias dc='docker compose'

alias szs='source ~/.zshrc'
alias reload='exec $SHELL -l'
alias tm='tmux'
alias brew_update='brew update && brew upgrade && brew cleanup'
alias reader='/usr/bin/open -a Safari `pbpaste`'

pycharm() {
  open -na "Pycharm.app" --args nosplash "$@"
}

webstorm() {
  open -na "WebStorm.app" --args nosplash "$@"
}

idea() {
  open -na "IntelliJ IDEA.app" --args nosplash "$@"
}

#
# nvim
alias nvimconfig='nvim ~/.config/nvim/init.lua'
# alias v='nvim'


# カレントディレクトリのパスをコピー。末尾の改行を削除する
alias pcopy='pwd | sed "s/^\(.*\)$/'\''\1'\''/" | tr -d '\''\n'\'' | pbcopy'
# xman関数を定義
function xman() { open x-man-page://$@ ; }


# postgres
alias postgres='postgres -D /usr/local/var/postgres'

# colordiff
# installされていない環境ではcolordiffではなくdiffを利用する
if [[ -x `which colordiff` ]]; then
    alias diff='colordiff -u'
else
    alias diff='diff'
fi

# convert-windows-path-with-mac
function win-to-mac() {
    windows_path="$1"
    google_drive_path=`readlink ~/Google\ Drive`

    # convert drive letter with mac google drive path, change file paths and change space with \space
    mac_path=$(echo "$windows_path" | sed -e 's|^G:||' -e 's|\\|\/|g' -e 's| |\\ |g')
    echo "$google_drive_path$mac_path" | pbcopy
}

# Pythonの仮想環境が有効な場合には、仮想環境名を表示する

function prompt_venv() {
  if [[ -n "$VIRTUAL_ENV" && -n "$PROMPT" ]]; then
    PYTHON_VIRTUAL_ENV_STRING="(`basename $VIRTUAL_ENV`)"
  fi
}

# PROMPTにvenvの設定追加
function setprompt(){
  PROMPT="${PYTHON_VIRTUAL_ENV_STRING}${PROMPT}"
}


 alias uvim='vim -u essential.vim'


# take effect back command history with ctrl s
stty stop undef

# sshの背景変える方法うまくいかないからコメントアウト
# alias ssh='~/bin/ssh-change-bg'
#
# ███████╗███████╗██╗  ██╗
# ╚══███╔╝██╔════╝██║  ██║
#   ███╔╝ ███████╗███████║
#  ███╔╝  ╚════██║██╔══██║
# ███████╗███████║██║  ██║
# ╚══════╝╚══════╝╚═╝  ╚═╝

# 補完機能を有効にする
autoload -Uz compinit compinit
zstyle ':completion:*:default' menu select=1
# 前方一致
# 入力補完
#source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# zsh-autocompleteのキーバインドを変更する
bindkey              '^I'         menu-complete
bindkey "$terminfo[kcbt]" reverse-menu-complete
# zsh-autocompleteのinstallによってコメントアウト
# autoload -Uz compinit && compinit
# default
zstyle ':completion:*:default' menu select
# interactive
# zstyle ':completion:*:default' menu select interactive
#
# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \ /user/sbin /usr/bin /bin /usr/X11R6/bin
fpath=(/usr/local/share/zsh-completions $fpath)

# tmux接続時にvim keybindになる場合があるため明示的にtmux keybindとする
if [[ -n "$TMUX" ]]; then
  bindkey -e
fi

# ssh 接続で背景を変更する
function ssh() {
    # tmux起動時
    if [[ -n $(printenv TMUX) ]] ; then
        # 現在のペインIDを記録
        local pane_id=$(tmux display -p '#{pane_id}')
        #接続先ホスト名に応じて背景色を切り替え
        if [[ `echo $1 | grep 'prod'` ]] ; then
            tmux select-pane -P 'bg=colour52,fg=white'
            # tmux set-option -g status-bg "colour238"
        elif [[ `echo $1 | grep 'vl'` ]] ; then
            tmux select-pane -P 'bg=colour52,fg=white'
            # tmux set-option -g status-bg "colour238"
        # test環境はec2端末ごとに色味の違いがあり、共通して見やすい色が設定できないため適用対象外とする
        #elif [[ `echo $1 | grep 'st'` ]] ; then
            #tmux set-option -g status-bg "colour238"
            #tmux select-pane -P 'bg=gray,fg=black'
            #tmux select-pane -P 'bg=green,fg=white'
        else
            #tmux set-option -g status-bg "colour238"
            #tmux select-pane -P 'bg=green,fg=white'
        fi
        #tmux select-pane -P 'bg=colour58,fg=white'
        #tmux select-pane -P 'bg=colour52,fg=white'
        #tmux select-pane -P 'bg=colour9,fg=white'
        #tmux select-pane -P 'bg=colour182,fg=black'
        #tmux select-pane -P 'bg=palevioletred,fg=black'
        #tmux select-pane -P 'bg=darkkhaki,fg=black'
        #tmux select-pane -P 'bg=olive,fg=white'
        #tmux select-pane -P 'bg=lightsteelblue,fg=black'
        #tmux select-pane -P 'bg=lightslategray,fg=black'

       # 通常通りssh続行
        command ssh $@
      # デフォルトの背景色に戻す
      # tmux set-option -t $pane_id -g status-bg 'default'
      tmux select-pane -t $pane_id -P 'default'
  else
      command ssh $@
  fi
}
