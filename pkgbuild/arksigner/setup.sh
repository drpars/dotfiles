#!/usr/bin/env bash
# e-imza kurulumu — Arch'ta AKIS kartlı e-imzayı ArkSigner ile sıfırdan kurar;
# üreticinin yeni sürümünü, paketi incelenmiş tabanla aynı biçimdeyse kendi
# kurar.
#
# Adımlar; her biri zaten yapılmışsa atlanır, betiği yeniden koşmak güvenli:
#   1. Paketler: ccid (ACR38U-CCID dahil genel okuyucu sürücüsü), pcsc-tools
#      (pcsc_scan), gnutls (p11tool), base-devel (makepkg), python ve
#      diffutils (bu betiğin kendi araçları).
#   2. pcscd.socket etkinleştirilir — Arch'ta varsayılan kapalı.
#   3. ArkSigner. Önce üreticinin sayfası okunur; oradaki sürüm hem PKGBUILD'in
#      hem kurulu olanın sürümünden yeniyse .deb indirilir, SHA-1'i sayfadakine
#      karşı doğrulanır, biçimi baseline.txt ile karşılaştırılır. Aynıysa o
#      sürüm kurulur; değilse kurulmaz ve fark basılır — inceleme gerekir.
#      Yeni sürüm kurulmadıysa: PKGBUILD'in sürümü kurulu değilse ya da kurulu
#      olandan yeniyse o derlenip kurulur.
#   4. Sınama: kurulu ikililerin kütüphaneleri (ldd -r), okuyucu, kart ve
#      karttaki token — salt-okuma, PIN sorulmaz.
#
# "Biçim aynı" ne demek — baseline.txt'deki dört şey, artı bir kapı:
#   ELF dosyalarının NEEDED/RUNPATH kayıtları; .deb'in Depends/Pre-Depends
#   alanı; control.tar'daki bakımcı betiklerinin özeti (arksigner.install
#   onların karşılığı); /usr/lib/arksigner dışına düşen yollar. Kapı: kurulmadan
#   önce açılmış ikililerde `ldd -r` sıfır çözülmeyen kütüphane / tanımsız
#   sembol vermeli. Kapsam paketin biçimi ve dinamik bağlamadır; İMZANIN
#   ÇALIŞTIĞINI SÖYLEMEZ — otomatik güncellemeden sonra bir imza atıp denenir.
#
# PKGBUILD ve baseline.txt son İNCELENMİŞ sürümü tutar; betik ikisine de
# dokunmaz (--baseline hariç), kurulu sürüm onlardan ileride olabilir. Betik
# hiçbir dalda sürüm düşürmez. Derlenen her paket pacman önbelleğine konur;
# geri dönüş `sudo pacman -U /var/cache/pacman/pkg/arksigner-local-<sürüm>-*`.
#
# Kullanım:
#   ./setup.sh             kur, yeni sürüm varsa ve biçimi aynıysa güncelle, sına
#   ./setup.sh --check     yalnız sına ve yeni sürüme bak, hiçbir şey kurma
#   ./setup.sh --rebuild   PKGBUILD'in sürümünü yeniden derle ve kur (kurulu
#                          sürüm ondan ilerideyse reddeder — düşürmez)
#   ./setup.sh --baseline  PKGBUILD'in .deb'inden baseline.txt'yi yeniden üret
#                          (PKGBUILD incelenip güncellendikten sonra)
#
# Çıkış kodu: 0 tamam. 3: kurulum/sınama tamam ama DİKKAT var — yeni sürüm
# kurulmadı ya da sayfa okunamadı (çıktının sonunda yazar); "güncel" ile
# "bakamadım" aynı kodu almasın diye. Diğerleri hata.
#
# Root olarak çalıştırılmaz (makepkg reddeder); kuran adımlar sudo ister.
# Paket listesi `pacman -S` ile kurulur, `-Syu` değil: betik sistemi
# yükseltmez. Paket veritabanı eskiyse indirme 404 alabilir — o zaman önce
# `sudo pacman -Syu`.
#
# Ölçümler ve kararlar yazarın özel notlarında; bu başlık kendi başına yeter.

