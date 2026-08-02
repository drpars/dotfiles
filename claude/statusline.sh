#!/bin/bash
# Claude Code status line
# Gösterilenler: kullanıcı@host/dizin · model · effort · 5s limit · 7g limit
#                · bağlam · proje
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

# Oturumun o anki bağlam büyüklüğü. Girdide hazır: total_input_tokens =
# input + cache_creation + cache_read, yani son çağrının okuduğu bağlamın tamamı.
# Kardeşi .context_window.used_percentage BİLEREK kullanılmıyor: o, modelin
# penceresine bölüyor (opus[1m] -> 1e6), yani "taşmak üzere miyim"i ölçer.
# Buradaki soru o değil; her çağrı bağlamın tamamını yeniden okuduğu için
# maliyeti belirleyen şey mutlak boy.
CTX=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')

# --- Limitlere göre renk seçimi ---
pick_color() {
  local pct=${1%%.*}   # ondalığı at
  if   [ -z "$pct" ];        then printf '%b' "$DIM"
  elif [ "$pct" -ge 90 ];    then printf '%b' "$RED"
  elif [ "$pct" -ge 70 ];    then printf '%b' "$YELLOW"
  else                            printf '%b' "$GREEN"
  fi
}

# Bağlam boyu -> renk. Eşik ölçütü "bu oturum 100 çağrı daha sürerse ne yakar":
# çevrim %1 ≈ 0.87M token, yani 150k'da ~%17, 300k'da ~%34 (5 saatlik pencere).
# Ölçülen kaçak oturumlar 500k+'a çıkmıştı. Eşiğin altında soluk kalır — satır
# sakin dursun, göze yalnızca kapanma vakti geldiğinde girsin.
pick_ctx_color() {
  local t=$1
  if   [ "$t" -ge 300000 ]; then printf '%b' "$RED"
  elif [ "$t" -ge 150000 ]; then printf '%b' "$YELLOW"
  else                           printf '%b' "$DIM"
  fi
}

# 64316 -> "64k", 1043000 -> "1.0M"
fmt_tokens() {
  local t=$1
  if [ "$t" -ge 1000000 ]; then
    printf '%d.%dM' $(( t / 1000000 )) $(( (t % 1000000) / 100000 ))
  else
    printf '%dk' $(( (t + 500) / 1000 ))
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

# --- Çalışılan proje (pars çalışma alanı) ---
# Bir oturum tek bir pars alt klasörüne aittir, ama cwd genelde kökte kalır ve
# statusline girdisinde "proje" diye bir alan yok. Sıra:
#   1) cwd zaten bir alt klasörde ise o,
#   2) menüde (AskUserQuestion) verilen SON cevap — oturum ortasında /menu ile
#      proje değişirse de doğru kalsın diye sonuncusu,
#   3) transcript'te EN ÇOK geçen pars/<klasör>/ yolu (menü kullanılmadıysa).
# 2 her zaman 3'ü ezer, 3 de "en son" değil "en çok" bakar: başka bir klasörün
# NOTLAR.md'sini okumak serbest, o yüzden son geçen yol seçili proje olmayabilir.
# Ölçülen örnek: baştan sona archsetup olan bir oturumda (205 geçiş) en son
# geçen yol dotfiles'tı (31 geçiş).
PARS="$HOME/Belgeler/pars"
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
PROJ=""

# Adaylar sırayla denenir; pars altında gerçekten dizin olan ilki kazanır.
# Doğrulama şart: 2. yol menüdeki başka soruların cevaplarını da yakalar,
# 3. yol ise pars/memory gibi dizin olmayan yolları.
first_valid() {
  local n
  while read -r n; do
    [ -n "$n" ] && [ -d "$PARS/$n" ] && { printf '%s\n' "$n"; return; }
  done
}

CWD=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
case "$CWD" in
  "$PARS"/*) PROJ=$(printf '%s\n' "${CWD#"$PARS"/}" | cut -d/ -f1 | first_valid) ;;
esac

if [ -z "$PROJ" ] && [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # İki sinyal de tek grep'te toplanır: dosya bir kez okunur (7 MB'lık
  # transcript'te ~40 ms), gerisi bellekte. Menü cevabı transcript'in başında
  # olduğu için "sondan tara, ilk isabette dur" numarası zaten işe yaramıyordu.
  # Menü cevabı, tool_result metninde  ...\"=\"<cevap>\"  biçiminde geçer.
  SIG=$(grep -oaE '\\"=\\"[a-z0-9][a-z0-9-]*|pars/[a-z0-9][a-z0-9-]*/' "$TRANSCRIPT" 2>/dev/null)
  # tac: birden çok menü cevabı varsa (oturum ortasında /menu) sonuncusu geçerli.
  PROJ=$(printf '%s\n' "$SIG" | grep '^\\' | sed 's/.*"//' | tac | first_valid)
  if [ -z "$PROJ" ]; then
    PROJ=$(printf '%s\n' "$SIG" | grep '^pars/' | sed 's|^pars/||; s|/$||' \
           | sort | uniq -c | sort -rn | sed 's/^ *[0-9]* *//' | first_valid)
  fi
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

# Oturumun ilk çağrısından önce alan 0 gelir; o zaman gösterecek bir şey yok.
if [ -n "$CTX" ] && [ "$CTX" -gt 0 ] 2>/dev/null; then
  C=$(pick_ctx_color "$CTX")
  LINE="${LINE} ${DIM}·${RESET} ${DIM}ctx${RESET} ${C}$(fmt_tokens "$CTX")${RESET}"
fi

[ -n "$PROJ" ] && LINE="${LINE} ${DIM}·${RESET} ${DIM}${PROJ}${RESET}"

printf '%b\n' "$LINE"
