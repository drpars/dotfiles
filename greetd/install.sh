#!/usr/bin/env bash
# greetd + tuigreet yapılandırmasını bu repodan sisteme kurar (root ister).
#
#   ./install.sh          kurar
#   ./install.sh check    canlı dosyalar repodan ayrıştı mı, onu söyler
#
# `check` bu bölümün varlık sebebi: hedefler /etc altında ve symlink değil
# (greeter kullanıcısı ev dizinini okuyamıyor — `~drpars` 0700). Kopya olduğu
# için ayrışma sessizdir; sddm bölümünde tam olarak bu oldu.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Root olarak çağrılabilsin diye: `sudo ./install.sh` tek onay penceresi açar,
# içeriden sudo çağırmak dosya başına bir tane açardı.
SUDO=sudo
(( EUID == 0 )) && SUDO=

# repo dosyası | sistemdeki hedef | mod
MAP=(
    "config.toml|/etc/greetd/config.toml|644"
    "tuigreet.toml|/etc/tuigreet/config.toml|644"
    "vtrgb-tokyonight|/etc/vtrgb-tokyonight|644"
    "vtrgb-tokyonight.service|/etc/systemd/system/vtrgb-tokyonight.service|644"
)

check() {
    local drift=0 missing=0
    for entry in "${MAP[@]}"; do
        IFS='|' read -r name dest _ <<<"$entry"
        if [[ ! -e $dest ]]; then
            printf '  ? %-45s kurulu değil\n' "$dest"
            missing=1
        elif cmp -s "$SRC/$name" "$dest"; then
            printf '  = %-45s aynı\n' "$dest"
        else
            printf '  ! %-45s AYRIŞMIŞ\n' "$dest"
            diff -u --label "repo/$name" --label "$dest" "$SRC/$name" "$dest" || true
            drift=1
        fi
    done
    (( drift )) && printf '\nAyrışma var. Canlı hâli doğruysa repoya alın, değilse ./install.sh koşturun.\n'
    (( missing )) && printf '\nEksik hedef var: ./install.sh\n'
    return $(( drift || missing ))
}

install_all() {
    local ts backup
    ts="$(date +%Y%m%d-%H%M%S)"

    for entry in "${MAP[@]}"; do
        IFS='|' read -r name dest mode <<<"$entry"
        if [[ -f $dest ]] && cmp -s "$SRC/$name" "$dest"; then
            printf '  = %s (değişmemiş)\n' "$dest"
            continue
        fi
        if [[ -e $dest ]]; then
            backup="$dest.bak-$ts"
            $SUDO cp -a "$dest" "$backup"
            printf '  ~ %s → %s\n' "$dest" "$backup"
        fi
        $SUDO install -D -m "$mode" "$SRC/$name" "$dest"
        printf '  → %s\n' "$dest"
    done

    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now vtrgb-tokyonight.service
    printf '\nPalet şimdi yürürlükte (Ctrl+Alt+F2 ile bakılabilir).\n'

    cat <<'EOF'

greetd YENİDEN BAŞLATILMADI ve elle de başlatılmamalı:
`systemctl restart greetd` çalışan oturumu öldürür. Yeni greeter
yapılandırması bir sonraki açılışta (ya da çıkışta) devreye girer.

Geri alma:
  sudo systemctl disable --now vtrgb-tokyonight.service
  sudo cp /etc/greetd/config.toml.bak-<damga> /etc/greetd/config.toml
  sudo rm -f /etc/tuigreet/config.toml
EOF
}

case "${1:-install}" in
    check)   check ;;
    install) install_all ;;
    *)       printf 'kullanım: %s [install|check]\n' "$0" >&2; exit 2 ;;
esac
