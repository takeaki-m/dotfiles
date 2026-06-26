
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

# aws profile
alias pa='profile_aws'
profile_aws() {
  # -n: デフォルトの出力(マッチしない行も出力される)を抑制
  # p: パターンにマッチした行だけを出力
  target_profile=$(sed -n 's/^\[profile \(.*\)]/\1/p' ~/.aws/config | fzf)
  if [[ -z "$target_profile" ]]; then
    echo "profileが選択されなかったため処理を中断する"
    return 1
  fi
  echo "PROFILE: ${target_profile}"
  aws sso login --profile ${target_profile}
  export AWS_PROFILE=${target_profile}
}

memo(){
    local dir="$HOME/Documents/obsidian/daily"
    local obsidian_home="$HOME/Documents/obsidian"
    mkdir -p "$dir" || return 1

    local file="$dir/$(date +%Y-%m-%d).md"
    local monthly_note="$dir/$(date +%Y-%m).md"

    # obsidianのディレクトリを開くように先にディレクトリを移動する
    # 失敗時には中断する
    cd $obsidian_home || return 1

    if [[ -f "$file" ]]; then
        # 既存ならそのファイルを普通に開く
        nvim -c "edit "$file""

    else
        # 未作成なら nvim を開いて専用コマンドを実行
        nvim -c "Obsidian today"
    fi
}

today(){
    local obsidian_home="$HOME/Documents/obsidian"
    local dir="$obsidian_home/daily"
    mkdir -p "$dir" || return 1

    local yesterday_note="$dir/$(date -v-1d +%Y-%m-%d).md"
    local file="$dir/$(date +%Y-%m-%d).md"
    local monthly_note="$dir/$(date +%Y-%m).md"

    # obsidianのディレクトリを開くように先にディレクトリを移動する
    # 失敗時には中断する
    cd "$obsidian_home" || return 1

    if check_os_theme_is_dark; then
        local colorscheme="tokyonight-night"
    else
        local colorscheme="tokyonight-day"
    fi

    command nvim "$monthly_note"

    # Obsidianでdaily note方式ではなくて、weekly noteにするため次のコマンドをコメントアウトする
    # 昨日分のファイル存在で分岐
    #if [[ -f "$yesterday_note" ]]; then
    #    # nvimのsplitコマンドにスペースを含むパスを渡すため、エスケープが必要
    #    # zshのパラメータ展開を利用
    #    # //: 全てのマッチを置換
    #    # // : //にて全ての置換を対象として、その後でスペースを指定
    #    # \\ : 置換文字列(バックスラッシュ+スペース)
    #    # NOTE; yesterday_noteを指定しているが、splitで開くことができない。もし実現方法がわかれば修正する
    #    local escaped_yesterday="${yesterday_note// /\\ }"
    #    command nvim "$monthly_note" \
    #      -c "vsplit $escaped_yesterday" \
    #      -c "Obsidian today" \
    #      # -c "colorscheme $colorscheme"
    #else
    #    # 昨日分のファイルが存在しなければ、今日のファイルのみ開く
    #    command nvim "$monthly_note" \
    #      -c "Obsidian today" \
    #      # -c "colorscheme $colorscheme"
    #fi
}

zenn() {
  echo "zennの記事作成に使う各パラメータを設定してください。"
  echo "slug:(英数"-"のみ利用) "
  read slug
  echo "title: "
  read title
  echo "type:"
  select type in tech idea
  do
    if [ -n "$type" ]; then
      echo "$type が選択されました"
      break #loopを抜ける
    else
      echo "無効な入力です"
    fi
  done
  echo "emoji: "
  read emoji 
  echo "実行するコマンドは以下で良いですか？"
  local cmd="npx zenn new:article --slug $slug --title $title --type $type --emoji $emoji"
  echo "$cmd"
  select answer in yes no
  do
    case $answer in
      yes)
        # yesが選択されたらループを抜ける先に進む
        break
        ;;
      no)
        echo "コマンドの実行を終了します"
        return 1
        ;;
      *)
        echo "無効な選択です。yesかnoの番号を入力してください"
        ;;
    esac
  done
  echo "記事を作成します"
  eval "$cmd"
}

