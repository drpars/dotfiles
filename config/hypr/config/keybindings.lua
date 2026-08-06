-- =======================================================
-- TUŞ BAĞLANTILARI
-- =======================================================

local M = _G.mainMod
local A = _G.altMod
local C = _G.ctrlMod

-- ── Temel Uygulamalar ──────────────────────────────
hl.bind(M .. " + RETURN", hl.dsp.exec_cmd(_G.terminal))
hl.bind(M .. " + D",      hl.dsp.exec_cmd(_G.fileManager))
hl.bind(M .. " + Y",      hl.dsp.exec_cmd(_G.terminal .. " yazi"))

-- ── Pencere Yönetimi ───────────────────────────────
hl.bind(M .. " + Q",               hl.dsp.window.close())
-- Dogrudan dispatcher; kabuk dogurulmuyor. Onceki hali
-- `exec_cmd("hyprctl dispatch exit")` idi ve OLUYDU: hyprctl klasik bicimi Lua
-- ayristiricisinda `hl.dispatch(exit)`'e ceviriyor, `exit` global bir ad
-- olmadigi icin nil gidiyor ve komut rc=7 ile dusuyordu (olculdu 2026-08-06).
hl.bind(M .. " + SHIFT + Q",       hl.dsp.exit())
hl.bind(M .. " + V",               hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + F",               hl.dsp.window.fullscreen({ action = "toggle" }))

-- ── Kilit Ekranı ───────────────────────────────────
hl.bind(M .. " + SHIFT + L",       hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

-- ── Güç Menüsü ─────────────────────────────────────
hl.bind(M .. " + X",               hl.dsp.exec_cmd(_G.scriptsDir .. "/powermenu"))

-- ── Layout ─────────────────────────────────────────
hl.bind(M .. " + P",               hl.dsp.window.pseudo())
hl.bind(M .. " + J",               hl.dsp.layout("togglesplit"))

-- ── Uygulama Başlatıcılar ──────────────────────────
hl.bind(M .. " + R",                    hl.dsp.exec_cmd(_G.menu))
hl.bind(A .. " + " .. C .. " + V",      hl.dsp.exec_cmd("cliphist list | rofi -replace -dmenu -theme " .. _G.rofiDir .. "/window.rasi | cliphist decode | wl-copy"))
hl.bind(A .. " + A",                    hl.dsp.exec_cmd('zsh -i -c "alias | rofi -dmenu -replace -theme ' .. _G.rofiDir .. '/window.rasi 2> /dev/null"'))
hl.bind(A .. " + TAB",                  hl.dsp.exec_cmd(_G.scriptsDir .. "/windowswitch"))

-- ── Focus ──────────────────────────────────────────
hl.bind(M .. " + left",            hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + right",           hl.dsp.focus({ direction = "right" }))
hl.bind(M .. " + up",              hl.dsp.focus({ direction = "up" }))
hl.bind(M .. " + down",            hl.dsp.focus({ direction = "down" }))

-- ── Pencere Taşıma ─────────────────────────────────
hl.bind(M .. " + " .. C .. " + left",   hl.dsp.window.move({ direction = "left" }))
hl.bind(M .. " + " .. C .. " + right",  hl.dsp.window.move({ direction = "right" }))
hl.bind(M .. " + " .. C .. " + up",     hl.dsp.window.move({ direction = "up" }))
hl.bind(M .. " + " .. C .. " + down",   hl.dsp.window.move({ direction = "down" }))

-- ── Resize Submap ──────────────────────────────────
hl.bind(A .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
    hl.bind("left",  hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- ── Çalışma Alanları ───────────────────────────────
for i = 1, 10 do
    local key = i % 10
    hl.bind(M .. " + " .. key,              hl.dsp.focus({ workspace = i }))
    hl.bind(M .. " + SHIFT + " .. key,      hl.dsp.window.move({ workspace = i }))
end

hl.bind(M .. " + tab",                 hl.dsp.focus({ workspace = "m+1" }))
hl.bind(M .. " + mouse_down",          hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up",            hl.dsp.focus({ workspace = "e-1" }))

-- ── Scratchpad'ler ─────────────────────────────────
-- Gomulu toggle_special yalnizca gosterip gizler, BASLATMAZ; eksigi kapatan
-- sarmalayici config/scripts/scratchtoggle. Pencereyi alana koyan sey ise
-- windowrules.lua'daki sinif kurali (oradaki "Scratchpad'ler" bolumu).
local home = os.getenv("HOME")

-- Anlik notlar. Tek dosya; `nvim +` imleci dosyanin sonuna atar -- nvim
-- yapilandirmasina dokunmadan calisir, o yuzden nvim deposunda karsiligi yok.
hl.bind(M .. " + N", hl.dsp.exec_cmd(
    _G.scriptsDir .. "/scratchtoggle notlar scratch-notes " ..
    _G.terminal .. " --class=scratch-notes nvim + " .. home .. "/notlar.md"))

-- WhatsApp Web. Sinif olculdu, uydurulmadi -- gerekce windowrules.lua'da.
hl.bind(M .. " + W", hl.dsp.exec_cmd(
    _G.scriptsDir .. "/scratchtoggle whatsapp chrome-web.whatsapp.com__-Default " ..
    "google-chrome-stable --app=https://web.whatsapp.com/ " ..
    "--user-data-dir=" .. home .. "/.local/share/webapps/whatsapp"))

-- Herhangi bir pencereyi scratchpad'e gonder (dagitimin ornegindeki desen).
hl.bind(M .. " + SHIFT + N", hl.dsp.window.move({ workspace = "special:notlar" }))
hl.bind(M .. " + SHIFT + W", hl.dsp.window.move({ workspace = "special:whatsapp" }))

-- ── Fare ───────────────────────────────────────────
hl.bind(M .. " + mouse:272",           hl.dsp.window.drag(),   { mouse = true })
hl.bind(M .. " + mouse:273",           hl.dsp.window.resize(), { mouse = true })

-- ── Ekran Görüntüsü ────────────────────────────────
-- Üç mod da swappy'ye giriyor: işaretle, sonra Ctrl+S ile kaydet veya Ctrl+C
-- ile panoya kopyala. `--raw` diske bir şey yazmaz, kaydetme kararı swappy'de
-- kalır. `-s` hyprshot'ın kendi bildirimini susturur (dosya kaydetmiyor ki).
-- `-z` seçim boyunca ekranı dondurur; tam ekran modunda seçim olmadığı için yok.
hl.bind("Print",                       hl.dsp.exec_cmd("hyprshot -m region -z --raw -s | swappy -f -"))
hl.bind("SHIFT + Print",               hl.dsp.exec_cmd("hyprshot -m window -z --raw -s | swappy -f -"))
hl.bind(C .. " + Print",               hl.dsp.exec_cmd("hyprshot -m output --raw -s | swappy -f -"))

-- ── Renk Seçici ────────────────────────────────────
hl.bind(M .. " + SHIFT + X",           hl.dsp.exec_cmd("hyprpicker -a -n"))

-- ── Duvar Kağıdı ───────────────────────────────────
hl.bind(A .. " + W",                   hl.dsp.exec_cmd(_G.scriptsDir .. "/wallselect"))

-- ── Waybar ─────────────────────────────────────────
hl.bind(M .. " + B",                   hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(M .. " + " .. A .. " + R",     hl.dsp.exec_cmd(scriptsDir .. "/refreshwaybar"))

-- ── Ses ────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(_G.scriptsDir .. "/volume upvol"),    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(_G.scriptsDir .. "/volume downvol"),  { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(_G.scriptsDir .. "/volume togglevol"),{ locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(_G.scriptsDir .. "/volume togglemic"),{ locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),              { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),                    { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),                { locked = true })

-- ── ASUS / ROG Bağlamaları ─────────────────────────
-- Marka değil yetenek sorulur (bkz. helpers.lua): araç kurulu değilse bağlama
-- doğru donanımda bile ölü olurdu, tersine kurulduğu her yerde çalışır.
if has("rog-control-center") then
    hl.bind("xf86Launch1",         hl.dsp.exec_cmd("rog-control-center"))
end

if has("asusctl") then
    hl.bind("xf86Launch3",         hl.dsp.exec_cmd("asusctl led-mode -n"))
    hl.bind("xf86Launch4",         hl.dsp.exec_cmd(scriptsDir .. "/powerprofileasus next"))
end

-- Klavye arka ışığı: asusctl'e değil, LED arayüzünün varlığına bağlı
if exists("/sys/class/leds/asus::kbd_backlight") then
    hl.bind("xf86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/brightness down kbd"))
    hl.bind("xf86KbdBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/brightness up kbd"))
end

-- ── Ekran Parlaklığı ───────────────────────────────
-- ROG'a özgü değil: bu tuşlar zaten yalnız dizüstü klavyelerinde var.
hl.bind("xf86MonBrightnessDown",   hl.dsp.exec_cmd(scriptsDir .. "/brightness down"))
hl.bind("xf86MonBrightnessUp",     hl.dsp.exec_cmd(scriptsDir .. "/brightness up"))

-- ── Özel ───────────────────────────────────────────
hl.bind("WIN + F1",                    hl.dsp.exec_cmd(_G.scriptsDir .. "/gamemode"))

-- ── Plugins ────────────────────────────────────────
-- hl.bind(M .. " + m",                   function() hl.plugin.hyprexpo.expo("toggle") end)
