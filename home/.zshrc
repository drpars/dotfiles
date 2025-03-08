# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# command-not-found dependencies
if ! command -v pkgfile &>/dev/null; then
  echo -e "Installing pkgfile...\npkgfile: command-not-found plugin dependency."
  echo
  sudo pacman -S --noconfirm pkgfile
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in ohmyzsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::command-not-found

# Add in spaceship
zinit light spaceship-prompt/spaceship-prompt
zinit light spaceship-prompt/spaceship-vi-mode

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
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

# User configuration
export PATH="$PATH:$HOME/.local/bin"
export EDITOR=nvim
# export TERMINAL=kitty

# alias
alias v=nvim
alias sv='sudo nvim'
alias install='sudo pacman -S --needed'
alias remove='sudo pacman -R'
alias update='yay --noconfirm'
alias full-update='yay --devel'
alias ssh_clear='rm ~/.ssh/known_hosts'
alias ls='eza -a --icons --group-directories-first'
alias ll='eza -al -h --color=always --icons --group-directories-first --octal-permissions'
alias lt='eza -a --tree --level=1 --icons --group-directories-first'
alias gs='git status'
alias py='python'
alias share='net usershare add'
alias unshare='net usershare remove'
alias sharelist='net usershare info'
alias shutdown='systemctl poweroff'
alias apkinstall='waydroid app install'
alias apkremove='waydroid app remove'
alias fontsearch='$HOME/.config/scripts/fontsearch'
alias fontupdate='fc-cache -f -v'
alias pngtojpg='mogrify -format jpg'
alias jpgtopng='mogrify -format png'
alias waydroidoff='waydroid session stop'
alias wifion='iwctl device wlan0 set-property Powered on'
alias wifioff='iwctl device wlan0 set-property Powered off'
alias bluetoothon='echo -e "power on" | bluetoothctl >/dev/null'
alias bluetoothoff='echo -e "power off" | bluetoothctl >/dev/null'
alias cleancache='sudo pacman -Sc'
alias cleanorphan='sudo pacman -Rns $(pacman -Qqtd)'
alias win11='$HOME/.config/scripts/win11'
alias win11shutdown='virsh --connect=qemu:///system shutdown win11'
alias ff='fastfetch --config examples/12'
alias integratedgpu='supergfxctl -m Integrated'
alias hybridgpu='supergfxctl -m Hybrid'
