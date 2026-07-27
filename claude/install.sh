#!/usr/bin/env bash
# Claude Code ayarlarını bu repodan ~/.claude içine kopyalar.
# Ters yön (bu makinedeki değişiklikleri repoya almak) için: ./save.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude"
BACKUP="$DEST/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Düz dosyalar (varsa kopyalanır, yoksa atlanır)
FILES=(settings.json keybindings.json CLAUDE.md)
# Çalıştırma izni gereken dosyalar
EXEC_FILES=(statusline.sh)
# Tümüyle kopyalanan dizinler
DIRS=(commands agents skills)

mkdir -p "$DEST"
did_backup=0

backup() {
    local target="$1"
    [[ -e $target ]] || return 0
    mkdir -p "$BACKUP"
    cp -a "$target" "$BACKUP/"
    did_backup=1
}

copy_file() {
    local name="$1" mode="$2"
    local from="$SRC/$name" to="$DEST/$name"

    [[ -f $from ]] || return 0
    if [[ -f $to ]] && cmp -s "$from" "$to"; then
        printf '  = %s (değişmemiş)\n' "$name"
        return 0
    fi

    backup "$to"
    install -m "$mode" "$from" "$to"
    printf '  → %s\n' "$name"
}

copy_dir() {
    local name="$1"
    local from="$SRC/$name" to="$DEST/$name"

    [[ -d $from ]] || return 0
    backup "$to"
    rm -rf "$to"
    cp -a "$from" "$to"
    printf '  → %s/\n' "$name"
}

printf 'Claude Code ayarları kuruluyor: %s\n' "$DEST"

for f in "${FILES[@]}"; do copy_file "$f" 644; done
for f in "${EXEC_FILES[@]}"; do copy_file "$f" 755; done
for d in "${DIRS[@]}"; do copy_dir "$d"; done

if (( did_backup )); then
    printf '\nEski dosyalar yedeklendi: %s\n' "$BACKUP"
fi

cat <<'EOF'

Tamamlandı.

Notlar:
  - Kimlik bilgileri (~/.claude/.credentials.json) taşınmaz.
    Yeni makinede bir kez `claude` çalıştırıp /login yapın.
  - Plugin'ler makineye özel kurulur. settings.json içindeki
    enabledPlugins listesi taşındı; plugin'lerin kendisini
    /plugin menüsünden bir kez kurmanız gerekir.
  - Çalışan bir Claude Code oturumu varsa ayarların tümüyle
    devreye girmesi için yeniden başlatın.
EOF
