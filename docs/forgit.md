# forgit — fzf ile etkileşimli git

[`wfxr/forgit`](https://github.com/wfxr/forgit) zinit ile yükleniyor (`.zshrc`).
Git komutlarına fzf arayüzü giydirir: liste + canlı diff önizlemesi.

## Ortak tuşlar (her komutta geçerli)

| Tuş | İşlev |
|---|---|
| `↑` / `↓` | listede gez |
| `Tab` | öğe işaretle (çoklu seçim) |
| `Ctrl-R` | hepsini seç/bırak (toggle-all) |
| `Enter` | seçimi onayla / ana eylemi çalıştır |
| `?` | önizleme panelini aç/kapat |
| `Alt-J` / `Alt-K` | önizlemeyi aşağı/yukarı kaydır |
| `Alt-W` | önizlemede satır kaydırma (wrap) |
| `Ctrl-S` | sıralamayı değiştir |
| `Esc` / `Ctrl-C` | **iptal** (hiçbir şey yapmadan çık) |

Önizleme paneli sağda %60 genişlikte açılır.

---

## `ga` — etkileşimli `git add`

Değişmiş + izlenmeyen dosyaları listeler; seçtiklerini stage'ler.

- Önizleme: üzerinde durduğun dosyanın diff'i.
- `Tab` ile birden fazla dosya işaretle → `Enter` ile hepsini stage'le.
- `Alt-E` → dosyayı editörde aç.

**Örnek:** `ga` → 3 dosyadan 2'sini `Tab`'la işaretle → `Enter`. Sadece o ikisi
stage'lendi (`gs` ile doğrula).

> Bütün dosya bazında çalışır; `git add -p` (parça parça) yerine geçmez.

---

## `glo` — etkileşimli `git log`

Commit geçmişinde gezersin; önizlemede o commit'in tam diff'i.

- `Enter` → commit'i pager'da tam aç.
- `Ctrl-Y` → commit **SHA**'sını panoya kopyala.
- Argüman alır:
  - `glo dosya.txt` → sadece o dosyanın geçmişi
  - `glo main` → o dalın logu

**Örnek:** `glo` → commit bul → `Ctrl-Y` ile SHA kopyala → çık → `git cherry-pick <yapıştır>`.

---

## `gd` — etkileşimli `git diff`

Değişiklikleri inceler (tek seçim + önizleme).

- `gd` → çalışma ağacındaki değişiklikler
- `gd <commit>` → o commit'e göre fark
- `gd <commit1> <commit2>` → iki commit arası fark
- `gd dosya.txt` → sadece o dosyanın farkı
- `Enter` → seçilen farkı pager'da tam aç.
- `Alt-E` → farkı görülen dosyayı editörde aç.

**Örnek:** `gd` → dosya seç → `Enter` ile oku → `q` ile pager'dan çık.

---

## `gco` — etkileşimli commit checkout ⚠️

Log'dan bir **commit** seçip `git checkout <commit>` yapar.

> **Dikkat:** Seni "detached HEAD" (ayrık HEAD) durumuna sokar — bir dala değil,
> doğrudan commit'e geçersin. Geçmişe bakıp denemek için iyidir; orada commit
> atarsan dala bağlı olmaz.

- Geri dönmek için: `git switch -` ya da `gcb` ile bir dala geç.
- **Dal değiştirmek için** → `gcb` (checkout branch).
- **Dosya değişikliğini geri almak (discard) için** → `gcf` (checkout file).

**Örnek:** `gco` → eski commit seç (detached) → incele → `git switch -` ile geri dön.

---

## `gss` — etkileşimli stash görüntüleme

Stash listesini gezersin; önizlemede stash'in diff'i.

- `Enter` → stash içeriğini tam göster.
- `Ctrl-Y` → stash adını (`stash@{0}`) panoya kopyala.
- **Görüntüleme** içindir; uygulamaz/silmez. Stash **oluşturmak** için → `gsp`.

**Örnek:** `gss` → stash seç → önizle → adını `Ctrl-Y` ile kopyala → `git stash apply <yapıştır>`.

---

## Hızlı özet

| Komut | Karşılığı | Ana eylem (Enter) | Özel tuş |
|---|---|---|---|
| `ga`  | git add          | seçilenleri stage'le | `Tab` çoklu, `Alt-E` düzenle |
| `glo` | git log          | commit'i aç          | `Ctrl-Y` SHA kopyala |
| `gd`  | git diff         | farkı pager'da aç    | `Alt-E` düzenle |
| `gco` | checkout commit  | commit'e geç (⚠️ detached) | — |
| `gss` | stash show       | stash'i göster       | `Ctrl-Y` ad kopyala |

## Diğer kullanışlı forgit alias'ları

| Komut | İş |
|---|---|
| `gcb` | dal değiştir (checkout branch) |
| `gcf` | dosya değişikliğini geri al (checkout file) |
| `gsp` | stash oluştur (stash push) |
| `grh` | `git reset HEAD` (stage'den çıkar) |
| `gbd` | dal sil (branch delete) |
| `gbl` | `git blame` |
| `grb` | etkileşimli rebase |

> Bir forgit alias'ı kendi alias'ınla çakışırsa, `.zshrc`'de forgit yüklenmeden
> önce `FORGIT_NO_ALIASES=1` ile tüm kısa adları kapatıp yalnızca
> `forgit::diff` gibi fonksiyon adlarını kullanabilirsin.
