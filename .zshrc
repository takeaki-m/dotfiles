
# Definition for alias

# command
alias ll='ls -l'
alias la='ls -la'
alias lll='ls -lhtr'
alias mv='mv -iv'
alias rm='rm -iv'
alias cp='cp -iv'
# network
alias trn='traceroute -n'
alias sub16='less /Users/t.miyazawa/scripts/subnet-mask-table.txt'

# postgres
alias postgres='postgres -D /usr/local/var/postgres'

# Google Drive File Stream
alias gd='cd /Volumes/GoogleDrive/'
alias gds='cd /Volumes/GoogleDrive/共有ドライブ'
alias gdm='cd /Volumes/GoogleDrive/マイドライブ/my-private-folder'
# 今月のvimメモを開く
alias thismonth='vim /Volumes/GoogleDrive/マイドライブ/my-private-folder/2020FY/202103.md'

alias vscode='open -a "Visual Studio Code"'
alias opc='open . -a Google\ Chrome'
# カレントディレクトリのパスをコピー。末尾の改行を削除する
alias pcopy='pwd | sed "s/^\(.*\)$/'\''\1'\''/" | tr -d '\''\n'\'' | pbcopy'
# ssh接続した際にターミナルの色を変更する。シェルのアクセス先のエイリアス
# alias ssh=~/.ssh/ssh_change_prompt.sh
alias oneshot='cd /Volumes/GoogleDrive/共有ドライブ/BA_Public/Project/BtoB_請求書再発行自動化/'
alias onecits='cd /Volumes/GoogleDrive/共有ドライブ/Partner_CITS/20_プロジェクト/2019_再発行（OneShot）'
#alias npsys='cd /Users/t.tiyazawa/dev_documents/np-system-document/03_運用チーム管理ドキュメント/BA_DOCUMENT_MANAGEMENT/2.アプリケーション基盤'
#alias npnet='cd /Users/t.miyazawa/dev_documents/np-system-document/BtoC/02_基盤設計書/01_00_本番環境/CTL/論理構成図'
#
#
# function add_dic(){
# #  defaults write -g NSUserDictionaryReplacementItems -array-add {on=1;replace=$1;with=$2;}
#   $keyvalue = {on=1;replace=$1;with=$2;}
#   defaults write -g NSUserDictionaryReplacementItems -array-add $keyvalue
# }
#
# 業務関連のalias
alias stnp='open /Users/t.miyazawa/doc/btoc_doc/10.システム設計/01_基盤設計書/01_05_ST環境（AWS）/【ST環境】AWS-VPC構成図.xls'
# alias job='open /Users/t.miyazawa/dev_documents/np-system-document/01_BtoC/02_業務設計書/01_業務共通設計/02_01_02_ジョブ関連/JP1ジョブ登録シート.xls'
# alias bcsaimu='cd /Users/t.miyazawa/dev_documents/np-system-document/01_BtoC/03_システム機能設計書/債権債務管理'
# alias bckamei='cd /Users/t.miyazawa/dev_documents/np-system-document/01_BtoC/03_システム機能設計書/加盟店管理'
# alias bcnyukin='cd /Users/t.miyazawa/dev_documents/np-system-document/01_BtoC/03_システム機能設計書/入出金管理/'
# alias bbbatch='cd /Users/t.miyazawa/dev_documents/np-system-document/02_BtoB/20.システム設計/4.業務設計/BATCH'

alias wsdpw='open /Volumes/GoogleDrive/共有ドライブ/BA_Private/社内IT/01_パスワード管理/PW管理系一覧.xlsx'
#
# ██████╗  ██████╗  ██████╗
# ██╔══██╗██╔═══██╗██╔════╝
# ██║  ██║██║   ██║██║
# ██║  ██║██║   ██║██║
# ██████╔╝╚██████╔╝╚██████╗
# ╚═════╝  ╚═════╝  ╚═════╝
#
# BtoB
alias bbset='open /Users/t.miyazawa/doc/btob_doc/20.システム設計/1.DB設計/テーブル定義書\(NP_SET\).xlsx'
alias bbdoc='cd /Users/t.miyazawa/doc/btob_doc/20.システム設計'
alias bbapi='cd /Users/t.miyazawa/doc/btob_service_doc/BTOB_SVN/002_マニュアル/102_NP掛け払いAPI'
alias bbsys='cd /Users/t.miyazawa/doc/btob_doc/20.システム設計/4.業務設計'
alias bber='open /Users/t.miyazawa/doc/ope_doc/BA_DOCUMENT_MANAGEMENT/3.データベース/31.ER図\(btob：NP_SET\).xlsx'
# Btoc
alias bcset='open /Users/t.miyazawa/doc/btoc_doc/10.システム設計/02_業務設計書/02_DB設計/02_02_03_テーブル定義/05_NP_SET_テーブル定義書.xls'
alias bcauth='open /Users/t.miyazawa/doc/btoc_doc/10.システム設計/02_業務設計書/02_DB設計/02_02_03_テーブル定義/06_NP_AUTH_テーブル定義書.xls'

