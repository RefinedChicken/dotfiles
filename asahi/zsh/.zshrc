# Add homebrew applications to path
eval "$(/opt/homebrew/bin/brew shellenv)"

# Set the directory for zinit and plugins
ZINIT_HOME="${ZDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light fdellwing/zsh-bat
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
zinit snippet OMZP::common-aliases

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Oh My Posh prompt
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
# 	eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
# 	eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/atomic-tokyo.json)"
#	eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/default.yaml)"
	eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/joray.omp.json)"
fi

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='eza -1 -l -a -M -Z --hyperlink'
alias ll='eza -1 -l -a -M -Z --hyperlink'
alias l='eza -a --hyperlink'
alias la='eza -1 -l -a -M -Z --hyperlink'
alias c='clear'
alias cat='bat -P'
alias e='yazi'
alias n='nvim'
alias q='exit'
alias tree='tree -a'
alias t='tree -a'
alias ez='exec zsh'
alias top='btop -u 1000'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
clear
fastfetch
