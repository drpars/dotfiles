#!/bin/bash
# Claude Code status line
# Gösterilenler: kullanıcı@host/dizin · model · effort · 5s limit · 7g limit
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

printf '%b\n' "$LINE"
