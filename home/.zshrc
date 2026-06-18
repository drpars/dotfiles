#!/bin/zsh

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Source/Load
source "${ZINIT_HOME}/zinit.zsh"
source "$HOME/.config/zsh/alias.zsh"
source "$HOME/.config/zsh/functions.zsh"
source "$HOME/.config/zsh/colors.zsh"
source "$HOME/.config/zsh/variables.zsh"

# Add plugins
# globdots compinit'ten ÖNCE ayarlanmalı (compinit, turbo bloğunda zicompinit ile koşuyor)
_comp_options+=(globdots)

# autosuggestions: öneriler hem geçmişten hem completion'dan gelsin (plugin'den önce ayarla)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Completion
zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions
# Completion selection
zinit light Aloxaf/fzf-tab
# History
zinit load zdharma-continuum/history-search-multi-word
zinit light zsh-users/zsh-history-substring-search
# Alias hatırlatıcı: tam komutu yazınca "bunun alias'ı var" der
zinit wait lucid for MichaelAquilina/zsh-you-should-use
# forgit: fzf ile etkileşimli git (ga, glo, gd, gco, gss…)
zinit wait lucid for wfxr/forgit

# Add in snippets
zinit snippet OMZP::sudo
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::command-not-found
# Evrensel arşiv açma: extract <dosya>  (tar/zip/rar/7z…)
zinit snippet OMZP::extract

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
setopt hist_find_no_dups

# Bindkey
bindkey '^?'      backward-delete-char          # bs         delete one char backward
bindkey '^[[3~'   delete-char                   # delete     delete one char forward
bindkey '^[[H'    beginning-of-line             # home       go to the beginning of line
bindkey '^[[F'    end-of-line                   # end        go to the end of line
bindkey '^[[1;5C' forward-word                  # ctrl+right go forward one word
bindkey '^[[1;5D' backward-word                 # ctrl+left  go backward one word
bindkey '^H'      backward-kill-word            # ctrl+bs    delete previous word
bindkey '^[[3;5~' kill-word                     # ctrl+del   delete next word
bindkey '^J'      backward-kill-line            # ctrl+j     delete everything before cursor
bindkey '^[[D'    backward-char                 # left       move cursor one char backward
bindkey '^[[C'    forward-char                  # right      move cursor one char forward
bindkey '^[[A'    history-substring-search-up   # up         prev command in history
bindkey '^[[B'    history-substring-search-down # down       next command in history
bindkey '^R'      history-search-multi-word     # ctrl+R     history search

# Styling
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=(none)
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set matcher-list
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
# genel önizleme: dizinleri eza, dosyaları bat ile göster
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '[ -d "$realpath" ] && eza -1 --color=always --icons "$realpath" || bat --color=always --style=numbers --line-range=:200 "$realpath" 2>/dev/null'
zstyle :plugin:history-search-multi-word reset-prompt-protect 1

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# compinit ve compdef replay, turbo bloğundaki zicompinit/zicdreplay ile yapılıyor.
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

. "$HOME/.local/bin/env"
