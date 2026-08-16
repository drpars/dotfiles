# dotfiles

Arch Linux + Hyprland kurulumunun yapılandırma dosyaları. Depo `~/.dotfiles`
altında durur; ev dizinindeki dosyalar buraya **symlink**'tir, yani
`~/.zshrc` düzenlenmez — `home/.zshrc` düzenlenir.

Kurulumun tamamı **tek komutla** olmaz ve bu bilerek böyledir: sekiz üst
klasörün üçü otomatik yerleştirilir, kalanı ya root ister, ya hedefi tahmin
edilemez, ya da başka bir işletim sistemine aittir.

## Bölümler

| Bölüm | Hedef | Nasıl kurulur |
|---|---|---|
| `config/` | `~/.config` | **Otomatik** — [archsetup](https://github.com/drpars/archsetup), öge öge seçilir |
| `home/` | `~` | **Otomatik** — archsetup |
| `local/share/` | `~/.local/share` | **Otomatik** — archsetup (`applications`, `icons`, `color-schemes`) |
| `sddm/` | `/etc/sddm.conf` + greeter'ın `~/.local/share/icons` | **Elle / root** — archsetup'ın ayrı SDDM görevi yazar; buradakiler referans kopyadır |
| `browser/` | Firefox / Zen profil dizini | **Elle** — profil klasörünün adı rastgele, sabit hedef yok |
| `claude/` | `~/.claude` | **Elle** — kendi betiği var: `claude/install.sh` (geri yön: `save.sh`) |
| `windows/` | Windows | **Elle** — PowerShell profili ve Scoop kurulum betiği, başka işletim sistemi |
| `docs/` | — | Kurulacak bir şey değil, belge |

Otomatik olan üç bölüm archsetup'ın dotfiles ekranından seçilir; symlink ya da
kopya modu vardır. `local/` bir seviye aşağıdan (`local/share`) eşlenir:
doğrudan eşlenseydi `~/.local/share`'in **tamamı** üç klasörle değiştirilirdi.

`browser/` altındaki `chrome/` klasörleri userChrome/userContent parçalarıdır;
hedef profil `about:profiles` ile bulunup elle kopyalanır.

## Makineye özgü ayarlar

Şablondan dosya üretilmez. Makineler arasındaki farklar iki yolla çözülür:

- **Yetenek testi** — araç kurulu mu, aygıt var mı (çalışma anında sorulabilen
  her şey). Tercih edilen yol budur.
- **Kimlik dosyası** — yalnızca çalışma anında sorulamayan olgular için:
  `config/hosts/<board_id>.conf` (`~/.config/hosts`'a symlink). Anahtar DMI
  `board_name`'den türetilir. Yeni makine için `config/hosts/ORNEK.conf`
  kopyalanır; iskeletteki anahtarların **hepsi yorumludur**, düzenlenmeyen
  makine nötr varsayılanda kalır.

## Yazarken: mutlak ev dizini yolu gömülmez

`/home/drpars` yazan bir satır başka kullanıcı adında sessizce kırılır. Her
biçimin `~` ile ne yaptığı farklı, ölçülerek yazıldı:

| Dosya türü | `~` genişler mi | Yapılacak |
|---|---|---|
| `qt5ct.conf`, `qt6ct.conf` | **Evet** (`Qt6CT::resolvePath`, `$DEGISKEN/` de) | `~/...` yazılır. Uyarı: qt6ct arayüzü "uygula" dediğinde satırı mutlak yola geri yazar |
| `.desktop` → `Exec=` | Hayır | Kabuktan geçilir: `Exec=sh -c "exec ~/yol"`. Argüman gerekiyorsa `\\$1` + `sh %u` — tek ters bölü `desktop-file-validate`'ten geçer ama GLib girdiyi **hiç yüklemez** |
| `.desktop` → `TryExec=` | Hayır | Yalnızca PATH'te bulunan çıplak ad yazılır; PATH dışındaki araç için TryExec eklenmez |
| `rofi` `*.rasi` | Hayır | Ayar hiç yazılmaz; `filebrowser` zaten `$HOME`'a düşer |
| `mc/panels.ini` | Hayır | `[Dirs]` bölümü tutulmaz; pasif panel ev dizininde açılır |

`TryExec=`, `Exec=`'in gerçekten çalıştırdığı ama her makinede bulunmayan aracı
gösterir: araç yoksa GLib girdiyi hiç yüklemez, `mimeapps.list`'teki yedekli
zincir bir sonraki adaya geçer.

## Üretilen dosyalar

Bir bölüm symlink'lendiğinde araçlar çıktılarını doğrudan bu depoya yazar
(`mimeinfo.cache`, `systemd/user/*.wants/`, `mc/ini`). Hepsi `.gitignore`'da —
yeni bir üretilen dosya fark edilirse oraya eklenir, çünkü `.gitignore` ancak
dosya hiç izlenmemişse iş görür.
