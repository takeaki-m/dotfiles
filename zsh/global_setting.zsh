

# PROMPT='%n@%m %~ %# '
PROMPT='%~ %# '
# ディレクトリ移動
setopt auto_pushd #自動的にディレクトリスタックに追加
setopt pushd_ignore_dups #ディレクトリスタックに重複したディレクトリを追加しない
dirstacksize=20 #ディレクトリスタックの上限数を20に

# path名展開
set glob_complete #マッチしたパスを一つずつ挿入
unset case_glob #globeを大文字小文字を区別しない

# correct spell miss
setopt correct  # スペルミスを修正する
setopt correct_all #コマンドライン引数の全てのスペルミスを修正

# 入力補完
autoload -Uz compinit && compinit

# git
# git show branch name on terminal
source ~/.zsh/git-prompt.sh
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit

# github cli completion
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  autoload -Uz compinit
  compinit
fi

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
    local selected_dir=$(find ~ -maxdepth 1 | grep netrc_ | peco --query "$LBUFFER")
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

alias vim='nvim'

alias g='git'
alias gpoc='git push origin `git rev-parse --abbrev-ref HEAD` | gpb'
alias gpb='git log --oneline | head -1 | awk '\''{print $2" "$3}'\'' | sed -e '\''s/\r\n//g'\'' | pbcopy'
alias gupdev='g fetch origin; g co develop; g pull'
alias gmd='gupdev; g co - ; g merge develop'

alias d='docker'
alias dc='docker compose'

alias gupdev='g co develop; g pull'
alias szs='source ~/.zshrc'
alias gpb='git log --oneline | head -1 | awk '\''{print $2" "$3}'\'' | sed -e '\''s/\r\n//g'\'' | pbcopy'


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
autoload -Uz compinit
compinit
zstyle ':completion:*:default' menu select=1

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \ /user/sbin /usr/bin /bin /usr/X11R6/bin
fpath=(/usr/local/share/zsh-completions $fpath)

# ssh 接続で背景を変更する
function ssh() {
    # tmux起動時
    if [[ -n $(printenv TMUX) ]] ; then
        # 現在のペインIDを記録
        local pane_id=$(tmux display -p '#{pane_id}')
        # 接続先ホスト名に応じて背景色を切り替え
        # if [[ `echo $1 | grep 'prd'` ]] ; then
        #     tmux select-pane -P 'bg=colour52,fg=white'
        # elif [[ `echo $1 | grep 'stg'` ]] ; then
        #     tmux select-pane -P 'bg=colour25,fg=white'
        # fi
        # tmux select-pane -P 'bg=colour58,fg=white'

        tmux select-pane -P 'bg=colour52,fg=white'

        # 通常通りssh続行
        command ssh $@

      # デフォルトの背景色に戻す
      tmux select-pane -t $pane_id -P 'default'
  else
      command ssh $@
  fi
}

