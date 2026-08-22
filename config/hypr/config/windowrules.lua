-- =======================================================
-- PENCERE KURALLARI
-- =======================================================

-- ── Kuralsiz float'lar: ekranin calisilan yerine oturmasinlar ──
-- HEDEF SINIF (v0.56.2 KAYNAGINDAN okundu, wiki degil --
-- XWaylandManager.cpp `shouldBeFloated`): Wayland tarafinda kendiliginden
-- float olan pencere ya xdg_toplevel PARENT'i olandir (yani bir dialog),
-- ya da SABIT BOYUT ilan edendir (minSize != 0 ve minSize == maxSize).
-- Sikayetin kaynagi bu iki sinif.
--
-- `xwayland = false` ZORUNLU, susleme degil: X11 tarafinda ayni fonksiyon
-- _NET_WM_WINDOW_TYPE_{TOOLTIP,MENU,DROPDOWN_MENU,POPUP_MENU,DOCK} atomlarini
-- da float sayiyor. Bu kosul kaldirilirsa bir X11 uygulamasinin acilir menusu
-- tiklanan yerden sag alt koseye firlar.
--
-- SIRA ONEMLI:
--   * WindowRuleApplicator.cpp: `move` efekti `center`i siler, `center` da
--     `position`i siler -- karsilikli dislayan, SON uygulanan kazanir.
--   * Isimsiz kurallar yukaridan asagi islenir (isimli olanlar hepsinden once).
--     Bu blok EN USTTE durdugu icin asagidaki zenity/Tk/tui-popup kurallarinin
--     `center = true`si onu ezer -- ozel kurallarin ortalamasi BOZULMAZ.
--     OLCULDU: zenity at=[1124,628], yani (2560-312)/2 ve 40+(1400-225)/2.
--
-- KENDI kurallarimizla float edilenler bu kuralin DISINDA kalir, ve bu
-- ordan degil mekanizmadan geliyor: WindowRule.cpp:404 `float` prop'unu
-- `w->m_isFloating` uzerinden esliyor, efektler ise sonra uygulaniyor
-- (Window.cpp:2191). Yani imv/mpv/Calculator eslesme aninda hala tiled.
-- Olculdu: imv kural sona tasindiginda bile ortada kaldi.
--
-- Hedef sag alt kose: ust taraf waybar'in (40 px rezerve) ve bildirimlerin,
-- merkez de zaten sikayetin kendisi.
-- `max(...)` kelepcedir: pencere ekrandan buyukse baslangic eksiye dusmesin.
-- Motor muParser (helpers/math/Expression.cpp).
-- IFADELER TABLO BICIMINDE VERILIR. Dize biciminde (`move = "a b"`)
-- parseExpressionVec2 ILK BOSLUKTAN boler, yani ifade ici bosluk kirilir.
hl.window_rule({
    match = { float = true, xwayland = false },
    move  = { "max(0, monitor_w - window_w - 20)", "max(40, monitor_h - window_h - 20)" },
})

-- NOT -- `modal = true` diye bir muafiyet DENENDI ve KALDIRILDI, cunku
-- olculdugunde olu cikti: Window.cpp:1681 `isModal()` yalnizca
-- `m_xwaylandSurface->m_modal`e bakiyor, yani native Wayland uygulamasinin
-- modal'i modal sayilmiyor. Yukaridaki kural zaten `xwayland = false`
-- dedigi icin muafiyetin eslesebilecegi tek kume de disarida kaliyor.
-- ACIK RISK: parola isteyen kutu (polkit) da koseye gider. Onu merkezde
-- tutmak icin sinifi gerekiyor, ve sinif UYDURULMAZ -- pencere ekrandayken
-- `hyprctl clients` ile olculur.

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
