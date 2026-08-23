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
    -- Notlar da dar, ama hesaptan GENIS: metin yaziliyor, sayi degil.
    -- 1400x1102 = ekranin %54,7'si; at=(580,189), sol/sag 580/580.
    -- Anlamli olcu piksel degil SUTUN, ve iki nokta olculdu (tek kullanimlik
    -- bir sinifla, kullanicinin acik nvim'ine dokunmadan): 1100 px -> 119
    -- sutun, 1400 px -> 152 sutun. Cozum: hucre 9,091 px, kenar dolgusu
    -- 9,1 px/yan. Baska bir genislik istenirse sutun sayisi buradan cikar --
    -- yeniden olcmeye gerek yok, ama FONT DEGISIRSE bu cozum bayatlar.
    -- Kural MAP aninda kosar: acik pencere yeni boyu bir sonraki acilista alir.
    float     = true,
    center    = true,
    size      = { 1400, 1102 },
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

-- Hesap makinesi: kitty + qalc, kendi sinifiyla.
-- Motor qalculate-gtk ile AYNI (libqalculate); degisen yalnizca kapi. Sinif
-- burada da secilebiliyor -- qalculate-gtk secilemezdi: GTK app_id'sini cagri
-- basina veremezsin, kural rofi'den acilan pencereyi de yutardi (ayni sinif
-- tuzak yukarida Chrome'da OLCULDU).
-- float/center/size YAZILMIYOR ve bu bir karar: dwindle:special_scale_factor
-- 0.8 oldugu icin special alanda tek basina duran pencere zaten ortalanmis
-- panel olarak ciziliyor. OLCULDU (2026-08-24, eDP-1 2560x1440, reserved ust
-- 40): at=(265,189) size=2030x1102 -- sol/sag bosluk 265/265, ust/alt 149/149,
-- yani iki eksende de tam merkez; olcek 0,793 x 0,787 (fark gaps + border).
-- floating=false: pencere TILED, "float gibi gorunmesini" veren sey scale
-- faktoru. Ucluyu ayrica yazmak ayni sonucu ikinci bir yerden tarif etmek
-- olurdu -- ve iki tarif birlikte guncellenmez.
hl.window_rule({
    match     = { class = "scratch-calc" },
    workspace = "special:hesap silent",
    -- Kullanici bu ikisini (notlar + hesap) yatayda dar istedi, whatsapp ve
    -- terminal genis kalsin. special_scale_factor GLOBAL -- tek bir alani
    -- daraltamaz, o yuzden daralan pencereler float'a alindi.
    -- OLCULDU (2026-08-24): istenen boy AYNEN geliyor -- scale faktoru float
    -- pencereyi fazladan kucultmuyor. 1102 yukseklikle sinandiginda dikey konum
    -- tiled hale BIREBIR esit cikti (ust/alt 149/149), yani `center` tiled
    -- yerlesimin merkeziyle ayni yeri veriyor; notlar kurali o boyda kaldi.
    -- Hesap = 1100x700: notlarin aksine tam boy DEGIL, cunku goz atilan bir
    -- panel. Anlamli olcu piksel degil HUCRE: bu boyda kitty 33 satir x 119
    -- sutun aliyor (olculdu -- ayni kurali alan bir kitty `stty size`'i dosyaya
    -- yazdi), yani qalc'in ~8 hesaplik gecmisi ekranda kaliyor.
    -- Geometri: at=(730,390), sol/sag 730/730, ust/alt 350/350.
    float     = true,
    center    = true,
    size      = { 1100, 700 },
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
