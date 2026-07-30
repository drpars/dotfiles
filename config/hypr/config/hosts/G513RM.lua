-- =======================================================
-- MAKİNE: ASUS ROG Strix G513RM (dizüstü)
-- =======================================================
-- DMI board_name = "G513RM". hyprland.lua bu dosyayı donanıma bakarak yükler,
-- adı elle hiçbir yere yazılmaz.
--
-- Buraya YALNIZCA yeteneğe sorulamayan olgular yazılır. "Araç kurulu mu"
-- türünden her şey helpers.lua'daki has()/exists() ile çözülür — bkz.
-- keybindings.lua'daki ASUS bağlamaları.

-- Dahili panel (BOE 0x0A07).
--
-- Konektör ADIYLA eşleşmiyoruz. Bu makinede iki kart var (card1 = iGPU,
-- card2 = dGPU) ve ikisi de bir eDP konektörü sunuyor; panel oturuma göre
-- eDP-1 ya da eDP-2 olarak numaralanabiliyor. 2026-07-30'da tam olarak bu
-- oldu: oturum yeniden başlayınca eDP-1 kuralı eşleşmez hâle geldi.
-- Açıklama EDID'den gelir, numaralamadan bağımsızdır.
host.monitor = {
    output   = "desc:BOE 0x0A07",
    mode     = "2560x1440@165",
    position = "0x0",
    scale    = 1,
    bitdepth = 10,
    cm       = "wide", -- wide|hdr
}

-- Hibrit grafik: Radeon 680M (iGPU) + RTX 3060 Mobile (dGPU), nvidia modülü
-- yüklü. Bu yüzden "nvidia modülü var mı" diye sormak ayırt etmiyor — olgu
-- şu ki her şeyi nvidia-drm'e zorlamak hibrit kurulumda doğru değil.
host.nvidia_env = false

-- OpenRGB profilleri (pars-white/pars-off) ve Razer çevre birimleri
-- masaüstünde. openrgb ikilisi burada da kurulu, yani yetenek testi yine
-- ayırt etmezdi — eksik olan cihazların kendisi.
host.rgb_devices = false

-- Dizüstünün tuş takımı Türkçe basılı; masaüstünde US klavye var. Fiziksel
-- bir olgu, yazılımdan sorulamaz.
host.kb_layout = "tr,us"
