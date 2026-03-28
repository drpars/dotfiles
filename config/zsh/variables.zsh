# ==========================================================
# ORTAM DEĞİŞKENLERİ VE YOL GÜNCELLEMELERİ
# ==========================================================

# --- 1. XDG Temel Dizin Tanımlamaları ---

# XDG standardı, yapılandırma dosyalarını (~/.config) ve verileri (~/.local/share) düzenler.
# XDG Yapılandırma Dizinini Ayarla (Genellikle varsayılan olarak ayarlanmıştır, ancak güvenlik için eklendi)
export XDG_CONFIG_HOME="$HOME/.config"

# XDG Veri Dizinini Ayarla (Kullanıcı tarafından oluşturulan veriler için)
# Bu dizin, Flatpak ve PATH ayarlamaları için önemlidir.
export XDG_DATA_HOME="$HOME/.local/share"

# XDG Çalışma Zamanı Dizinini Ayarla (Soketler, PID'ler vb. geçici dosyalar)
# Oturum boyunca var olur ve yeniden başlatmada temizlenir.
export XDG_RUNTIME_DIR="/run/user/$UID"

# --- 2. PATH ve Dizin Güncellemesi ---

# PATH Güncellemesi: Kullanıcıya Özel İkili Dosyaları Ekleme
# Sadece $HOME/.local/bin PATH içinde henüz yoksa ekle.
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$PATH:$HOME/.local/bin"
fi

# Tüm betiklerin tek bir yerden PATH üzerinden erişilmesini sağlar.
if [[ ":$PATH:" != *":$HOME/.config/scripts:"* ]]; then
  export PATH="$PATH:$HOME/.config/scripts"
fi

# XDG_DATA_DIRS Güncellemesi (Flatpak Entegrasyonu)
# Flatpak kısayollarının ve simgelerinin masaüstü ortamında görünür olmasını sağlar.
FLATPAK_USER_SHARE="${XDG_DATA_HOME}/flatpak/exports/share"
FLATPAK_SYSTEM_SHARE="/var/lib/flatpak/exports/share"
# Flatpak yollarını listenin başına ekle (öncelik ver)
export XDG_DATA_DIRS="${FLATPAK_USER_SHARE}:${FLATPAK_SYSTEM_SHARE}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
# Geçici değişkenleri temizle
unset FLATPAK_USER_SHARE FLATPAK_SYSTEM_SHARE

# --- 3. Temel Uygulama Tanımları ve Ayarlar ---

export EDITOR=nvim
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export TERMINAL=kitty
export BROWSER=firefox
# export LIBVIRT_DEFAULT_URI="qemu:///system"