# gh commandの出力がdark modeとlight modeで背景の色と同色になってしまうため被らないように設定
# https://github.com/charmbracelet/glamour#styles
# https://github.com/cli/cli/issues/8292?utm_source=chatgpt.com
# NOTE: 以下の設定ではinteractiveコマンドが利用できないためコメントアウトをする(gh pr newで起動できない)
gh() {
  if check_os_theme_is_dark; then
    GLAMOUR_STYLE=dark command gh "$@"
  else
    GLAMOUR_STYLE=light command gh "$@"
  fi
}
gh_release_backend() {
  local out
  out=$(gh workflow run release-backend.yml --ref $(git branch --show-current) -f environment=dev 2>&1) || \
  { echo "$out" >&2; return 1; }
  local run_id=$(echo "$out" | grep -oE 'runs/[0-9]+' | head -1 | cut -d/ -f2)
  [ -n "$run_id" ] && gh run watch --exit-status "$run_id"
}

gh_release_frontend() {
  local out
  out=$(gh workflow run release-frontend.yml --ref $(git branch --show-current) -f environment=dev -f cleanup=true 2>&1) || \

  { echo "$out" >&2; return 1; }
  local run_id=$(echo "$out" | grep -oE 'runs/[0-9]+' | head -1 | cut -d/ -f2)
  [ -n "$run_id" ] && gh run watch --exit-status "$run_id"
}
ghdev() {
  echo "GitHub issueと関連付けてブランチを作成します">&2
  echo "Issue を選択してください">&2
  issue_no=$(gh issue list --limit 100 | fzf | awk '{print $1}')
  echo "選択されたIssue: $issue_no">&2
  choice=$( echo "feature\nfix\nother" | fzf --prompt="prefixを選択:")
  echo "prefixを選択してください">&2
  if [[ "$choice" == "other" ]]; then
    # readはZLEを使わないためCtrl-Hなどのemacsキーバインドが効かない。
    # varedはZLE経由で値を編集するため、bindkey -eで設定したキーが利用できる。
    vared -c -p "prefixを自由入力してください: " choice
  fi
  echo "変更内容を英語で入力してください">&2
  # 同上: readではなくvaredを使ってemacsキーバインド(Ctrl-H等)を有効化する
  vared -c -p "変更内容: " content
  branch="${choice}/${issue_no}-${content}"
  echo "実行するコマンドは以下で良いですか？">&2
  local cmd=( gh issue develop "$issue_no" --name "$branch" )
  echo "$cmd" >&2
  answer=$( echo "yes\nno" | fzf --prompt="実行しますか？:")
  if [[ "$answer" != "yes" ]]; then
    echo "コマンドの実行を終了します">&2
    return 1
  fi
  echo "ブランチを作成します" >&2
  if ! "${cmd[@]}" 1>&2; then
    echo "gh コマンドの実行に失敗しました" >&2
  fi
  # 呼び出し側にはREPLY(zsh慣用のグローバル変数)でブランチ名を渡す。
  # 背景: $(ghdev)のコマンド置換で呼ぶとサブシェル化されZLEが無効になり、
  #       vared(ZLE依存)が "ZLE not enabled" で失敗する。
  #       対話シェル本体で実行しつつ結果を返すため、stdoutではなく変数経由にする。
  REPLY=$branch
}

gwc() {
    # 全体: issue連動worktreeを作成し、nvim + ClaudeCodeを起動する
    # 詳細: ghdevが返すブランチ名(例 feature/123-fix-xxx)からissue番号を抜き出し、
    #       Claude Codeの初期プロンプトとして /check-issue を送る。
    #       抽出できない場合は従来通り素のClaudeCodeを起動する(フォールバック)。
    # ghdevはコマンド置換で呼ぶとZLEが無効化されvaredが失敗するため、
    # 対話シェルの文脈でそのまま実行し、結果はREPLY経由で受け取る。
    ghdev || return 1
    local branch=$REPLY
    [[ -z "$branch" ]] && return 1
    branch_with_hyphen=$(echo $branch | tr / -)
    local worktree_path="../$branch_with_hyphen"
    git fetch origin $branch
    git worktree add "$worktree_path" "$branch"
    cd "$worktree_path"

    # ブランチ名 feature/123-content から "123" を取り出す
    # zshパラメータ展開: ${${branch#*/}%%-*} は「最初の / より後ろ」かつ「最初の - より前」
    local issue_no="${${branch#*/}%%-*}"

    # nvimと指定しないとaliasの設定が効かずvimが起動される
    # 引用符の通り道: zsh \" → nvim opts.args内に " → claudecode.nvimがclaude CLIへ渡す際に
    # shellを経由して引用符が剥がれ、claudeが /check-issue <番号> を1位置引数として受け取る
    if [[ "$issue_no" =~ ^[0-9]+$ ]]; then
        nvim . -c "term make init_apps; zsh" \
            -c "ClaudeCode \"/check-issue $issue_no\""
    else
        nvim . -c "term make init_apps; zsh" \
            -c "ClaudeCode"
    fi
}

