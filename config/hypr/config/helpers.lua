-- =======================================================
-- ORTAK DEĞİŞKENLER VE YARDIMCILAR
-- =======================================================

-- Modifier tuşlar
_G.mainMod = "SUPER"
_G.altMod  = "ALT"
_G.ctrlMod = "CTRL"

-- Uygulamalar
_G.terminal    = "kitty"
_G.fileManager = "dolphin"
_G.menu        = "rofi -replace -show drun -theme ~/.config/rofi/applications.rasi"
_G.launcher    = "rofi -replace -show drun -theme ~/.config/rofi/applications.rasi"

-- Dizinler
_G.scriptsDir = os.getenv("HOME") .. "/.config/scripts"
_G.wallpaper  = os.getenv("HOME") .. "/.config/hypr/images/wallpaper_symlink"
_G.rofiDir    = os.getenv("HOME") .. "/.config/rofi"

-- Renkler (hex formatında)
_G.colors = {
    lavender  = "rgb(b4befe)",
    pink      = "rgb(f5c2e7)",
    text      = "rgba(240, 240, 240, 1.0)",
    subtext   = "rgba(200, 200, 200, 0.9)",
    overlay   = "rgba(00000000)",
}
