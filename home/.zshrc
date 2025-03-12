#!/bin/zsh

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Source/Load
source "${ZINIT_HOME}/zinit.zsh"
source "$HOME/.config/zsh/alias.zsh"

# User configuration
export PATH="$PATH:$HOME/.local/bin"
export $EDITOR=nvim
# export $TERMINAL=kitty

# Add plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
# History
zinit load zdharma-continuum/history-search-multi-word
zinit light zsh-users/zsh-history-substring-search
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::command-not-found

# Add in spaceship
zinit light spaceship-prompt/spaceship-prompt

# History
HISTSIZE=10000
HISTFILE=~/.config/zsh/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

# Setopt
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt menu_complete

# Bindkey
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^R' history-search-multi-word

# Styling
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=(none)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Replay compdefs (to be done after compinit). -q – quiet.
autoload -Uz compinit && compinit
_comp_options+=(globdots)
zinit cdreplay -q
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