set -euo pipefail

here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
pkgname=arksigner-local
akis_lib=/usr/lib/arksigner/drivers/akis/x64/libakisp11.so
baseline=$here/baseline.txt
page_url=https://arksigner.com/indir
pkgcache=/var/cache/pacman/pkg
packages=(ccid pcsc-tools gnutls base-devel python diffutils)

work=$(mktemp -d -t arksigner-setup.XXXXXX)
trap 'rm -rf -- "$work"' EXIT
attention=() notices=()
up_ver='' up_dist='' up_sha1='' up_date='' up_url=''

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'HATA: %s\n' "$*" >&2; exit 1; }

usage() {
  sed -n '/^# Kullanım:/,/^#$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

install_packages() {
  say "Paketler: ${packages[*]}"
  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

enable_pcscd() {
  say "pcscd.socket"
  if systemctl is-enabled --quiet pcscd.socket && systemctl is-active --quiet pcscd.socket; then
    echo "zaten etkin ve çalışıyor"
  else
    sudo systemctl enable --now pcscd.socket
  fi
}

is_elf() { cmp -s -n 4 -- "$1" <(printf '\177ELF'); }

elf_files() {  # $1 altındaki ELF dosyaları (symlink değil)
  local f
  while IFS= read -r -d '' f; do
    if is_elf "$f"; then printf '%s\n' "$f"; fi
  done < <(find "$1" -type f -print0 | LC_ALL=C sort -z)
}

installed_elfs() {
  local f
  pacman -Qlq "$pkgname" 2>/dev/null | while IFS= read -r f; do
    if [[ -f $f && ! -L $f ]] && is_elf "$f"; then printf '%s\n' "$f"; fi
  done
}

# ldd -r'nin çözülmeyen kütüphane / tanımsız sembol satırları; boşsa temiz.
# Pozitif kontrol (3.0.12): sahte libpoppler-qt5.so.1 → 9, sahte
# libqpdf.so.30 → 16 tanımsız sembol, yalnız arksigner-management'ta;
# arksigner-bes ve -service ikisinden de sembol almıyor. Yani kapı tek ikiliye
# kurulsaydı kör kalabilirdi.
ldd_problems() {
  local f
  for f; do
    LC_ALL=C ldd -r "$f" 2>&1 | grep -E 'not found|undefined symbol' |
      sed "s|^|${f##*/}: |" || true
  done
}

# .deb'in biçimi: baseline.txt'nin satırları. $2 boş bir dizin; .deb oraya
# açılır, açılan ağacı çağıran ldd kapısı için kullanır.
deb_shape() (
  export LC_ALL=C
  local deb=$1 d=$2 f tag val
  mkdir -p "$d/data" "$d/control" || exit 1
  bsdtar -O -xf "$deb" 'data.tar*' | bsdtar -C "$d/data" -xf - || exit 1
  bsdtar -O -xf "$deb" 'control.tar*' | bsdtar -C "$d/control" -xf - || exit 1

  # Paket başına bir satır, sıralı: fark yalnız değişen paketi gösterir.
  # Debian alanı devam satırlarıyla sürebilir.
  awk '
    /^[^ \t]/ {
      keep = /^(Pre-)?Depends:/
      if (keep) { f = $1; sub(/:$/, "", f); $0 = substr($0, index($0, ":") + 1) }
    }
    keep {
      n = split($0, a, ",")
      for (i = 1; i <= n; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", a[i])
        if (a[i] != "") print "control " f " " a[i]
      }
    }' "$d/control/control" | sort || exit 1
  # control ve md5sums her sürümde değişir (Version, özetler); gerisi bakımcı
  # betikleri ve benzeri — içerikleri özetle.
  for f in "$d/control"/*; do
    case ${f##*/} in control|md5sums) continue ;; esac
    printf 'script %s %s\n' "${f##*/}" "$(sha256sum < "$f" | cut -d' ' -f1)"
  done
  (cd "$d/data" && find . ! -type d ! -path './usr/lib/arksigner/*' \
    \( -type l -printf 'path %P -> %l\n' -o -printf 'path %P\n' \)) | sort
  while IFS= read -r -d '' f; do
    is_elf "$d/data/$f" || continue
    readelf -d "$d/data/$f" |
      sed -n 's/.*(\(NEEDED\|RUNPATH\|RPATH\)).*\[\(.*\)\]/\1 \2/p' |
      while read -r tag val; do printf 'elf %s %s %s\n' "$f" "$tag" "$val"; done
  done < <(cd "$d/data" && find . -type f -printf '%P\0') | sort
)

