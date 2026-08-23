-- plugins:session (yazi'nin gomulu preset eklentisi, ya pkg ile kurulmaz)
-- Ornekler arasi yank/paste. Yayin tarafi zaten kosulsuz calisiyor -- Rust
-- cekirdeginde Pubsub::pub_after_yank(self.cut, &self.urls) -- ama ALICI taraf
-- bu secenegin arkasinda ve varsayilani KAPALI. Gomulu kaynak tam olarak su:
--     local function setup(_, opts)
--       if opts.sync_yanked then
--         ps.sub_remote("@yank", function(state) ya.emit("update_yanked", { state }) end)
--       end
--     end
-- Yani kanal canli olsa bile (DDS soketi /run/user/<uid>/yazi+<uid>/.dds.sock
-- LISTEN, ikinci ornek ona bagli) dinleyen olmadigi icin `y` ... `p` calismaz;
-- olculdu 2026-08-17, once bu satir yokken calismadi.
--
-- "@" oneki DDS'te "kalici saklanir ve yeni ornek acilinca geri yuklenir"
-- demek, o yuzden bu acikken sonradan acilan bir yazi de yank'i devralir.
-- Sinir: ayni kullanici, ve yollar her iki ornekten de erisilebilir olmali.
-- init.lua acilista kostugu icin degisiklik ACIK yazi'lere uygulanmaz; ikisi
-- de yeniden baslatilmali.
require("session"):setup({
	sync_yanked = true,
})

-- plugins:full-border
require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

-- plugins:git
-- Durum isaretleri (unstaged/staged/untracked...) theme.toml'un [git]
-- bolumunde; plugin onlari `th.git`'ten okuyor ve o tablo init.lua'dan
-- degil theme.toml/flavor.toml'dan doluyor.
require("git"):setup({
	-- Order of status signs showing in the linemode
	order = 1500,
})

-- plugins:mime-ext
-- Uzanti veritabanindan MIME turu; fetcher tanimi yazi.toml'da.
require("mime-ext.local"):setup({
	-- Veritabaninda olmayan uzanti/ad file(1)'e duser. Kapatilirsa uzantisiz
	-- dosyalar yanlis turle acilir -- opener kurallari MIME'a bakiyor.
	fallback_file1 = true,
})

-- uhs-robert/sshfs
-- Uzak sunucuyu ~/.ssh/config'ten okuyup FUSE ile baglar (tus: F).
require("sshfs"):setup()

-- shafayetejaman/sduf
-- Durum cubugunun ortasinda disk olceri: bulunulan dizinin dosya sistemi icin
-- kullanilan/toplam + yuzde. `df -h <cwd>` ile besleniyor ve "cd" olayina
-- abone, yani olcer dizinle birlikte degisiyor -- "M" ile bir bolume girince
-- (mount eklentisinde Enter cd yapar) olcer o bolumu gosterir. Bosluk buydu:
-- mount.yazi'nin kendi tablosunda boyut sutunu YOK (redraw()'da dort sutun:
-- aygit / etiket / baglama noktasi / fstype).
--
-- RENKLER — koyu sema, ve sayilari hesaplanarak secildi (2026-08-17).
--
-- Kisit yapisaldir: eklenti durum rengini ZEMINDE tasiyor ama metin icin TEK
-- bir text_fg aliyor, ve o metin doluluk noktasindan bolunup hem dolu hem bos
-- zeminin ustune dusuyor. Tokyo Night'in uyari renkleri (#e0af68, #f7768e)
-- ACIK renkler oldugu icin "bos kismi koyult, dolgulari birak" isleme:
-- 256 gri tonu tarandi, tek bir fg ile ulasilabilen en iyi MINIMUM kontrast
-- 2,24 -- WCAG'in buyuk metin esigi (3,0) bile gecilmiyor. Ilk surumun acik
-- kapsulu bu yuzden aciktı, keyfi degil.
--
-- Cozum dolgulari da koyultmak: her aksanin TONU ve DOYGUNLUGU korunup yalniz
-- parlakligi #c0caf5'e karsi kontrast 4,5'e (WCAG AA) inene kadar dusuruldu.
-- Iz olarak #1a1b26 secildi -- Tokyo Night'in kendi bg'si, yani cubugun zemini:
-- bos kisim cubuga karisip gorunmez oluyor, geriye yalnizca dolu dilim kaliyor.
-- Olculen sonuc: yaziya karsi min kontrast 4,50; iz ile dolgu arasi 2,34
-- (ikisi ayni anda yan yana duruyor, o yuzden ayrica olculdu).
--
-- error_fg zeminSIZ ciziliyor (`ui.Span(" Disk: ?? "):fg(...)`), yani cubugun
-- zemini uzerinde: #f7768e orada 6,46 veriyor, koyultmaya gerek yok.
require("sduf"):setup({
	filled_bg        = "#415f1f", -- tokyonight yesil #9ece6a, koyultulmus
	filled_bg_warn   = "#754f18", -- %75'ten sonra: sari #e0af68, koyultulmus
	filled_bg_danger = "#ae0a29", -- %90'dan sonra: kirmizi #f7768e, koyultulmus
	unfilled_bg      = "#1a1b26", -- iz = cubugun zemini
	text_fg          = "#c0caf5", -- tokyonight fg
	error_fg         = "#f7768e",
})

