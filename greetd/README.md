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
`/etc/sddm.conf`, `sddm/sddm.conf`'tan üç ortam değişkeni kadar ayrılmıştı ve
kimse fark etmedi. Karşılığı `./install.sh check` — canlı dosyalarla repoyu
karşılaştırır, farkı `diff` olarak basar.

## Ölçülmüş tuzaklar

**Config dosyası komut satırını sessizce yutar.** `--config` verildiği anda
tuigreet'in geri kalan bayrakları etkisiz kalıyor: `--config <dosya> --time`
koşusunda `show_time` hâlâ `false`, çıkış kodu 0. Aynısı `--cmd`,
`--remember`, `--theme` için de geçerli (ölçüldü 2026-09-07). Bu yüzden
`/etc/greetd/config.toml` içinde `--config`'ten başka bayrak **olmamalı**;
oraya eklenen bir bayrak hata vermeden yok sayılır.

Bu tuzak `--config` yazılmasa da kurulur: `/etc/tuigreet/config.toml`
tuigreet'in **varsayılan** yolu ve dosya kurulduktan sonra bayraksız
`tuigreet --dump-config` da onu okuyor (ölçüldü). Yani dosyanın **var olması**
komut satırını etkisizleştirmeye yetiyor. Komuttaki `--config` bu yüzden
gereksiz değil, bağımlılığı **görünür** kılıyor.

**`--dump-config` doğrulama değil.** Yalnız TOML olarak ayrıştığını gösteriyor:
`border = "zzznosuch"` ve `--background zzz` rc=0 ile geçip dump'a olduğu gibi
yazılıyor. Doğrulayan tek şey çizdirmek:

```sh
tuigreet --mock --config /etc/tuigreet/config.toml
```

`--mock` greetd socket'ine hiç dokunmuyor, kimlik akışını taklit ediyor. Boru
altında koşturulacaksa pty şart ve **boyut verilmeli** — boyutsuz pty'de
ratatui 0×0 alanla panikliyor:

```sh
script -qec "stty rows 30 cols 100; tuigreet --mock --config …" /dev/null
```

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

## Bir sonraki açılışta bakılacak

Birimin sıralaması (`Before=greetd.service`) mekanizmadan yazıldı; paletin
greeter **çizerken** yürürlükte olduğu henüz bir açılışta doğrulanmadı.
Doğrulanmazsa çare adresi belli: `vt.default_red/grn/blu=` çekirdek
parametreleri (modül parametreleri var, `/proc/cmdline`'da yok) — ama o UKI
dokunmak demek.

## Bu bölümde olmayan

Klavye düzeni ve konsol yazı tipi burada değil, `/etc/vconsole.conf`'ta
(`KEYMAP=trq`, `FONT=ter-v22b`) — greeter'ın yazı boyutu oradan gelir.
