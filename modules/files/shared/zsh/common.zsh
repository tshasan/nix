# Interactive preferences shared by NixOS and macOS.

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt AUTO_CD
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

export EDITOR="nvim"
export VISUAL="$EDITOR"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

if (( $+commands[eza] )); then
  alias ls="eza"
  alias ll="eza -la"
  alias la="eza -a"
  alias lt="eza --tree --level=2"
else
  alias ll="ls -la"
  alias la="ls -a"
fi

alias g="git"
alias vim="nvim"

if (( $+commands[yazi] )); then
  function y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
      builtin cd -- "$cwd"
    fi
    command rm -f -- "$tmp"
  }
fi

(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# zsh only picks vi mode implicitly from EDITOR, so say it outright. The short
# KEYTIMEOUT drops the 0.4s pause after Esc, and the viins bindings let
# Backspace and ^W delete past the point where insert mode was entered.
bindkey -v
KEYTIMEOUT=1
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

for local_config in "$HOME"/.config/zsh/local/*.zsh(N); do
  source "$local_config"
done
unset local_config