# Üretici sayfasındaki Linux .deb'i: "sürüm dağıtım sha1 tarih url". Bağlantı
# ya da o sürümün SHA-1'i tek değilse — sayfa değişmiş demektir — hata döner;
# "bulunamadı" hiçbir dalda "güncel" diye okunmasın.
upstream_latest() {
  curl -fsSL --max-time 30 -o "$work/page.html" "$page_url" || return 1
  python3 -I - "$work/page.html" <<'PY'
import html, re, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
urls = {m.group(0) for m in re.finditer(
    r"https?://[^\s\"'<>]+/arksigner_[0-9][0-9.]*_[A-Za-z0-9.]+_amd64\.deb", raw)}
if len(urls) != 1:
    sys.exit(f"sayfada Linux .deb bağlantısı tek değil: {sorted(urls) or 'hiç yok'}")
url = urls.pop()
m = re.search(r"arksigner_([0-9](?:[0-9.]*[0-9])?)_([A-Za-z0-9.]+)_amd64\.deb$", url)
if not m:
    sys.exit(f"bağlantıdan sürüm okunamadı: {url}")
ver, dist = m.groups()
text = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", raw)))
pairs = {(d, h.lower()) for v, d, h in re.findall(
    r"Versiyon ([0-9][0-9.]*[0-9]) Versiyon Tarihi (\S+) Özet \(SHA-1\) ([0-9A-Fa-f]{40})",
    text) if v == ver}
if len(pairs) != 1:
    sys.exit(f"sayfada {ver} için tarih/SHA-1 tek değil: {sorted(pairs) or 'hiç yok'}")
date, sha1 = pairs.pop()
print(ver, dist, sha1, date, url)
PY
}

# PKGBUILD'in yeni sürüme uyarlanmış kopyası (stdout). Yalnız beş satır
# değişir; her biri tam bir kez eşleşmezse hata — PKGBUILD'in biçimi değişmiş.
render_pkgbuild() {  # sürüm dağıtım sha1 sha256
  awk -v ver="$1" -v dist="$2" -v s1="$3" -v s256="$4" '
    /^_debver=/    { print "_debver=" ver;                  n[1]++; next }
    /^_debdist=/   { print "_debdist=" dist;                n[2]++; next }
    /^pkgrel=/     { print "pkgrel=1";                      n[3]++; next }
    /^sha1sums=/   { print "sha1sums=(\047" s1 "\047)";     n[4]++; next }
    /^sha256sums=/ { print "sha256sums=(\047" s256 "\047)"; n[5]++; next }
    { print }
    END { for (i = 1; i <= 5; i++) if (n[i] != 1) exit 1 }
  ' "$here/PKGBUILD"
}

# $1'i PKGBUILD olarak derler, paketi pacman önbelleğine koyar (geri dönüş
# için) ve kurar. makepkg -p betiği çalışılan dizinin içinde istiyor ve
# .install'ı da orada arıyor; kopya yerine symlink. Hata yolları açık
# `return 1`: koşullu bağlamdan da çağrılıyor, orada set -e işlemez.
build_and_install() {
  local b=$work/build pkg
  rm -rf -- "$b" && mkdir -p "$b" "$work/src" || return 1
  ln -s "$1" "$b/PKGBUILD" && ln -s "$here/arksigner.install" "$b/arksigner.install" ||
    return 1
  (
    cd "$b" || exit 1
    export BUILDDIR="$b" SRCDEST="$work/src" PKGDEST="$b" LOGDEST="$b"
    makepkg -s --noconfirm -f
  ) || return 1
  pkg=$(find "$b" -maxdepth 1 -name "$pkgname-*.pkg.tar*" ! -name '*.sig') || return 1
  if [[ -z $pkg || $pkg == *$'\n'* ]]; then
    echo "derlenen paket bulunamadı ya da tek değil" >&2
    return 1
  fi
  sudo install -m644 -t "$pkgcache" "$pkg" || return 1
  sudo pacman -U --noconfirm "$pkgcache/${pkg##*/}" || return 1
  echo "paket önbellekte: $pkgcache/${pkg##*/}"
}

