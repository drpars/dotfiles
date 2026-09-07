# greetd + tuigreet

Giriş ekranı. 2026-09-07'de sddm'in yerine geçti; gerekçe bu depoda değil,
çalışma notlarında (`pars/soru-cevap`, `pars/g14-boot-hatalari`): sddm'in
greeter'ı nvidia GSP-init kilitlenmesinin **kurbanıydı**, tuigreet ise TTY
greeter'ı — X, EGL/GLX/VA-API ve QML yok, yani `/dev/nvidia*`'ı açan kod yolu
yok.

## Dosyalar

| Repo | Hedef | Ne |
|---|---|---|
| `config.toml` | `/etc/greetd/config.toml` | greetd'nin kendisi: vt 1, greeter kullanıcısı, tek komut |
| `tuigreet.toml` | `/etc/tuigreet/config.toml` | greeter'ın tamamı: oturum, saat, hatırlama, renkler |
| `vtrgb-tokyonight` | `/etc/vtrgb-tokyonight` | konsolun 16 renk yuvası, tokyonight |
| `vtrgb-tokyonight.service` | `/etc/systemd/system/` | paleti greetd'den önce süren birim |

Kurulum ve ayrışma denetimi: `./install.sh`, `./install.sh check`.

## Neden symlink değil

Diğer bölümler symlink; bu bölüm **kopya**. Sebebi ölçüldü: greeter `greeter`
kullanıcısı olarak koşuyor ve `~drpars` izinleri `0700`, yani repodaki hiçbir
dosyayı okuyamıyor (`sudo -u greeter test -r …` → rc=1). Hedefler `/etc`
altında gerçek dosya olmak zorunda.

Kopya olmanın bedeli ayrışmadır ve bu depoda bir kez ödendi: canlı
`/etc/sddm.conf`, o zamanki `sddm/` bölümünün sürümlenen kopyasından üç ortam
değişkeni kadar ayrılmıştı ve kimse fark etmedi (bölüm 2026-09-07'de silindi,
`2dbb06f` sonrası; geçmişte duruyor). Karşılığı `./install.sh check` — canlı
dosyalarla repoyu karşılaştırır, farkı `diff` olarak basar.

## Ölçülmüş tuzaklar

**Config dosyası komut satırını sessizce yutar.** `--config` verildiği anda
tuigreet'in geri kalan bayrakları etkisiz kalıyor: `--config <dosya> --time`
koşusunda `show_time` hâlâ `false`, çıkış kodu 0. Aynısı `--cmd`,
`--remember`, `--theme` için de geçerli (ölçüldü 2026-09-07). Bu yüzden
`/etc/greetd/config.toml` içinde `--config`'ten başka bayrak **olmamalı**;
oraya eklenen bir bayrak hata vermeden yok sayılır.

