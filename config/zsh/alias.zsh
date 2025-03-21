# Functions
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

custompip() {
  if ! command -v pip &>/dev/null; then
    echo "Error: pip is not installed or not in PATH." >&2
    return 1
  fi

  local option="$1"
  local package="$2"
  local constant="--break-system-packages"

  case "$option" in
    install|uninstall)
      if [[ -z "$package" ]]; then
        echo "Error: No package specified for '$option'." >&2
        return 1
      fi
      pip "$option" "$package" "$constant"
      return $? 
      ;;
    *)
      pip "$@"
      ;;
  esac
}

pipupdatewithpipreview() {
  # Ensure pip-review is installed
  if ! command -v pip-review &>/dev/null; then
    echo "Installing pip-review..."
    pip install pip-review --break-system-packages || return 1
  fi

  # Generate a List of Outdated Packages and Update Them
  pip-review --freeze-outdated-packages | cut -d '=' -f 1 | xargs -r -n1 pip install --upgrade --break-system-packages
}

# alias
alias c='clear'
alias v='nvim'
alias sv='sudo nvim'
alias install='sudo pacman -S --needed'
alias remove='sudo pacman -R'
alias update='yay --noconfirm'
alias full-update='yay --devel && sudo pkgfile --update && sudo locate db >/dev/null'
alias ssh_clear='rm ~/.ssh/known_hosts'
alias ls='eza -a --icons --group-directories-first'
alias ll='eza -al -h --color=always --icons --group-directories-first --octal-permissions'
alias lt='eza -a --tree --level=1 --icons --group-directories-first'
alias gs='git status'
alias py='python'
alias pipforce='custompip'
alias pipupdate='pipupdatewithpipreview'
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
alias neo='LANG=C neo -D'