gcw() {
  local target
  target=$(git worktree list | fzf | awk '{print $1}')
  if [ -n "$target" ]; then
    cd "$target"
  fi
}

gci() {
  issue_line=$(gh issue list --limit 100 | fzf)
  [[ -z "$issue_line" ]] && { echo "issueが選択されなかったため処理を中断します" >&2; return 1; }
  # gh issue listの出力先頭はissue番号。awkで抜き出す
  local issue_no
  issue_no=$(echo "$issue_line" | awk '{print $1}')
  [[ -z "$issue_no" ]] && { echo "issue番号を取得できませんでした" >&2; return 1; }
  # gh issue viewはstdinを読まないため、issue番号は位置引数で渡す。
  task_name=$(gh issue view "$issue_no" --json number,title -q '[.number, .title] | join(" ")')
  echo $task_name | pbcopy
  echo "task titleとissue numberがclipboardにコピーされました。: ${task_name}" >&2
}

gwp() {
    # 全体: PR連動worktreeを作成し、nvim + ClaudeCodeを起動する
    # 詳細: gh pr listで一覧表示しfzfで選択 → 選択PRのheadRefNameを取得 →
    #       そのブランチを使ってworktreeを作成しnvim+ClaudeCodeを起動する。
    # gwc(issueベース)とは異なり、既存PRに紐づくブランチで作業を始める用途。
    echo "Pull Requestを選択してください" >&2
    local pr_line
    pr_line=$(gh pr list --limit 100 | fzf)
    [[ -z "$pr_line" ]] && { echo "PRが選択されなかったため処理を中断します" >&2; return 1; }

    # gh pr listの出力先頭はPR番号。awkで抜き出す
    local pr_no
    pr_no=$(echo "$pr_line" | awk '{print $1}')
    [[ -z "$pr_no" ]] && { echo "PR番号を取得できませんでした" >&2; return 1; }

    # gh pr viewはstdinを読まないため、PR番号は位置引数で渡す。
    # -q (--jq)でheadRefNameだけを抽出する
    local branch
    branch=$(gh pr view "$pr_no" --json headRefName -q .headRefName)
    [[ -z "$branch" ]] && { echo "headRefNameを取得できませんでした" >&2; return 1; }
    echo "選択されたPR: #${pr_no} (branch: ${branch})" >&2

    # ブランチ名に / が含まれるとworktreeのパスがネストしてしまうため - に置換する。
    # 加えてフォルダ名は英小文字に統一したいため、tr で大文字→小文字へ変換する。
    # (zshの ${var:l} でも小文字化できるが、ここではtrでパイプ処理にまとめる)
    local branch_with_hyphen
    branch_with_hyphen=$(echo "$branch" | tr / - | tr '[:upper:]' '[:lower:]')
    local worktree_path="../$branch_with_hyphen"

    # リモート最新を取得してからworktreeを作成
    git fetch origin "$branch" || { echo "git fetchに失敗しました" >&2; return 1; }
    git worktree add "$worktree_path" "$branch" || { echo "git worktree addに失敗しました" >&2; return 1; }
    cd "$worktree_path" || return 1

    # gwcと同様、nvim起動と同時にClaudeCodeを立ち上げる
    if [[ "$pr_no" =~ ^[0-9]+$ ]]; then
        nvim . -c "term make init_apps; zsh" \
            -c "ClaudeCode \"/check-pr $pr_no\""
    else
        nvim . -c "term make init_apps; zsh" \
            -c "ClaudeCode"
    fi
}

