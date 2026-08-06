-- =======================================================
-- PENCERE KURALLARI
-- =======================================================

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