**Tuzağın ölçütü dosya değil, bayrak** — burada bir kez tersi yazıldı ve
2026-09-07'de ölçülerek düzeltildi. `--config` **yazılmazsa**
`/etc/tuigreet/config.toml` yine okunuyor (tuigreet'in varsayılan yolu, o kadarı
doğruydu) ama komut satırı **kazanıyor**: bu dosyanın kendi değerlerine karşı
`-w 100` → `width = 100` ve `--title` → `show_title = true`, dosya 80 ve false
derken. `--config` **verilince** aynı bayraklar düşüyor (80 ve false kalıyor,
`--session-wrapper X` dump'a hiç girmiyor).

**`--config`'siz kol yok saymıyor, BİRLEŞTİRİYOR:** dosya, komut satırının
**değinmediği** alanları doldurmayı sürdürüyor. Aynı koşuda ölçüldü —
`-w 100` `width`'i 100 yaparken `show_time = true` ve
`command = "start-hyprland"` dosyadan geldi. Yani öncül ("bayraksız
`--dump-config` dosyayı okuyor") doğru; ondan *"demek ki komut satırını
etkisizleştiriyor"* çıkarmak yanlıştı — okumak ile üstüne yazmak ayrı şeyler.

Yani iki yazım biçimi birbirinin yerine geçmiyor: `--config` bağımlılığı
görünür kılan bir süs değil, dosyayı **tek kaynak** yapan mekanizmanın kendisi.
Onsuz, komut satırına sızan her bayrak yürürlüğe girer.

**`--dump-config` doğrulama değil.** Yalnız TOML olarak ayrıştığını gösteriyor:
`border = "zzznosuch"` ve `--background zzz` rc=0 ile geçip dump'a olduğu gibi
yazılıyor. Doğrulayan tek şey çizdirmek:

```sh
tuigreet --mock --config /etc/tuigreet/config.toml
```

`--mock` greetd socket'ine hiç dokunmuyor, kimlik akışını taklit ediyor. Boru
altında koşturulacaksa pty şart ve **boyut verilmeli** — boyutsuz pty'de
ratatui 0×0 alanla panikliyor. **Üçüncü şart stdin:** `script`'in kendi stdin'i
kapalıysa (araç kabuğunda öyle) oturum anında bitiyor ve akış **12 bayt**
kalıyor — yalnız alt-ekran dizisi, tek satır çizilmeden, hata da yok. Yani
"çizmedi" ile "çizemedi" aynı görünüyor. stdin'i açık tutan biçim (ölçüldü
2026-09-07):

```sh
timeout 12 sh -c 'sleep 4 | script -qec "stty rows 28 cols 100; \
    tuigreet --mock --config …" /dev/null'
```

Normal bitiş `rc=124`'tür (`timeout` kesti); ekran içeriği çıktının içinde,
kaçış dizileri ayıklanarak okunur.

**Hex renk konsolda çürüyor.** tuigreet hex'i doğru yapıyor — gerçek
`38;2;R;G;B` basıyor —, kıran şey Linux VT'si. Ölçüm (tty6'ya yaz,
`/dev/vcsa6`'dan özniteliği oku): 10 tokyonight rengi **6** yuvaya çöküyor ve
`#a9b1d6`, `#c0caf5`, `#bb9af7`, `#9ece6a` **aynı** yuvaya düşüyor. Bu yüzden
renkler paletten geliyor: yuvalar tokyonight'la boyanıyor, tema da yuva
numarası veriyor. Aynı sebeple `[background.doom]` / `[background.matrix]`
renkleri de hex olduğu için yaklaşık kalır.

**Palet global.** `setvtrgb -C /dev/tty6 …` verilse bile çekirdek renk
haritasını **bütün** sanal konsollara uyguluyor (ölçüldü: tty2'nin paleti de
değişti). Yani birim yalnız greeter'ı değil, `Ctrl+Alt+F<n>` ile açılan her
konsolu boyar. Geri alma `setvtrgb vga`; birimin `ExecStop`'u bunu yapıyor.

**Kaçış dizisi kanalı çalışmadı.** `console_codes(4)`'ün belgelediği
`ESC ] P nrrggbb` dizisi, arka plandaki bir VT'ye yazıldığında paleti
değiştirmedi (`KDGETPALETTE` ile okundu, fark yok). Çalışan kanal ioctl, yani
`setvtrgb`.

**Giriş ile compositor arasındaki metin oturumun kendi stdout'u.** greeter
kapandıktan sonra, compositor ekranı devralana kadar geçen boşlukta konsolda
yazı görünüyordu. Kaynağı tahmin edilmedi, okundu: girişten sonra `/dev/vcs1`
(VT'nin metin tamponu) geri okundu ve içinde Hyprland'in ASCII `Welcome to
Hyprland!` banner'ı, ~20 `DEBUG` satırı ve xkbcomp'un keymap uyarıları vardı.
Aynı dökümde Hyprland'in kendi satırı da duruyor — *"Disabling stdout logs
(debug.enable_stdout_logs = 0)"* —, yani susuyor ama ancak config'i
ayrıştırdıktan sonra; banner ondan önce basılıyor. Çare `[session]
session_wrapper` → `tuigreet.toml`; gerekçesi ve iki koşu yolu orada yazılı.

## Bir sonraki açılışta bakılacak

**Sarmalayıcı işini yaptı mı** — giriş ile compositor arasında yazı kalmadı mı.
`session_wrapper`'ın iki yolu da kapsadığı kaynaktan okundu (0.11.1 etiketi,
`ipc.rs`), ama bu makinede bir girişte sınanmadı. Kayıt yerinde kalıyor:
`journalctl -t wayland-session` banner'ı taşıyorsa sarmalayıcı koşmuş demektir,
boşsa koşmamıştır — ekrana bakmadan da ayırt edilir.

**Bozarsa kurtarma greeter'ın içinde DEĞİL.** Sarmalayıcıdan kaçan bir yol
yok: `Session::get_selected` yalnız **listeden** seçilen oturumda `Some`
dönüyor, `F2` ile elle yazılan komut da varsayılan komut da `_` koluna düşüyor
ve orada sarmalanıyor — yani greeter'da komutu düzeltmek sarmalayıcıyı
atlatmaz. Kalan yol `Ctrl+Alt+F2`: greetd yalnız `getty@tty1` ile çakışıyor,
öbür VT'lerde metin girişi açık; oradan `session_wrapper` satırı silinir ya da
`install.sh`'ın bıraktığı `.bak-*` geri konur.

## Bu bölümde olmayan

Klavye düzeni ve konsol yazı tipi burada değil, `/etc/vconsole.conf`'ta
(`KEYMAP=trq`, `FONT=ter-v22b`) — greeter'ın yazı boyutu oradan gelir.
