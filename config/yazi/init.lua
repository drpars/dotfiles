-- plugins:full-border
require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

-- plugins:git
th.git = th.git or {}
th.git.unknown_sign = " "
th.git.added_sign = ""
th.git.deleted_sign = ""
th.git.modified_sign = "󰝤"
th.git.untracked_sign = "󰬜"
th.git.clean_sign = "✔"
require("git"):setup({
	-- Order of status signs showing in the linemode
	order = 1500,
})

-- uhs-robert/recycle-bin
require("recycle-bin"):setup({
	-- Optional: Override automatic trash directory discovery
	-- trash_dir = "~/.local/share/Trash/",  -- Uncomment to use specific directory
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
-- Renkler eklentinin Catppuccin varsayilanlarindan flavor'a (tokyo-night)
-- cevrildi. Tek bir text_fg hem dolu hem bos parcanin uzerine dusuyor -- ayni
-- metin doluluk noktasindan ikiye bolunuyor -- o yuzden iki zemin de acik
-- tonda, yazi koyu secildi. Flavor'in kendi kurali da bu:
-- count_copied = { fg = "#1a1b26", bg = "#9ece6a" }.
require("sduf"):setup({
	filled_bg        = "#9ece6a", -- yesil
	filled_bg_warn   = "#e0af68", -- %75'ten sonra sari
	filled_bg_danger = "#f7768e", -- %90'dan sonra kirmizi
	unfilled_bg      = "#a9b1d6", -- bos parca
	text_fg          = "#1a1b26",
	error_fg         = "#f7768e",
})

-- pirafrank/what-size
-- Klasor/secim boyutunu fs.calc_size() ile hesaplar (harici `du` yok; API
-- yazi'nin kendisinde, PR #2695). Tus: "m S" -- keymap.toml, OZEL ATAMALAR.
-- setup() yalnizca durum cubugu yazicisini kaydeder ve ilk hesaplamaya kadar
-- bos doner; bildirim sonduktan sonra sayiyi gorunur tutan sey budur.
require("what-size"):setup()