# Sayfadaki sürüm hem PKGBUILD'inkinden hem kurulu olandan yeniyse 0 döner ve
# up_* değişkenlerini doldurur. Sayfa okunamazsa "güncel" demez: DİKKAT'e yazar.
upstream_newer() {  # kurulu (boş olabilir), PKGBUILD sürümü
  local have=$1 want=$2 line
  say "Üretici sayfası: $page_url"
  if ! line=$(upstream_latest); then
    attention+=("üretici sayfası okunamadı — yeni sürüm olup olmadığı BİLİNMİYOR")
    return 1
  fi
  read -r up_ver up_dist up_sha1 up_date up_url <<<"$line"
  echo "sayfada $up_ver ($up_date)"
  if (( $(vercmp "$up_ver" "${want%-*}") <= 0 )); then
    echo "yeni değil (PKGBUILD ${want%-*})"
    return 1
  fi
  if [[ -n $have ]] && (( $(vercmp "$up_ver-1" "$have") <= 0 )); then
    echo "yeni değil (kurulu $have)"
    return 1
  fi
}

# Yeni sürümü indirir, SHA-1'ini sayfaya karşı doğrular, biçimini tabanla
# karşılaştırır, ldd kapısından geçirir; hepsi tutarsa PKGBUILD'in üretilmiş
# kopyasıyla derleyip kurar. Tutmazsa kurmaz, sebebi DİKKAT'e yazar. Koşullu
# bağlamdan çağrılıyor: hata yolları açık `return 1`.
install_upstream() {  # kurulu sürüm (boş olabilir)
  local have=$1 deb=$work/src/arksigner-$up_ver.deb sha256 problems old=''
  local -a elfs
  say "Yeni sürüm $up_ver: indir, doğrula, tabanla karşılaştır"
  if [[ ! -r $baseline ]]; then
    attention+=("baseline.txt yok — $up_ver karşılaştırılamadı, kurulmadı (./setup.sh --baseline)")
    return 1
  fi
  mkdir -p "$work/src" || return 1
  if ! curl -fsSL --max-time 600 -o "$deb" "$up_url"; then
    attention+=("$up_ver indirilemedi: $up_url")
    return 1
  fi
  if [[ $(sha1sum < "$deb" | cut -d' ' -f1) != "$up_sha1" ]]; then
    attention+=("$up_ver: indirilen dosyanın SHA-1'i sayfadakiyle tutmuyor — kurulmadı")
    return 1
  fi
  sha256=$(sha256sum < "$deb" | cut -d' ' -f1)
  echo "SHA-1 sayfadakiyle tutuyor"

  if ! deb_shape "$deb" "$work/new" > "$work/new.shape"; then
    attention+=("$up_ver: .deb açılamadı — kurulmadı")
    return 1
  fi
  if ! diff -u --label baseline.txt --label "$up_ver" \
      <(grep -v '^#' "$baseline") "$work/new.shape"; then
    attention+=("$up_ver: paketin biçimi tabanla aynı değil (fark yukarıda) — kurulmadı, inceleme gerekiyor")
    return 1
  fi
  echo "biçim tabanla aynı"

  mapfile -t elfs < <(elf_files "$work/new/data")
  problems=$(ldd_problems "${elfs[@]}")
  if [[ -n $problems ]]; then
    printf '%s\n' "$problems"
    attention+=("$up_ver: ldd çözülmeyen kütüphane / tanımsız sembol buldu (yukarıda) — kurulmadı")
    return 1
  fi
  echo "ldd -r: ${#elfs[@]} ELF dosyası, sorun yok"

  if [[ -n $have ]]; then
    old=$(compgen -G "$pkgcache/$pkgname-$have-*.pkg.tar*" | grep -v '\.sig$' | head -n1) || true
    [[ -n $old ]] || attention+=("geri dönüş paketi yok: $have önbellekte değil ($pkgcache)")
  fi
  if ! render_pkgbuild "$up_ver" "$up_dist" "$up_sha1" "$sha256" > "$work/PKGBUILD"; then
    attention+=("PKGBUILD $up_ver için uyarlanamadı (beş satırdan biri tek değil) — kurulmadı")
    return 1
  fi
  if ! build_and_install "$work/PKGBUILD"; then
    attention+=("$up_ver derlenemedi ya da kurulamadı")
    return 1
  fi
  notices+=("ArkSigner $up_ver otomatik kuruldu. Bir imza atıp deneyin — biçim kontrolleri imzanın çalıştığını söylemez.")
  [[ -z $old ]] || notices+=("İmza bozulursa geri dönüş: sudo pacman -U $old")
}