gwr() {
  local target
  target=$(git worktree list | grep -v develop | grep -v main | fzf --header "削除するworktreeとbranchを選択してください")
  [ -z "$target" ] && return
  local target_worktree target_branch
  target_worktree=$(echo "$target" | awk '{print $1}')
  target_branch=$(echo "$target" | awk '{print $3}' | tr -d '[]')
  if [ -n "$target_worktree" ]; then
    git worktree remove "$target_worktree" && \
    echo "remove git worktree: $target_worktree" && \
    git branch -d "$target_branch" && \
    echo "remove git branch: $target_branch"
  fi
}


release() {
  echo "Release準備を開始します"
  echo "Releaseブランチを作成します"
  echo "Release branch suffix: リリース内容を英語で入力してください">&2
  # readではなくvaredを使ってemacsキーバインド(Ctrl-H等)を有効化する
  vared -c -p "content(english)" branch_suffix 
  git checkout -b "release/$(date '+%Y-%m')/$branch_suffix"
  echo "続けてPRを作成します"
  echo "PR title suffix: リリース内容を日本語で入力してください">&2
  # readではなくvaredを使ってemacsキーバインド(Ctrl-H等)を有効化する
  vared -c -p "content(Japanese)" pr_title_suffix 
  gh pr new --base main --title "Release/$(date '+%Y-%m')/${pr_title_suffix}"
}

# Git作業前提: tracked変更(staged/unstaged)がないことを確認
git_require_clean_tracked() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Not a git repository."
      return 1
    }
  git update-index -q --refresh
  if ! git diff --quiet --ignore-submodules --; then
    echo "Blocked: unstaged changes exist. Commit/stash/restore first."
    git status --short
    return 1
  fi
  if ! git diff --cached --quiet --ignore-submodules --; then
    echo "Blocked: staged changes exist. Commit/stash/restore first."
    git status --short
    return 1
  fi
}

# 安全 checkout/switch
gco() {
  git_require_clean_tracked || return 1
  git checkout "$@"
}

# 安全 pull
gpl() {
  git_require_clean_tracked || return 1
  git pull "$@"
}


# 全体: Claude Code Review を手動実行するラッパー
# 詳細: 引数が無い場合は現在ブランチのPR番号を自動取得する
gcr() {
  local pr_number
  if [[ -n "$1" ]]; then
    pr_number="$1"
  else
    pr_number="$(gh pr view --json number -q .number)"
  fi

  if [[ -z "$pr_number" ]]; then
    echo "PR番号を取得できません。引数でPR番号を指定してください。"
    return 1
  fi

  gh workflow run "Claude Code Review" -f pr_number="$pr_number"
}

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
alias history='history -i'
# edit clipboard contents with vim
alias cv='vim +"put +"'
alias vimset='cd $HOME/settings/dotfiles/nvim/ && vim .'
# set xterm to TERM for older terminals that does not support xterm-256color
alias term='export TERM=xterm; echo $TERM'

alias psql='psql-17'

# nvimがos themeに合わせて色が変更可能になったため以下の設定はコメントアウトする
#nvim(){
    # if check_os_theme_is_dark; then
    #     command nvim -c "colorscheme tokyonight-night" "$@"
    # else
    #     command nvim -c "colorscheme tokyonight-day" "$@"
    # fi
#}

alias v='vim'
alias vim='nvim'

alias g='git'
alias gpoc='git push origin `git rev-parse --abbrev-ref HEAD` | gpb'
alias gpb='git log --oneline | head -1 | awk '\''{print $2" "$3}'\'' | sed -e '\''s/\r\n//g'\'' | pbcopy'
alias gupdev='g fetch origin; g co develop; g pull'
alias gmd='gupdev; g co - ; g merge develop'
alias gbrmd='git branch -d `git branch --merged`'
alias gpr='gh pr create'
# 末尾の改行を削除するために-nを利用。標準出力をpipeするとechoで出力されなかったため変数に指定する
alias cpb='current_branch_name=$(git branch | grep "*" | sed -e "s/\* //g") | echo -n $current_branch_name | pbcopy'

alias d='docker'
alias dc='docker compose'