alias javaversion='/usr/libexec/java_home -V'
alias sqlcon='sql /nolog'

alias cdd='cd ../../../'
alias npnet='open /Users/t.miyazawa/doc/btoc_doc/10.システム設計/01_基盤設計書/01_00_本番環境/CTL/論理構成図/NP\ NW\ Diagram\ v20.1.pdf'
alias npjob='open /Users/t.miyazawa/doc/btoc_doc/10.システム設計/02_業務設計書/01_業務共通設計/02_01_02_ジョブ関連/JP1ジョブ登録シート.xls'
alias jshell='/Library/Java/JavaVirtualMachines/jdk-12.0.1.jdk/Contents/Home/bin/jshell'
# WSD
alias npnetwork='open /Volumes/GoogleDrive/共有ドライブ/WSD/001_運用資料/00_通常利用/03_ネットワーク管理/ネットワーク構成図/01_社内ネットワーク構成図_20201208.xlsx'
alias baseikyu='open /Volumes/GoogleDrive/共有ドライブ/BA_契約管理/発注関連/2020年度/'
alias wsdseikyu='open /Volumes/GoogleDrive/共有ドライブ/WSD/001_運用資料/00_通常利用/98_発注関連書類'
#
# ██████╗ ██████╗
# ██╔══██╗██╔══██╗
# ██║  ██║██████╔╝
# ██║  ██║██╔══██╗
# ██████╔╝██████╔╝
# ╚═════╝ ╚═════╝
#
# DB接続のalias
# 本来なら、.ssh/configに指定したいがうまくいかないのでこちらで
alias db-st-b='ssh i04npsys@103.4.8.217 -N -L 7521:10.0.1.192:1521'
alias db-st-c='ssh i04npsys@103.4.8.217 -N -L 7522:st-btoc-db1.st-vpc.internal:1521'
alias db-CT-B='ssh i04npsys@103.4.8.217 -N -L 5521:ct-btob-npdb.c50hlo4hzhce.ap-northeast-1.rds.amazonaws.com:1521'
alias db-CT-C='ssh i04npsys@103.4.8.217 -N -L 5522:ct-btoc-npdb.c50hlo4hzhce.ap-northeast-1.rds.amazonaws.com:1521'
alias db-ut-b='ssh i04npsys@103.4.8.217 -N -L 7521:10.0.1.47:1521'

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

## git ブランチ名を色付きで表示させるメソッド
#function rprompt-git-current-branch {
#local branch_name st branch_status
#
#if [ ! -e  ".git" ]; then
#    # git 管理されていないディレクトリは何も返さない
#    return
#fi
#branch_name=`git rev-parse --abbrev-ref HEAD 2> /dev/null`
#st=`git status 2> /dev/null`
#if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
#    # 全て commit されてクリーンな状態
#    branch_status="%F{green}"
#elif [[ -n `echo "$st" | grep "^Untracked files"` ]]; then
#    # git 管理されていないファイルがある状態
#    branch_status="%F{red}?"
#elif [[ -n `echo "$st" | grep "^Changes not staged for commit"` ]]; then
#    # git add されていないファイルがある状態
#    branch_status="%F{red}+"
#elif [[ -n `echo "$st" | grep "^Changes to be committed"` ]]; then
#    # git commit されていないファイルがある状態
#    branch_status="%F{yellow}!"
#elif [[ -n `echo "$st" | grep "^rebase in progress"` ]]; then
#    # コンフリクトが起こった状態
#    echo "%F{red}!(no branch)"
#    return
#else
#    # 上記以外の状態の場合
#    branch_status="%F{blue}"
#fi
## ブランチ名を色付きで表示する
#echo "${branch_status}[$branch_name]"
#}
#
## プロンプトが表示されるたびにプロンプト文字列を評価、置換する
#setopt prompt_subst
#
## プロンプトの右側にメソッドの結果を表示させる
#RPROMPT='`rprompt-git-current-branch`'

source "/usr/local/opt/zsh-git-prompt/zshrc.sh"
ZSH_THEME_GIT_PROMPT_PREFIX="["
ZSH_THEME_GIT_PROMPT_SUFFIX=" ]"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[green]%}%{ %G%}"
ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[magenta]%}%{x%G%}"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[red]%}%{+%G%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[red]%}%{-%G%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[green]%}%{+%G%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%}%{✔%G%}"
RPROMPT='$(git_super_status)'
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
# ----------------------------------------
# カレントディレクトリ表示
# ----------------------------------------
# PROMPT='%m:%F{green}%c%f %n$ '
# PROMPT='
# %F{green}%(5~,%-1~/.../%2~,%~)%f
# %F{green}%B●%b%f'
# PROMPT='%F{yellow}%m@%n%f %F{green}%~%f$ '
eval "$(anyenv init -)"

source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/t.miyazawa/.sdkman"
[[ -s "/Users/t.miyazawa/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/t.miyazawa/.sdkman/bin/sdkman-init.sh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
