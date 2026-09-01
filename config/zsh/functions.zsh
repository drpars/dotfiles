# Functions
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
	_yazi_pkg_check
}

# Eklentiler geride mi -- gunde bir, yazi KAPANDIKTAN sonra, SALT-OKUMA.
#
# Neden burasi: gercek tetik yazi'nin PAKET SURUMU, ve seyrek atesliyor.
# Olculdu (pacman.log tek dosya, 2026-07-28 kurulumundan beri, rotasyon yok):
# icinde toplam IKI yazi satiri var -- installed 26.5.6-4 (07-29), upgraded
# 26.8.15-1 (08-22 16:58). Olay ayda bir; `y` gunde defalarca kosuyor, aradaki
# farki gunluk damga kapatiyor. Cagri yazi KAPANDIKTAN sonra, cunku eklenti
# kodu zaten bir sonraki acilista yukleniyor -- acilisi geciktirmesinin karsiligi yok.
#
# Neden `ya pkg upgrade` DEGIL: (a) komut package.toml'u ve eklenti agacini
# YERINDE yeniden yazar, ve ikisi de sürümlenen dosya -- sonraki oturumun
# `git status --short`'u kimsenin dokunmadigi kirli dosyalar gorur; (b) kosan
# eklenti kodunu gozden gecirmeden degistirir. Burada yalnizca SORULUYOR:
# yukseltmeyi kullanici baslatir, diff'i okur, commit eder.
#
# Neden aracin kendisi degil: `ya pkg` alt komutlari add/delete/install/list/
# upgrade -- check ya da dry-run YOK, ve `ya pkg list` yalnizca YEREL rev
# basiyor (olculdu: cagri package.toml'un sha256'sini degistirmiyor, cikti da
# uzak sutunu tasimiyor). Yani "lazim mi" sorusunun aracin icinde cevabi yok;
# dedektor `git ls-remote <depo> HEAD`.
#
# Depo adi kurali olculdu: `use` icinde ":" varsa monorepo (yazi-rs/plugins),
# yoksa depo adinin sonuna ".yazi" gelir (KKV9/compress -> compress.yazi).
# 15 girdi -> 8 benzersiz depo; sekizi de rc=0 ve gercek SHA dondurdu.
#
# TUZAK: `ls-remote --heads` KULLANILMAZ. Tum dallari alfabetik listeler ve
# ilk satir varsayilan dal DEGILDIR; bu okuma bir kez "compress geride"
# dedirtti, degildi. Sorulan sey HEAD.
#
# Maliyet olculdu: 8 depo paralel ~0,7-1,0 s, gunde BIR kez; damga tazeyken
# 7 ms. Ag yoksa sessiz gecer ve damga YAZILMAZ -- ertesi kosu yeniden dener.
# Damga ~/.local/state altinda, ~/.config/yazi'da DEGIL: orasi depo, damga
# her gun bir diff satiri olurdu.
function _yazi_pkg_check() {
	local pt="${XDG_CONFIG_HOME:-$HOME/.config}/yazi/package.toml"
	local stamp="${XDG_STATE_HOME:-$HOME/.local/state}/yazi/.pkg-check"
	local today=${(%):-%D{%F}}
	[[ -r $pt ]] || return 0
	[[ -f $stamp && $(<$stamp) == $today ]] && return 0

	local -A want
	local line use rev repo
	while IFS= read -r line; do
		case $line in
			(use\ =\ *) use=${${line#*\"}%\"} ;;
			(rev\ =\ *) rev=${${line#*\"}%\"}
				[[ $use == *:* ]] && repo=${use%%:*} || repo=$use.yazi
				want[$repo]=$rev ;;
		esac
	done < $pt
	(( ${#want} )) || return 0

	local tmp=${$(mktemp -d):-}
	[[ -n $tmp ]] || return 0
	for repo in ${(k)want}; do
		( local out=$(GIT_TERMINAL_PROMPT=0 git ls-remote "https://github.com/$repo" HEAD 2>/dev/null)
		  print -r -- "$repo ${out[1,7]}" > $tmp/${repo//\//_} ) &
	done
	wait

	local -a behind
	local answered=0 f h
	for f in $tmp/*(N); do
		read -r repo h < $f
		[[ -n $h ]] || continue
		(( answered++ ))
		[[ $h == ${want[$repo]} ]] || behind+=( ${repo%.yazi} )
	done
	rm -rf $tmp
	(( answered )) || return 0
	mkdir -p ${stamp:h} && print -r -- $today > $stamp

	(( ${#behind} )) && print -P -- "%F{#e0af68}yazi eklentileri geride%f: ${(j:, :)behind} — %F{#7aa2f7}ya pkg upgrade%f"
	return 0
}

# ~/.ssh altindaki tum ozel anahtarlari agent'a yukler.
#
# Neden fonksiyon: duz `ssh-add ~/.ssh/*` her cagrida ZATEN YUKLU anahtarlarin
# passphrase'ini de yeniden sorar. Burada once agent'taki parmak izleri
# okunuyor, eslesenler atlaniyor -- tekrar cagirmak bedava, yalnizca eksik
# olan sorulur.
#
# Anahtar listesi makineye gomulmuyor: .pub'i olan her ozel anahtar aday.
# Boylece anahtar adlari makineden makineye degisse de calisir ve yeni anahtar
# eklendiginde burasi guncellenmez.
#
# Ne zaman gerekir: agent bosaldiginda (kullanici oturumu yenilenince oluyor)
# git commit imzalari ve uzak baglantilar passphrase istemeye baslar.
function sshkeys() {
	local h ok warn dim r
	if [[ -t 1 ]]; then
		h=$'%B%F{#7aa2f7}'
		ok=$'%B%F{#9ece6a}'
		warn=$'%B%F{#e0af68}'
		dim=$'%F{#565f89}'
		r=$'%b%f'
	fi

	# ssh-add -l: 0 = anahtar var, 1 = agent bos, 2 = agent'a ulasilamiyor.
	# Ucuncusu bambaska bir ariza, "bos" ile karistirilmamali.
	local listing
	listing=$(ssh-add -l 2>/dev/null)
	if (( $? == 2 )); then
		print -P "${warn}ssh-agent'a ulasilamiyor${r} ${dim}(SSH_AUTH_SOCK bos ya da olu soket)${r}"
		return 2
	fi

	local -a loaded
	loaded=(${(f)"$(print -r -- $listing | awk '{print $2}')"})

	local -a added failed
	local -i skipped=0
	local pub key fp
	# (N): eslesme yoksa desen literal olarak kalmasin.
	for pub in ~/.ssh/*.pub(N); do
		key=${pub%.pub}
		[[ -f $key ]] || continue

		fp=$(ssh-keygen -lf "$pub" 2>/dev/null | awk '{print $2}')
		if [[ -n $fp ]] && (( ${loaded[(I)$fp]} )); then
			(( skipped++ ))
			continue
		fi

		if ssh-add "$key"; then
			added+=(${key:t})
		else
			failed+=(${key:t})
		fi
	done

	(( $#added )) && print -P "${ok}==> Eklendi:${r} ${(j:, :)added}"
	(( skipped )) && print -P "${dim}    Zaten yuklu: ${skipped} anahtar${r}"

	if (( $#failed )); then
		print -P "${warn}==> Eklenemedi:${r} ${(j:, :)failed}"
		return 1
	fi
	if (( $#added == 0 && skipped == 0 )); then
		print -P "${warn}~/.ssh altinda .pub'i olan ozel anahtar bulunamadi${r}"
		return 1
	fi
	return 0
}

# Tam guncelleme: resmi depolar + AUR + VCS paketlerinin yeniden derlenmesi.
# `update` (sudo pacman -Syu) AUR'a dokunmadigi icin kismi yukseltme penceresi
# aciliyor; bir kutuphanenin soname'i degisince AUR paketleri yeniden derlenene
# kadar bozuk kalabilir. Bu fonksiyonun isi o pencereyi kapatmak.
#
# Yukseltme basarisiz olursa orada durur -- .pacnew raporu yarim kalmis bir
# guncellemenin uzerine yaniltici bilgi vermesin.
#
# Renkler colors.zsh'teki TokyoNight fzf degerleriyle ayni. Cikti terminale
# gitmiyorsa (`full-update > log`) degiskenler bos kalir ve kod uretilmez.
function full-update() {
	# %B once, %F sonra: ters sirada zsh rengi iki kez yaziyor.
	local h ok warn dim cmd r
	if [[ -t 1 ]]; then
		h=$'%B%F{#7aa2f7}'      # bolum basligi
		ok=$'%B%F{#9ece6a}'     # basari
		warn=$'%B%F{#e0af68}'   # dikkat gerektiren
		dim=$'%F{#565f89}'      # ikincil bilgi
		cmd=$'%F{#2ac3de}'      # kopyalanacak komut
		r=$'%b%f'
	fi

	local -i start=$SECONDS
	print -P "${h}==> Tam guncelleme${r} ${dim}resmi depolar + AUR + VCS yeniden derleme${r}"

	yay -Syu --devel "$@" || {
		local -i rc=$?
		print -P "${warn}==> Yukseltme yarim kaldi (cikis $rc); .pacnew denetimi atlandi.${r}"
		return $rc
	}

	# Birlestirilmemis .pacnew/.pacsave dosyalari sessizce birikir ve aylar
	# sonra "guncellemeden sonra bozuldu" olarak geri doner. Yalnizca listele:
	# hicbir sey kendiliginden birlestirilmez.
	local -a diffs
	diffs=(${(f)"$(pacdiff -o 2>/dev/null)"})
	if (( $#diffs )); then
		print -P "${warn}==> Yapilandirma: elle bakilmasi gereken ${#diffs} dosya${r}"
		# Dosya adlari `print -P` ile basilmaz: icindeki % isareti bicim
		# dizisi sanilir.
		print -l -- ${diffs/#/      }
		# `-s` editoru sudoedit ile acar: editor KULLANICI olarak kosar,
		# root yalnizca geri yazma aninda devreye girer. `sudo -E pacdiff`
		# degil -- `-E` HOME'u ve EDITOR'u tasidigi icin nvim root olarak
		# kullanicinin config'ini yukler ve lazy'nin yazdigi her sey root'a
		# kalir (2026-08-30: ~/.local/share/nvim/lazy altinda 15 dosya).
		print -P "    Birlestirmek icin: ${cmd}pacdiff -s${r}"
	else
		print -P "${ok}==> Yapilandirma temiz${r} ${dim}(birlestirilmemis .pacnew yok)${r}"
	fi

	local -i took=$(( SECONDS - start ))
	local sure
	if (( took >= 60 )); then
		sure="$(( took / 60 )) dk $(( took % 60 )) sn"
	else
		sure="${took} sn"
	fi
	print -P "${ok}==> Bitti${r} ${dim}(${sure})${r}"
}

# claude sarmalayicisi: parolasiz sudo penceresini claude'un omruyle sinirlar.
#
# Pencereyi ACMAZ, yalnizca kapatir. Acmak elle bir karar olarak kalmali:
# pencere acikken bu kullanici adina calisan her sey parolasiz root'a ulasiyor,
# oysa claude oturumlarinin cogu sudo'ya hic dokunmuyor. Acilis `csudo on`.
#
# Neden gerekli: kapatmayi bugun oturumun kendisi yapiyor. Unutursa ya da
# cakilirsa yetki bir sonraki logout'a kadar acik kaliyor -- tmpfs ve
# claude-sudo.service duruyor ama aradaki saatleri kapatan bir sey yoktu.
#
# Neden fonksiyon, PATH'e konan `claude` adli bir betik degil: sarmalayicinin
# isi yalnizca etkilesimli kabuktan baslatilan claude ile. PATH'teki bir ad her
# cagriyi yakalar (masaustu girdisi, betik, npx) ve gercek ikiliyi hangi
# sirayla buldugu makineye gore degisir.
#
# Trap'ler bu makinede olculdu (zsh 5.9, 2026-08-05):
#   - Yalniz EXIT yetmiyor: SIGINT ve SIGTERM'de HIC calismiyor (SIGHUP'ta
#     calisiyor). Terminali kapatmak disindaki her sonlanma kacardi.
#   - Sinyal yakalaninca zsh trap'ten sonra fonksiyona devam ediyor, yani EXIT
#     de ayrica calisiyor. Bayrak bu yuzden var.
#   - Bayrak GLOBAL olmali: EXIT trap'i fonksiyonun yerelleri yikildiktan sonra
#     kosuyor, `local` bir bayrak orada BOS gorunuyor ve koruma sessizce ise
#     yaramiyor. Bir `typeset -g` ile bes ayri sonlanma tek release veriyor.
#   - Trap'ler cikis kodunu bozmuyor; claude'un rc'si oldugu gibi donuyor.
function claude() {
	typeset -g _CLAUDE_SUDO_RELEASED=0
	trap '
		if (( ! _CLAUDE_SUDO_RELEASED )); then
			_CLAUDE_SUDO_RELEASED=1
			claude-sudo __release $$
		fi
	' EXIT INT HUP TERM

	# Tutamak, pencere kapaliyken de kaydediliyor: pencere cogu zaman claude
	# calisirken aciliyor (`! csudo on`), baslangicta degil.
	claude-sudo __hold $$

	command claude "$@"
}