# Adım 3. $1: install | rebuild | check (check hiçbir şey kurmaz).
arksigner_step() {
  local mode=$1 want have
  want=$( (cd "$here" && makepkg --printsrcinfo) |
    awk '$1=="pkgver"{v=$3} $1=="pkgrel"{r=$3} END{print v "-" r}')
  have=$(pacman -Q "$pkgname" 2>/dev/null | awk '{print $2}') || true
  say "ArkSigner: PKGBUILD $want, kurulu ${have:-yok}"

  if [[ $mode == rebuild ]]; then
    if [[ -n $have ]] && (( $(vercmp "$have" "$want") > 0 )); then
      die "kurulu sürüm ($have) PKGBUILD'dekinden ($want) ileride; --rebuild sürüm düşürürdü. Geri dönüş isteniyorsa: sudo pacman -U $pkgcache/$pkgname-<sürüm>-*"
    fi
    build_and_install "$here/PKGBUILD"
    return
  fi

  if upstream_newer "$have" "$want"; then
    if [[ $mode == check ]]; then
      attention+=("yeni sürüm var: $up_ver ($up_date) — ./setup.sh biçimi tabanla aynıysa kurar")
      return
    fi
    if install_upstream "$have"; then return; fi
  fi
  [[ $mode != check ]] || return 0

  if [[ -z $have ]] || (( $(vercmp "$want" "$have") > 0 )); then
    build_and_install "$here/PKGBUILD"
  elif (( $(vercmp "$want" "$have") < 0 )); then
    echo "kurulu $have, incelenmiş PKGBUILD'den ($want) ileride — otomatik güncellenmiş; dokunulmuyor"
  else
    echo "güncel, derlenmiyor (zorlamak için --rebuild)"
  fi
}

