#!/bin/bash
# Claude Code status line
# Gösterilenler: kullanıcı@host/dizin · model · effort · 5s limit · 7g limit · konu
# Not: limit verisi API'den ilk prompt'tan sonra gelir. Bu yüzden gelen
# değerleri önbelleğe yazıyoruz; prompt öncesi veri yokken önbellekten
# okuyup "~" işaretiyle (son bilinen değer) gösteriyoruz.
input=$(cat)

CACHE="$HOME/.claude/.statusline-cache"

# --- Renkler ---
RESET='\033[0m'
DIM='\033[2m'
CYAN='\033[36m'
MAGENTA='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

# --- Temel bilgiler ---
DIR=$(basename "$(echo "$input" | jq -r '.workspace.current_dir // .cwd')")
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')

# --- Limitlere göre renk seçimi ---
pick_color() {
  local pct=${1%%.*}   # ondalığı at
  if   [ -z "$pct" ];        then printf '%b' "$DIM"
  elif [ "$pct" -ge 90 ];    then printf '%b' "$RED"
  elif [ "$pct" -ge 70 ];    then printf '%b' "$YELLOW"
  else                            printf '%b' "$GREEN"
  fi
}

# resets_at (epoch) -> kalan süre "2s 14d" gibi
fmt_reset() {
  local at=$1
  [ -z "$at" ] || [ "$at" = "null" ] && { echo ""; return; }
  local now=$(date +%s)
  local diff=$(( at - now ))
  [ "$diff" -lt 0 ] && diff=0
  local h=$(( diff / 3600 ))
  local m=$(( (diff % 3600) / 60 ))
  if [ "$h" -ge 24 ]; then
    echo "$(( h / 24 ))g $(( h % 24 ))s"
  elif [ "$h" -gt 0 ]; then
    echo "${h}s ${m}d"
  else
    echo "${m}d"
  fi
}

H_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
H_AT=$(echo "$input"  | jq -r '.rate_limits.five_hour.resets_at // empty')
D_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
D_AT=$(echo "$input"  | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Önbellek: canlı veri varsa yaz, yoksa oku ---
STALE=""
if [ -n "$H_PCT" ] || [ -n "$D_PCT" ]; then
  # PID'e özel temp + atomik mv: birden fazla CLI aynı anda yazsa da
  # dosya bozulmaz (limitler hesap geneli olduğu için içerik zaten ortak).
  TMP="$CACHE.tmp.$$"
  {
    printf 'H_PCT=%s\nH_AT=%s\nD_PCT=%s\nD_AT=%s\n' "$H_PCT" "$H_AT" "$D_PCT" "$D_AT"
  } > "$TMP" 2>/dev/null && mv "$TMP" "$CACHE" 2>/dev/null || rm -f "$TMP" 2>/dev/null
elif [ -f "$CACHE" ]; then
  . "$CACHE"
  STALE="~"
fi

# --- Sohbet konusu ---
# Statusline girdisinde hazır bir "konu" alanı yok, ama transcript'te var:
# Claude Code oturum için kendisi bir başlık üretip "ai-title" satırı olarak
# yazıyor (bir kez üretilir, konuşmanın tamamından türer — ilk mesaj "Merhaba..."
# gibi anlamsızsa bile isabetli olur). Sıra:
#   1) elle verilen başlık (custom-title)  2) CLI'ın ürettiği (ai-title)
#   3) hiçbiri yoksa oturumun ilk kullanıcı prompt'u (eski oturumlar için).
# Kısaltma jq içinde yapılır: jq UTF-8 kod noktasıyla sayar, bash ise
# UTF-8 olmayan locale'de bayt sayar ve Türkçe karakteri ortadan böler.
TOPIC_MAX=32
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
TOPIC=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Üç yol da adayı @json ile tek satır olarak verir: prompt çok satırlıysa
  # aşağıdaki "head -n1" yanlışlıkla ilk satırı değil, ilk mesajı alsın diye.
  # grep ön filtresi: MB'larca transcript'i baştan sona jq'ya ayrıştırtmamak için.
  # Boş dizgi adayları ayıklanır, yoksa bir sonraki yola düşmeyi engellerler.
  TOPIC=$(grep -F '"type":"custom-title"' "$TRANSCRIPT" 2>/dev/null | tail -n1 \
          | jq -r '.customTitle | select(type == "string" and length > 0) | @json' 2>/dev/null)
  if [ -z "$TOPIC" ]; then
    TOPIC=$(grep -F '"type":"ai-title"' "$TRANSCRIPT" 2>/dev/null | tail -n1 \
            | jq -r '.aiTitle | select(type == "string" and length > 0) | @json' 2>/dev/null)
  fi
  if [ -z "$TOPIC" ]; then
    # İlk kullanıcı mesajı dosyanın başındadır (sabit maliyet). tool_result'lar
    # dizi içerik taşır, slash komutları <command-...> ile başlar; ikisi de atlanır.
    # Akış kipinde (-s yok) kalıyoruz: canlı yazılan transcript'in son satırı
    # yarım JSON olsa bile önceki geçerli satırlar yine de işlenir.
    TOPIC=$(head -n 40 "$TRANSCRIPT" 2>/dev/null | jq -r '
      select(.type == "user" and (.message.content | type == "string"))
      | .message.content
      | select(length > 0 and (startswith("<") or startswith("Caveat:") | not))
      | @json' 2>/dev/null | head -n1)
  fi
fi
if [ -n "$TOPIC" ]; then
  # Girdi zaten JSON dizgi: jq onu doğrudan ayrıştırır. Boşlukları tek satıra
  # indir, sonra kod noktasına göre kısalt.
  TOPIC=$(printf '%s' "$TOPIC" | jq -r --argjson max "$TOPIC_MAX" '
    gsub("\\s+"; " ") | ltrimstr(" ") | rtrimstr(" ")
    | if length > $max then .[0:$max] + "…" else . end' 2>/dev/null)
  # printf %b ile basıldığı için ters eğik çizgi kaçışlarını etkisizleştir.
  TOPIC=${TOPIC//\\/\\\\}
fi

# --- Parçaları birleştir ---
HOST=${HOSTNAME:-$(uname -n)}
LINE="${DIM}[$(whoami)@${HOST%%.*} ${DIR}]${RESET}"
LINE="${LINE} ${CYAN}${MODEL}${RESET}"
[ -n "$EFFORT" ] && LINE="${LINE} ${DIM}·${RESET} ${MAGENTA}${EFFORT}${RESET}"

if [ -n "$H_PCT" ]; then
  C=$(pick_color "$H_PCT"); R=$(fmt_reset "$H_AT")
  LINE="${LINE} ${DIM}·${RESET} ${DIM}5s${RESET} ${C}${STALE}${H_PCT%%.*}%${RESET}"
  [ -n "$R" ] && LINE="${LINE} ${DIM}(${R})${RESET}"
fi
if [ -n "$D_PCT" ]; then
  C=$(pick_color "$D_PCT"); R=$(fmt_reset "$D_AT")
  LINE="${LINE} ${DIM}·${RESET} ${DIM}7g${RESET} ${C}${STALE}${D_PCT%%.*}%${RESET}"
  [ -n "$R" ] && LINE="${LINE} ${DIM}(${R})${RESET}"
fi

[ -n "$TOPIC" ] && LINE="${LINE} ${DIM}·${RESET} ${DIM}${TOPIC}${RESET}"

printf '%b\n' "$LINE"
