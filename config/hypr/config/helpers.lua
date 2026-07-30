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

-- =======================================================
-- SISTEM SORGULAMA
-- =======================================================
-- Bu yapılandırma birden fazla makinede kullanılıyor. Ayrım için marka değil
-- YETENEK sorulur: bir bağlama kurulu olmayan bir aracı çağırıyorsa, doğru
-- donanımda bile ölüdür. Yeteneğe sorulamayan şeyler (monitör çıkışı gibi)
-- için kimlik anahtarı DMI `board_name` — hostname elle değişebilir, o sabit.

-- NOT: os.execute BURADA KULLANILMAZ. Hyprland'in Lua 5.5 VM'inde komut
-- çalışıyor ama dönüş değeri gelmiyor (os.execute() → false, yani "kabuk yok"),
-- dolayısıyla koşul olarak okunamaz. Aşağıdakiler yalnız io kullanır: kabuk
-- doğurmaz, alt süreç açmaz.

-- Dosya var mı / açılabiliyor mu (dizinlerde de çalışır)
function _G.exists(path)
    local fh = io.open(path, "r")
    if not fh then return false end
    fh:close()
    return true
end

local function read_line(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local line = fh:read("l")
    fh:close()
    return line
end

-- /sys/class/dmi/id/<field> — ör. dmi("board_name") == "G513RM"
function _G.dmi(field)
    return read_line("/sys/class/dmi/id/" .. field)
end

function _G.hostname()
    return read_line("/etc/hostname")
end

-- Komut PATH'te var mı — PATH'i kendimiz tarıyoruz
function _G.has(cmd)
    for dir in (os.getenv("PATH") or ""):gmatch("[^:]+") do
        if exists(dir .. "/" .. cmd) then return true end
    end
    return false
end

-- =======================================================
-- MAKİNEYE ÖZGÜ OLGULAR
-- =======================================================
-- Yeteneğe sorulamayan şeyler burada. `config/hosts/<board_name>.lua` varsa
-- bu tabloyu ezer (bkz. hyprland.lua).
--
-- DİKKAT: Aşağıdaki varsayılanlar şu an MASAÜSTÜNÜN değerleri, yani "host
-- dosyası yoksa masaüstüdür" varsayımı. Geçici: masaüstünün board_name'i
-- öğrenilip kendi host dosyası açılınca bunlar nötrleştirilecek
-- (output = "", mode = "preferred", bayraklar false).
_G.host = {
    monitor = {
        output   = "DP-1",
        mode     = "2560x1440@120",
        position = "0x0",
        scale    = 1,
        bitdepth = 10,
        cm       = "wide", -- wide|hdr
    },
    nvidia_env  = true,     -- her şeyi nvidia-drm'e zorla (hibrit olmayan makine)
    rgb_devices = true,     -- OpenRGB / Razer cihazları bu makinede var
    kb_layout   = "us,tr",  -- fiziksel klavyenin dizilimi; ilki öncelikli
}

-- Renkler (hex formatında)
_G.colors = {
    lavender  = "rgb(b4befe)",
    pink      = "rgb(f5c2e7)",
    text      = "rgba(240, 240, 240, 1.0)",
    subtext   = "rgba(200, 200, 200, 0.9)",
    overlay   = "rgba(00000000)",
}
