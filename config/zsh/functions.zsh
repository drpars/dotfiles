# Functions
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
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
		print -P "    Birlestirmek icin: ${cmd}sudo -E pacdiff${r}"
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