-- pirafrank/what-size
-- Klasor/secim boyutunu fs.calc_size() ile hesaplar (harici `du` yok; API
-- yazi'nin kendisinde, PR #2695). Tus: "m S" -- keymap.toml, OZEL ATAMALAR.
-- setup() yalnizca durum cubugu yazicisini kaydeder ve ilk hesaplamaya kadar
-- bos doner; bildirim sonduktan sonra sayiyi gorunur tutan sey budur.
require("what-size"):setup()

-- Kopya/tasima bitince bildirim -- eklenti degil, iki DDS aboneligi.
-- Bosluk suydu: yazi bir yapistirmanin BITTIGINI hicbir yerde soylemiyordu;
-- durum cubugundaki `progress` ve `w` (tasks:show) surerken bilgi veriyor,
-- bitince sessizce kayboluyor. Olculdu 2026-08-21, yazi 26.5.6:
--   kopyala-yapistir -> "duplicate", kes-yapistir -> "move" (ayni govde)
--   govde: { items = { { from = Url, to = Url }, ... } } -- to.name / to.parent
--   TOPLU: uc dosyalik tek yapistirma TEK mesaj verdi, dosya basina degil
--   gecikme: hedef dosya dolduktan +0,47..0,51 sn sonra (dort kosunun dordu)
--   BASARISIZ yapistirmada (yazma izni olmayan hedef) 30 sn boyunca HIC
--   ATESLEMEDI -- yani olay "denendi" degil "oldu" demek; bildirimi dogru
--   kilan sey bu.
-- Konu listesinde tamamlanma adi tasiyan bir konu YOK; bu ikisi tamamlanmada
-- atesledigi ISIMLERINDEN degil olculerek bulundu.
--
-- SINIR -- "bitti" ne kadar dogru: olay, yazi'nin write() cagrilari donunce
-- atesler; verinin diske inmesi ayri bir sorudur. Yalani bagli tutan sey
-- cekirdek tarafi (bdi max_bytes + strict_limit -- archsetup'in
-- dirty-writeback gorevi). Olculdu, USB hedefte iki kosu: olaydan sonra
-- kalan is `sync -f` ile 45 ms ve 24 ms -- yani "bitti" burada gercekten
-- bitti demek. Sinirsiz kirli sayfayla ayni bogazin ne oldugu
-- pars/soru-cevap/soru-2026-08-17-usb-writeback.md icinde.
local function paste_done(title, items)
	local n = #items
	if n == 0 then
		return
	end
	local what = n == 1 and tostring(items[1].to.name) or string.format("%d items", n)
	ya.notify({
		title = title,
		content = what .. " → " .. tostring(items[1].to.parent),
		timeout = 4,
		level = "info",
	})
end

ps.sub("duplicate", function(body) paste_done("Copied", body.items) end)
ps.sub("move", function(body) paste_done("Moved", body.items) end)