# PKGBUILD'in .deb'ini indirir, iki özetini PKGBUILD'e karşı doğrular ve
# biçimini baseline.txt'ye yazar. PKGBUILD incelenip güncellendikten sonra
# koşulur; iki dosya birlikte commit'lenir.
write_baseline() {
  local info src name url want deb
  info=$(cd "$here" && makepkg --printsrcinfo)
  src=$(awk '$1=="source"{print $3; exit}' <<<"$info")
  name=${src%%::*} url=${src#*::}
  want=$(awk '$1=="pkgver"{v=$3} $1=="pkgrel"{r=$3} END{print v "-" r}' <<<"$info")
  deb=$work/src/$name
  say "Taban: $url"
  mkdir -p "$work/src"
  curl -fsSL --max-time 600 -o "$deb" "$url"
  [[ $(sha1sum < "$deb" | cut -d' ' -f1) == "$(awk '$1=="sha1sums"{print $3; exit}' <<<"$info")" ]] ||
    die "SHA-1 PKGBUILD'dekiyle tutmuyor"
  [[ $(sha256sum < "$deb" | cut -d' ' -f1) == "$(awk '$1=="sha256sums"{print $3; exit}' <<<"$info")" ]] ||
    die "SHA-256 PKGBUILD'dekiyle tutmuyor"
  {
    echo "# setup.sh --baseline ile üretildi, elle düzenlenmez."
    echo "# Kaynak: ${url##*/} (PKGBUILD $want). Anlamı: setup.sh başlığı."
    deb_shape "$deb" "$work/base"
  } > "$work/baseline.txt"
  mv -f -- "$work/baseline.txt" "$baseline"
  echo "yazıldı: $baseline ($(grep -vc '^#' "$baseline") satır)"
}

check() {
  local out problems
  local -a elfs
  say "Sınama (salt-okuma)"

  if ! systemctl is-active --quiet pcscd.socket; then
    echo "pcscd.socket çalışmıyor — kurulum adımı 2 eksik"
    return 1
  fi

  # ArkSigner yalnız üretici güncelleyince değil, Arch güncelleyince de bozulur:
  # ikililer sürümü sabit soname istiyor (libqpdf.so.30, libpoppler-qt5.so.1).
  echo "-- ArkSigner ikilileri: çözülmeyen kütüphane / tanımsız sembol (ldd -r)"
  mapfile -t elfs < <(installed_elfs)
  if (( ${#elfs[@]} == 0 )); then
    echo "$pkgname kurulu değil"
    return 1
  fi
  problems=$(ldd_problems "${elfs[@]}")
  if [[ -n $problems ]]; then
    printf '%s\n' "$problems"
    echo "ArkSigner bu sistemin kütüphaneleriyle bağlanamıyor — bir Arch güncellemesi soname değiştirmiş olabilir"
    return 1
  fi
  echo "${#elfs[@]} ELF dosyası, sorun yok"

  echo "-- okuyucular (pcsc_scan -r)"
  timeout 10 pcsc_scan -r 2>&1 | sed -n '/^Scanning/,$p' || true

  out=$(timeout 10 pcsc_scan -c 2>&1 || true)
  if grep -q 'Card inserted' <<<"$out"; then
    echo "-- kart takılı: $(grep -m1 'ATR:' <<<"$out" | sed 's/^ *//')"
  else
    echo "-- kart takılı görünmüyor (pcsc_scan -c çıktısında 'Card inserted' yok):"
    sed -n '/^Scanning/,$p' <<<"$out"
    return 0
  fi

  if [[ -r $akis_lib ]] && command -v p11tool >/dev/null; then
    echo "-- AKIS PKCS#11 token (p11tool --list-tokens, girişsiz)"
    timeout 60 p11tool --provider "$akis_lib" --list-tokens 2>&1 |
      grep -E 'Label:|Manufacturer:|Model:' || echo "token listelenemedi"
  fi
}

main() {
  local mode=install rc=0
  case "${1:-}" in
    '') ;;
    --check) mode=check ;;
    --rebuild) mode=rebuild ;;
    --baseline) mode=baseline ;;
    -h|--help) usage ;;
    *) usage 2 ;;
  esac

  [[ $EUID -ne 0 ]] || die "root olarak değil, kendi kullanıcınızla çalıştırın"
  command -v pacman >/dev/null || die "pacman yok — bu betik Arch içindir"

  if [[ $mode == baseline ]]; then
    write_baseline
    return
  fi
  if [[ $mode != check ]]; then
    install_packages
    enable_pcscd
  fi
  arksigner_step "$mode"
  check || rc=$?

  if [[ $mode != check ]]; then
    say "Tarayıcılar"
    echo "Firefox: ArkSigner eklentisini kurduran politika /etc/firefox/policies/"
    echo "  altında; politika Firefox açılışında okunur."
    echo "Chrome: harici eklenti kaydı /opt/google/chrome/extensions/ altında."
  fi
  if (( ${#notices[@]} )); then
    say "Sonra"
    printf '  %s\n' "${notices[@]}"
  fi
  if (( ${#attention[@]} )); then
    say "DİKKAT"
    printf '  %s\n' "${attention[@]}"
    (( rc )) || rc=3
  fi
  return "$rc"
}

# Kaynak olarak da okunabilsin (fonksiyonları tek tek sınamak için).
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
