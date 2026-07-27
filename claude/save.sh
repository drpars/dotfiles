#!/usr/bin/env bash
# Bu makinedeki ~/.claude ayarlarını repoya geri kopyalar.
# Symlink kullanılmadığı için, ayarlarda değişiklik yaptıktan sonra
# bu betiği çalıştırıp commit etmeniz gerekir.
set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HOME/.claude"

FILES=(settings.json keybindings.json CLAUDE.md)
EXEC_FILES=(statusline.sh)
DIRS=(commands agents skills)

changed=0

copy_file() {
    local name="$1" mode="$2"
    local from="$SRC/$name" to="$DEST/$name"

    [[ -f $from ]] || return 0
    if [[ -f $to ]] && cmp -s "$from" "$to"; then
        return 0
    fi

    install -m "$mode" "$from" "$to"
    printf '  ← %s\n' "$name"
    changed=1
}

copy_dir() {
    local name="$1"
    local from="$SRC/$name" to="$DEST/$name"

    [[ -d $from ]] || return 0
    if [[ -d $to ]] && diff -rq "$from" "$to" >/dev/null 2>&1; then
        return 0
    fi

    rm -rf "$to"
    cp -a "$from" "$to"
    printf '  ← %s/\n' "$name"
    changed=1
}

printf 'Ayarlar repoya alınıyor: %s\n' "$DEST"

for f in "${FILES[@]}"; do copy_file "$f" 644; done
for f in "${EXEC_FILES[@]}"; do copy_file "$f" 755; done
for d in "${DIRS[@]}"; do copy_dir "$d"; done

if (( changed )); then
    printf '\nDeğişiklikler alındı. Şimdi commit edebilirsiniz:\n'
    printf '  cd %s && git add claude && git commit\n' "$(dirname "$DEST")"
else
    printf '  = değişiklik yok\n'
fi
