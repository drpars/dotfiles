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
#   1) cwd zaten bir alt klasördeyse o,
#   2) transcript'teki AÇIK SEÇİM — `/menu <ad>`, ya da argümansız `/menu` +
#      kullanıcının yazdığı numara; ikisinden dosyada SONRA geçen kazanır,
#   3) transcript'te İLK geçen pars/<klasör>/ yolu (menü hiç kullanılmadıysa).
#
# 2 ve 3 2026-08-21'de değişti; ikisi de ölçülerek (445 transcript; yer doğrusu
# = oturumun hangi projenin NOTLAR.md / arsiv-*.md dosyasını YAZDIĞI — başka
# projeninkine yazmak zaten yasak olduğu için bu sinyal sezgisellerden bağımsız;
# 214 oturumda tek proje çıkıyor):
#   - Eski 2. öncelik `AskUserQuestion` cevabıydı ve ÖLÜYDÜ: /menu artık o aracı
#     kullanmıyor (CLAUDE.md, "AKIŞ — oturum başlangıcı"). Ölçüldü: 445
#     oturumun yalnız 8'inde geçerli bir sonuç veriyor, yani pratikte her oturum
#     doğrudan 3. önceliğe düşüyordu.
#   - Eski 3. öncelik "EN ÇOK geçen" yoldu ve YAPIŞKAN DEĞİLDİ: sayaç her
#     render'da baştan hesaplanıyor, başka projenin NOTLAR.md'sini okumak da
#     serbest — okunan klasör oturum ortasında öne geçip adı sessizce
#     değiştiriyordu. Bildirilen arıza buydu.
# Oturum içinde ad değiştiren oturum 18 -> 1 (%8,4 -> %0,5), toplam ad değişimi
# 25 -> 1; kalan tek oturum kullanıcının ikinci kez /menu yapması. Takasın
# bedeli de yazılı: son değer doğruluğu 210 -> 207. Kaybedilen 7 oturumun 3'ünde
# kullanıcı açık seçim yapmış ve iş sonra başka klasöre kaymış (orada iki cevap
# da savunulabilir), 3'ü yedek yolun bedeli, 1'i artık silinmiş bir klasör.
# Kazanılan 4 oturumun dördü de bildirilen arızanın ta kendisiydi. Hız ölçüldü
# (7 MB'lık en büyük transcript, GNU grep, çıktı boruya): 72 ms -> 48 ms.
# Türetim -> pars/claude-cli-ayarlari/arsiv-2026-08.md § 2026-08-21;
# kurulum ve bu makinede yeniden ölçümü -> pars/dotfiles/arsiv-2026-08.md.
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
  # Geçerli klasör listesi bir kez, fork'suz kuruluyor. (awk içinde
  # system("test -d ...") ad başına bir kabuk açıyordu; transcript'te geçen her
  # ayrı geçersiz ad — scratchpad yolundaki oturum uuid'leri — bir fork demek,
  # tek başına 175 ms.)
  DIRS=""
  for d in "$PARS"/*/; do d=${d%/}; DIRS="$DIRS,${d##*/},"; done

  # 2) AÇIK SEÇİM. Satır seçimi sabit dizgiyle: aynı işi yapan tek geçişli -oE
  # deseni 7 MB'lık transcript'te 173 ms sürüyor (alternasyon süperadditif,
  # parçalar tek tek 1-4 ms), bu 11 ms. Menü başlığı için iki çapa birden
  # veriliyor — hook metni değişirse biri sağ kalsın.
  PROJ=$(grep -naF -e '<command-args>' -e '"role":"user","content":"' \
                   -e 'kaynak=' -e 'alanındaki projeler' "$TRANSCRIPT" 2>/dev/null |
  awk -v dirs="$DIRS" '
    function valid(n) { return (n != "" && index(dirs, "," n ",") > 0) }
    {
      # Menü listesi: " 6) dotfiles" -> map[6]="dotfiles". Liste tek bir kayıtta
      # geldiği için harita satır başına sıfırlanıyor; bayat girdi kalmıyor.
      s = $0; built = 0
      while (match(s, /[0-9]+\) [a-z0-9-]+/)) {
        t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        num = t; sub(/\).*/, "", num)
        nm  = t; sub(/^[0-9]+\) /, "", nm)
        if (valid(nm)) { if (!built) { delete map; built = 1 }; map[num] = nm }
      }
      # Buradan sonrası yalnız KULLANICININ kendi kaydı; iki koşul da şart.
      # Asistan kaydı çalıştırdığım komut metnini taşır, araç çıktısı da
      # "type":"user" kaydıdır ama "toolUseResult" alanı vardır. Bu ayrım
      # olmadan transcript grepleyen oturum kendi çıktısını seçim sinyali sayar
      # (ölçüldü: hem türetme hem kurulum oturumu kendini "archsetup"
      # gösteriyordu) — pgrep -f in kendi kabuğunu bulmasıyla aynı sınıf.
      if (!index($0, "\"type\":\"user\"") || index($0, "toolUseResult")) next
      if (match($0, /<command-args>[a-z0-9-]*<\/command-args>/)) {
        t = substr($0, RSTART + 14, RLENGTH - 29)
        if (valid(t)) sel = t
      }
      if (match($0, /"role":"user","content":"[^"]*"/)) {
        t = substr($0, RSTART + 25, RLENGTH - 26)
        # Numara BİR KEZ tüketilir: menüden sonraki ilk sayı cevabı seçimdir,
        # oturumun ilerisindeki alâkasız bir sayı değil. Ölçüldü — tüketmeyen
        # sürüm, menüye "3" (doğru cevap) dendikten sonra gelen bir "1"i seçim
        # sanıp adı archsetup yapıyordu; tüketen sürüm o oturumu kazanıyor ve
        # başka hiçbir oturumun cevabını değiştirmiyor.
        if (t ~ /^[0-9]+$/) { if (t in map) { sel = map[t]; delete map } }
        else if (valid(t)) sel = t
      }
    }
    END { print sel }')

  # 3) YEDEK: transcript'te geçen İLK geçerli yol — "en çok geçen" değil, çünkü
  # aranan şeyin kendisi yapışkanlık. first_valid ilk isabette dönünce boru
  # kapanıyor ve grep SIGPIPE ile erken çıkıyor: tam tarama 34 ms, böyle 19 ms.
  if [ -z "$PROJ" ]; then
    PROJ=$(grep -oaE 'pars/[a-z0-9][a-z0-9-]*/' "$TRANSCRIPT" 2>/dev/null |
           sed 's|^pars/||; s|/$||' | first_valid)
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
