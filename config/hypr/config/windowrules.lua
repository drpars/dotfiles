-- =======================================================
-- PENCERE KURALLARI
-- =======================================================

-- ── Kuralsiz float'lar: KURAL YOK, ve bu bir karar ──
-- HEDEF SINIF (v0.56.2 KAYNAGINDAN okundu, wiki degil --
-- XWaylandManager.cpp `shouldBeFloated`): Wayland tarafinda kendiliginden
-- float olan pencere ya xdg_toplevel PARENT'i olandir (yani bir dialog),
-- ya da SABIT BOYUT ilan edendir (minSize != 0 ve minSize == maxSize).
--
-- 2026-08-22'de bu iki sinifi sag alt koseye tasiyan bir kural vardi
-- (`move = { "max(0, monitor_w - window_w - 20)", ... }`); KALDIRILDI.
-- Kullanici merkezi istiyor ve Hyprland zaten merkeze koyuyor. Ayni GTK
-- sondasiyla uc hal OLCULDU (500x400 pencere, ekran 2560x1440, waybar 40):
--   A kose kurali     : at=(2040,1020)
--   B `center = true` : at=(1030,540)
--   C kural yok       : at=(1030,540)   <-- YURURLUKTE
--
-- B ile C sabit-boyut penceresinde AYNI; ayrildiklari yer DIALOG dali.
-- Olculdu (dialog 600x400, parent at x=11 w=1263):
--   B -> at=(980,540)   ekranin merkezi
--   C -> at=(343,540)   PARENT'in merkezi (11 + 1263/2 - 300)
-- Yani `center = true` no-op DEGIL: dialogu ait oldugu pencereden koparip
-- ekran merkezine ceker. Kural yokken dialog parent'inin ustunde kalir --
-- istenen bu, ve bu yuzden bos birakmak `center = true` yazmaktan iyidir.
--
-- KOSE KURALI GERI EKLENECEKSE once notu oku: `move` yalnizca MAP aninda
-- kosuyor; sonrasinda istemci kendini yeniden boyutlarsa Hyprland kurali
-- yeniden kosturmuyor, pencerenin MERKEZINI koruyor. Kuculen istemci ice
-- kayar (swappy: 20 px yerine 71 px), BUYUYEN istemci disari tasar ve
-- `max(0, ...)` kelepcesi tutmaz -- olculdu: 500x400 -> 1500x1050'de
-- ekranin 480x305 px disina cikti. `general:resize_corner` bu isi
-- gormuyor (olculerek elendi: etkilesimli boyutlamaya ozel).
--
-- SIRA: isimsiz kurallar yukaridan asagi islenir, isimli olanlar hepsinden
-- once. `move` efekti `center`i siler, `center` da `position`i -- karsilikli
-- dislayan, SON uygulanan kazanir (WindowRuleApplicator.cpp).
--
-- `float = true` ile eslesme denenirse: WindowRule.cpp:404 prop'u
-- `w->m_isFloating` uzerinden esliyor, efektler ise sonra uygulaniyor
-- (Window.cpp:2191) -- yani KENDI kurallarimizla float ettiklerimiz
-- (imv/mpv/Calculator) eslesme aninda hala tiled ve kapsam disinda kalir.
--
-- `modal = true` diye bir muafiyet DENENDI ve OLU cikti: Window.cpp:1681
-- `isModal()` yalnizca `m_xwaylandSurface->m_modal`e bakiyor, yani native
-- Wayland uygulamasinin modal'i modal sayilmiyor.

-- Hesap makinesi
hl.window_rule({
    match = { class = "org.gnome.Calculator" },
    float = true,
})

-- Waydroid
hl.window_rule({
    match      = { title = "Waydroid" },
    fullscreen = true,
})


-- Resim/video görüntüleyiciler
hl.window_rule({
    match = { class = "imv" },
    float = true,
})

hl.window_rule({
    match = { class = "mpv" },
    float = true,
})

-- Zenity (dosya seçici)
hl.window_rule({
    match  = { class = "zenity" },
    float  = true,
    center = true,
    size   = { 650, 450 },
})

-- Symlink Manager
hl.window_rule({
    match  = { class = "Tk" },
    float  = true,
    center = true,
    size   = { 850, 700 },
})

-- ── Scratchpad'ler ─────────────────────────────────
-- Pencereyi special workspace'e koyan yer BURASI, baslatan betik degil
-- (config/scripts/scratchtoggle). Boylece uygulama nereden baslatilirsa
-- baslatilsin -- kisayol, rofi, .desktop -- ayni alana duser.

-- Anlik notlar: kitty + nvim, tek dosya (~/notlar.md).
hl.window_rule({
    match     = { class = "scratch-notes" },
    workspace = "special:notlar silent",
})

-- WhatsApp Web.
-- Sinif UYDURULAMAZ, olculur: Chrome Wayland'de --class bayragini yok sayiyor
-- ve app_id'yi --app URL'i + profil adindan turetiyor (olculdu 2026-08-06).
-- Ayni sinif webapp-whatsapp.desktop'taki StartupWMClass'ta da yaziyor; URL
-- degisirse ikisi birden degisir.
hl.window_rule({
    match     = { class = "chrome-web.whatsapp.com__-Default" },
    workspace = "special:whatsapp silent",
})

-- Kalici kabuk: ciplak kitty, kendi sinifiyla.
-- Sinif kitty'nin varsayilani OLAMAZ: "kitty" yazilsaydi bu kural SUPER+RETURN
-- ile acilan her terminali de special alana suruklerdi. Sinif betikte degil
-- baglilikta veriliyor (`--class=scratch-term`); ikisi birlikte degisir.
hl.window_rule({
    match     = { class = "scratch-term" },
    workspace = "special:terminal silent",
})

-- ── Waybar tiklamasiyla acilan TUI pencereleri ─────
-- Bunlar scratchpad DEGIL: special workspace de toggle da yok. Istenen sey
-- yalnizca "hep ayni geometride acilsin"di ve onu veren sey special alan degil
-- asagidaki float/center/size ucludur -- zenity ve Tk kurallariyla ayni desen.
-- Toggle olmadan special alana konsalardi pencereler hic gorunmezdi.
-- Sinif ORTAK: hepsi ayni geometriyi paylastigi icin tek kural yetiyor;
-- biri ayrisirsa sinif o zaman bolunur. Sinifi artik tek bir yer veriyor:
-- scripts/tuipop (`--class=tui-popup`), modules.json'daki her cagri onu
-- calistiriyor. Ikisi birlikte degisir.
-- Cagiran listesi ELLE TUTULMUYOR, sorulur:
--   grep -n tuipop ../../waybar/modules.json
-- Onceki bicim sayiyordu ("bes cagri (bluetui, impala, btop x2, nvtop)") ve
-- guncelleme tiklamalari eklenince bayatladi. Ders bu depoda kayitli: mutlak
-- sayi yazan yorum, degismez yazan yorumdan hizli bayatlar.
-- "kitty" yazilamaz -- SUPER+RETURN terminallerini de yakalardi.
hl.window_rule({
    match  = { class = "tui-popup" },
    float  = true,
    center = true,
    size   = { 1536, 864 },
})
