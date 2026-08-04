# ==========================================================
# TEMEL KABUK VE GEZİNME (SHELL & NAVIGATION)
# ==========================================================
alias c='clear'
alias ..='cd ..'
alias ...='cd'
alias py='python'

# ==========================================================
# DÜZENLEME VE GÖRÜNTÜLEME (EDITOR & VIEW)
# ==========================================================
# nvim kullan
alias v='nvim'
# sudo ile Wayland uyumlu nvim
alias sv='sudo XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WAYLAND_DISPLAY=$WAYLAND_DISPLAY DISPLAY=$DISPLAY nvim'
# Fastfetch ile sistem bilgisi
alias ff='fastfetch --config examples/12'
# Neo-Matrix
alias neo='LANG=C neo-matrix -D'

# ==========================================================
# DOSYA VE DİZİN YÖNETİMİ (FILE & DIRECTORY)
# ==========================================================
# eza ile listeleme (ls yerine modern alternatif)
alias ls='eza -a --icons --group-directories-first'
alias ll='eza -al -h --color=always --icons --group-directories-first --octal-permissions'
alias lt='eza -a --tree --level=1 --icons --group-directories-first'

# Klasik tree komutu
alias tree='tree -l -C --dirsfirst'

# Dönüşümler
alias pngtojpg='mogrify -format jpg'
alias jpgtopng='mogrify -format png'

# ==========================================================
# PAKET VE SİSTEM YÖNETİMİ (PACMAN & SYSTEM)
# ==========================================================
# Kurulum
alias install='yay -S --needed'
alias remove='sudo pacman -R'
# Güncelleme
# update: yalnizca resmi Arch depolari (core/extra/multilib). AUR'a dokunmaz.
# yay uzerinden degil pacman'la: yay-bin'in kendisi bir AUR paketi, bozuldugu
# gun de `update` calisabilmeli.
alias update='sudo pacman -Syu'
# full-update fonksiyondur -> functions.zsh (alias burada TANIMLANMAZ; alias
# ayni adli fonksiyonu golgeler).
# Temizlik
alias cleancache='sudo pacman -Sc'
alias cleanorphan='sudo pacman -Rns $(pacman -Qqtd)'
# Kapatma
alias shutdown='systemctl poweroff'
alias stopkmscon='sudo systemctl restart kmsconvt@tty5.service'

# ==========================================================
# AĞ VE CİHAZ KONTROLÜ (NETWORK & DEVICE)
# ==========================================================
alias ssh_clear='rm ~/.ssh/known_hosts'
alias wifion='iwctl device wlan0 set-property Powered on'
alias wifioff='iwctl device wlan0 set-property Powered off'
alias bluetoothon='echo -e "power on" | bluetoothctl >/dev/null'
alias bluetoothoff='echo -e "power off" | bluetoothctl >/dev/null'

# ==========================================================
# SANALLAŞTIRMA VE UYGULAMA (VM & APP)
# ==========================================================
# Windows 11 VM
alias win11='$HOME/.config/scripts/others/win11'
alias win11shutdown='virsh --connect=qemu:///system shutdown win11'
# Misafirin masaustunu ac (Looking Glass). `-f /dev/kvmfr0` ZORUNLU: bayraksiz
# cagirinca istemci /dev/shm/looking-glass'a bakar, bu kurulumda paylasilan
# bellek kvmfr karakter cihazinda. Yanlis cagrinin belirtisi yaniltici --
# "The host application seems to not be running" satirinda donar, yani misafir
# kapali gibi gorunur. Istemci misafir kapaninca kendiliginden cikar.
alias win11view='looking-glass-client -f /dev/kvmfr0'

# Waydroid (Android)
alias apkinstall='waydroid app install'
alias apkremove='waydroid app remove'
alias waydroidoff='waydroid session stop'

# Samba Paylaşım
alias share='net usershare add'
alias unshare='net usershare remove'
alias sharelist='net usershare info'

# Razer DeathStalker v2 Pro
alias klavye='razer-cli -e reactive,4 brightness,25 -c FFFFFF'
# ==========================================================
# DİĞER ARAÇLAR (MISCELLANEOUS)
# ==========================================================
alias gs='git status'
alias fontsearch='$HOME/.config/scripts/fontsearch'
alias fontupdate='fc-cache -f -v'
alias mimetipbul='file --mime-type -b'
alias balık='asciiquarium'
# ==========================================================
# AI araclar
# ==========================================================
# Claude Code'a parolasiz sudo ver/al: argumansiz cagri toggle, `csudo status`
# durumu soyler. Pencere oturum kapaninca ya da yeniden baslatinca kendiliginden
# kapanir. Ilk kullanimdan once makinede bir kez: `claude-sudo setup`.
alias csudo='claude-sudo'

alias ollama-start='nohup ollama serve > ~/Documents/ollama.log 2>&1 &'
alias ollama-stop='pkill -f "ollama serve"'
alias ollama-status='pgrep -f "ollama serve" && echo "Çalışıyor" || echo "Durmuş"'