alias szs='source ~/.zshrc'
alias reload='exec $SHELL -l'
alias tm='tmux'
alias brew_add='vim ~/.Brewfile'
alias brew_install='brew bundle --global'
alias upbrew='brew update && brew upgrade && brew cleanup'
alias reader='/usr/bin/open -a Safari `pbpaste`'

alias dotfiles='cd ~/settings/dotfiles && vim . -c "ClaudeStart"'
alias lg='lazygit'
alias pn='pnpm'
alias aws_dev='aws sso login --profile dev-admin'

lazygit(){
  if check_os_theme_is_dark; then
     command lazygit --use-config-file="$HOME/Library/Application Support/lazygit/config.yml,$HOME/Library/Application Support/lazygit/theme_dark.yml"
  else
     command lazygit --use-config-file="$HOME/Library/Application Support/lazygit/config.yml,$HOME/Library/Application Support/lazygit/theme_light.yml"
  fi
}

# nvim
alias work="cd ~/work/aim/aim-suite"
alias aim='vim ~/work/aim/aim-suite -c "cd ~/work/aim/aim-suite"'

# github cli
alias ghie='gh issue edit $(gh issue list | fzf | awk '\''{print $1}'\'')'
alias ghpre='gh pr edit $(gh pr list | fzf | awk '\''{print $1}'\'')'
alias approot='GIT_ROOT=$(git rev-parse --show-toplevel) && cd $GIT_ROOT'
alias check_gh_workflow="gh run watch && osascript -e 'display notification \"Workflow finished\" with title \"GitHub Actions\" sound name \"Glass\"'"

# 指定した時間後に通知を表示する関数
# 使用例: notify 5m ビルド完了しました（引用符不要）
notify() {
  local wait_time="$1"
  shift
  local message="${*:-通知}"  # 残りの引数をすべて結合

  if [[ -z "$wait_time" ]]; then
    echo "使用方法: notify <待機時間> [メッセージ]" >&2
    echo "  待機時間: 秒数(例: 900) または 分指定(例: 5m, 10m)" >&2
    return 1
  fi

  # 分指定(例: 5m)を秒に変換
  if [[ "$wait_time" =~ ^([0-9]+)m$ ]]; then
    wait_time=$((${BASH_REMATCH[1]} * 60))
  fi

  echo "${wait_time}秒後に通知します: ${message}"
  sleep "$wait_time" && osascript -e "display notification \"${message}\" with title \"通知\" sound name \"Glass\""
} 
alias webstorm='open -na "WebStorm.app" --args .'
alias idea='open -na "IntelliJ IDEA.app" --args .'
alias pycharm='open -na "Pycharm.app" --args .'

check_os_theme_is_dark() {
  osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode' \
  | grep -qi true
}

function set_api_keys() {
  set_openai
  set_google_generative_ai_api_key
  set_anthropic_api_key
}

# 開発時にopen ai apiの設定を迅速にする関数
function set_openai() {
    # 既に値がセットされているかチェック (-n は文字列の長さが0より大ならTrue)
    if [ -n "$OPENAI_API_KEY" ]; then
        echo "OPENAI_API_KEY is already set. Skipping."
        return 0
    fi

    # -r: バックスラッシュをエスケープとして扱わない
    # -s: 入力文字を非表示にする
    read -rs "OPENAI_API_KEY?Enter OPENAI_API_KEY: "

    # 外部に公開
    export OPENAI_API_KEY

    # -s を使うと改行が表示されないため、手動で改行を入れる
    echo "\nOPENAI_API_KEY has been exported."
}

# 開発時にopen ai apiの設定を迅速にする関数
function set_google_generative_ai_api_key() {
    # 既に値がセットされているかチェック (-n は文字列の長さが0より大ならTrue)
    if [ -n "$GOOGLE_GENERATIVE_AI_API_KEY" ]; then
        echo "GOOGLE_GENERATIVE_AI_API_KEY is already set. Skipping."
        return 0
    fi

    # -r: バックスラッシュをエスケープとして扱わない
    # -s: 入力文字を非表示にする
    read -rs "GOOGLE_GENERATIVE_AI_API_KEY?Enter GOOGLE_GENERATIVE_AI_API_KEY: "

    # 外部に公開
    export GOOGLE_GENERATIVE_AI_API_KEY

    # -s を使うと改行が表示されないため、手動で改行を入れる
    echo "\nGOOGLE_GENERATIVE_AI_API_KEY has been exported."
}

