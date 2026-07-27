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
alias nnn="nnn -a"
alias vim="nvim"

(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey '^ ' autosuggest-accept

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

for local_config in "$HOME"/.config/zsh/local/*.zsh(N); do
  source "$local_config"
done
unset local_config
