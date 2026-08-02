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
function full-update() {
	yay -Syu --devel "$@" || return

	# Birlestirilmemis .pacnew/.pacsave dosyalari sessizce birikir ve aylar
	# sonra "guncellemeden sonra bozuldu" olarak geri doner. Yalnizca listele:
	# hicbir sey kendiliginden birlestirilmez.
	local -a diffs
	diffs=(${(f)"$(pacdiff -o 2>/dev/null)"})
	if (( $#diffs )); then
		print -P "%F{yellow}Elle bakilmasi gereken dosyalar:%f"
		print -l -- $diffs
		print -P "Birlestirmek icin: %F{cyan}sudo -E pacdiff%f"
	fi
}
