### split zsh
ZSHHOME="${HOME}/.zsh.d"

if [ -d $ZSHHOME -a -r $ZSHHOME -a \
     -x $ZSHHOME ]; then

    # Source the .profile.zsh file first
    profile_zsh="$ZSHHOME/profile.zsh"
    if [ -f "$profile_zsh" -o -h "$profile_zsh" ] && [ -r "$profile_zsh" ]; then
        . "$profile_zsh"
    fi

    # Source the remaining zsh files
    for i in $ZSHHOME/*; do
        if [ "$i" != "$profile_zsh" ]; then
          [[ ${i##*/} = *.zsh ]] && [ \( -f $i -o -h $i \) -a -r $i ]  && . $i
        fi
    done
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
# libpqは利用しないので、コメントアウト
# export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
# homebrewでinstallしたgitを利用する
if [[ -f /opt/homebrew/opt/git ]] then
  export PATH="/opt/homebrew/opt/git:$PATH"
fi

# pnpm
export PNPM_HOME="/Users/take/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/take/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