function set_anthropic_api_key() {
    # 既に値がセットされているかチェック (-n は文字列の長さが0より大ならTrue)
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "ANTHROPIC_API_KEY is already set. Skipping."
        return 0
    fi

    # -r: バックスラッシュをエスケープとして扱わない
    # -s: 入力文字を非表示にする
    read -rs "ANTHROPIC_API_KEY?Enter ANTHROPIC_API_KEY: "

    # 外部に公開
    export ANTHROPIC_API_KEY

    # -s を使うと改行が表示されないため、手動で改行を入れる
    echo "\nANTHROPIC_API_KEY has been exported."
}

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
# 補完メニュー操作用モジュール: menuselectキーマップを利用可能にする
zmodload zsh/complist
zstyle ':completion:*:default' menu select=1
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

# --------------------
# keybind
# - bindkey -eの設定より、後に設定しなければkeybindが無効となる
# - 以下にまとめて設定すること
# --------------------

# emacs keybindをdefaultとする
bindkey -e


# 前方一致
# 入力補完
# zsh-autocomplete: リアルタイム補完機能
# 無効化理由: 入力中の自動表示が煩わしいため。
# 現在は zsh-completions + fzf の組み合わせで補完・検索機能を実現している。
#source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# zsh-autocompleteのキーバインドを変更する
bindkey              '^I'         menu-complete
bindkey "$terminfo[kcbt]" reverse-menu-complete

# emacsモードではC-n/C-p/C-a/C-e/C-f/C-b/C-d/C-k/C-wはデフォルトで有効

# 補完メニュー選択中のキーバインド
# menu selectが有効な場合、候補一覧の中をC-n/C-pで移動できるようにする
bindkey -M menuselect '^N' down-line-or-history   # 補完メニュー: 下へ
bindkey -M menuselect '^P' up-line-or-history     # 補完メニュー: 上へ
bindkey -M menuselect '^F' forward-char           # 補完メニュー: 右へ
bindkey -M menuselect '^B' backward-char          # 補完メニュー: 左へ

#--------------------
# 入力するコマンドをエディタで編集する
#--------------------
# シンプルにzshの既存コマンドを利用するパターン
# この設定では、vimが起動する。
# 起動にはnvimを利用したいが、Globalのeditorをnvimに設定するとClaude CodeのCtrl-gコマンドでの入力時に問題が発生する
# グローバルのエディタ設定ではなく、今回のshell編集時のみnvimを利用するように次のカスタム設定を採用する
#autoload -Uz edit-command-line
#zle -N edit-command-line
#bindkey '\ee' edit-command-line

#
edit-with-nvim() {
    local tmp=${TMPPREFIX:-/tmp/zsh}editcmd-$RANDOM
    # 現在のBUFFERを一時ファイルへ
    print -r -- "$BUFFER" >! "$tmp"

    # 画面をクリアして外部エディタに切り替え
    zle -I
    # 入力中のバッファは一旦空に（任意：残しても良い）
    BUFFER=

    # nvim で編集（終了を待つ）
    nvim "$tmp"

    # 編集内容をBUFFERに反映
    if [[ -r "$tmp" ]]; then
        BUFFER=$(<"$tmp")
        CURSOR=${#BUFFER}
    fi

    # 後始末
    rm -f -- "$tmp"
}

zle -N edit-with-nvim
bindkey '^O' edit-with-nvim
#PROMPT='%n@%m %~ %# '
# PROMPT='%~ %# '
# 上記のPROMPTは342行目の git-aware な PS1（__git_ps1 でブランチ名を表示）を上書きしてしまうためコメントアウト

# 利用しないためコメントアウト
# ghqとの連携。ghqの管理化にあるリポジトリを一覧表示する。ctrl - ]にバインド。
#function peco-src () {
#  local selected_dir=$(ghq list -p | peco --prompt="repositories >" --query "$LBUFFER")
#  if [ -n "$selected_dir" ]; then
#    BUFFER="cd ${selected_dir}"
#    zle accept-line
#  fi
#  zle clear-screen
#}
#zle -N peco-src
#bindkey '^]' peco-src

