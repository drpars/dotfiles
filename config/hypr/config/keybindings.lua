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
hl.bind(M .. " + SHIFT + Q",       hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind(M .. " + V",               hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + F",               hl.dsp.window.fullscreen({ action = "toggle" }))

-- ── Kilit Ekranı ───────────────────────────────────
hl.bind(M .. " + SHIFT + L",       hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

-- ── Layout ─────────────────────────────────────────
hl.bind(M .. " + P",               hl.dsp.window.pseudo())
hl.bind(M .. " + J",               hl.dsp.layout("togglesplit"))

-- ── Uygulama Başlatıcılar ──────────────────────────
hl.bind(M .. " + R",                    hl.dsp.exec_cmd(_G.menu))
hl.bind(A .. " + " .. C .. " + V",      hl.dsp.exec_cmd("cliphist list | rofi -dmenu -theme " .. _G.rofiDir .. "/window.rasi | cliphist decode | wl-copy"))
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

-- ── Fare ───────────────────────────────────────────
hl.bind(M .. " + mouse:272",           hl.dsp.window.drag(),   { mouse = true })
hl.bind(M .. " + mouse:273",           hl.dsp.window.resize(), { mouse = true })

-- ── Ekran Görüntüsü ────────────────────────────────
hl.bind("Print",                       hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

-- ── Renk Seçici ────────────────────────────────────
hl.bind(M .. " + SHIFT + X",           hl.dsp.exec_cmd("hyprpicker -a -n"))

-- ── Duvar Kağıdı ───────────────────────────────────
hl.bind(A .. " + W",                   hl.dsp.exec_cmd(_G.scriptsDir .. "/wallselect"))
hl.bind(C .. " + W",                   hl.dsp.exec_cmd("waypaper"))

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

-- ── ROG G15 Strix'e Özel Bağlamalar ─────────────────
-- hl.bind("xf86Launch1",             hl.dsp.exec_cmd("rog-control-center"))
-- hl.bind("xf86KbdBrightnessDown",   hl.dsp.exec_cmd(scriptsDir .. "/waybar/brightnesskbd down"))
-- hl.bind("xf86KbdBrightnessUp",     hl.dsp.exec_cmd(scriptsDir .. "/waybar/brightnesskbd up"))
-- hl.bind("xf86Launch3",             hl.dsp.exec_cmd("asusctl led-mode -n"))
-- hl.bind("xf86Launch4",             hl.dsp.exec_cmd(scriptsDir .. "/waybar/powerprofile next"))
-- hl.bind("xf86MonBrightnessDown",   hl.dsp.exec_cmd(scriptsDir .. "/waybar/brightness down"))
-- hl.bind("xf86MonBrightnessUp",     hl.dsp.exec_cmd(scriptsDir .. "/waybar/brightness up"))

-- ── Özel ───────────────────────────────────────────
hl.bind("WIN + F1",                    hl.dsp.exec_cmd(_G.scriptsDir .. "/gamemode"))

-- ── Plugins ────────────────────────────────────────
-- hl.bind(M .. " + m",                   function() hl.plugin.hyprexpo.expo("toggle") end)
