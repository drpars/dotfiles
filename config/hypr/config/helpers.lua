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

-- KEY="value" biçimli bir dosyayı tabloya oku. Yorumlar ve bozuk satırlar
-- düşer; `source` etmediğimiz için dosyaya sızmış bir komut çalışmaz.
local function read_conf(path)
    local t = {}
    local fh = io.open(path, "r")
    if not fh then return t end
    for line in fh:lines() do
        local k, v = line:match('^%s*([A-Z0-9_]+)%s*=%s*(.-)%s*$')
        if k then t[k] = (v:gsub('^"(.*)"$', "%1")) end
    end
    fh:close()
    return t
end

-- =======================================================
-- MAKİNEYE ÖZGÜ OLGULAR
-- =======================================================
-- Kaynak: ~/.config/hosts/<board_id>.conf — **tek gerçek kaynak**. Aynı
-- dosyayı kabuk betikleri de okuyor (scripts/hostfact), böylece bir olgu iki
-- dilde iki kez yazılmıyor. Yoksa aşağıdaki nötr varsayılanlar geçerli:
-- tanınmayan makinede Hyprland'in kendi varsayılanlarına düşülür, hiçbir
-- donanım varsayılmaz.
--
-- board_id türetimi hostfact'teki ile aynı tutulmalı: dosya adı dostu olmayan
-- karakterler _, ardışıklar toplanır, uçlar kırpılır. (MSI "MEG Z490 UNIFY
-- (MS-7C71)" diyor → MEG_Z490_UNIFY_MS-7C71.)
function _G.board_id()
    local raw = dmi("board_name") or ""
    return (raw:gsub("[^%w%-_]", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", ""))
end

local _hc = {}
do
    local id = board_id()
    if id ~= "" then
        _hc = read_conf(os.getenv("HOME") .. "/.config/hosts/" .. id .. ".conf")
    end
end

local function _bool(key, default)
    local v = _hc[key]
    if v == nil then return default end
    return v == "true"
end
local function _str(key, default)
    return _hc[key] or default
end
-- Sayıya çevrilebiliyorsa sayı; değilse ("auto" gibi) olduğu gibi.
local function _num(key, default)
    local v = _hc[key]
    if v == nil then return default end
    return tonumber(v) or v
end

_G.host = {
    monitor = {
        output   = _str("MONITOR_OUTPUT", ""),
        mode     = _str("MONITOR_MODE", "preferred"),
        position = _str("MONITOR_POSITION", "auto"),
        scale    = _num("MONITOR_SCALE", "auto"),
        bitdepth = _num("MONITOR_BITDEPTH", nil),
        cm       = _str("MONITOR_CM", nil),
    },
    nvidia_env  = _bool("NVIDIA_ENV", false),   -- dGPU'ya zorlama
    rgb_devices = _bool("RGB_DEVICES", false),  -- OpenRGB / Razer varsayma
    kb_layout   = _str("KB_LAYOUT", "us,tr"),   -- ilki öncelikli
}

-- =======================================================
-- XDG KULLANICI DİZİNLERİ
-- =======================================================
-- İki makine farklı yerelde kuruldu: masaüstünde ~/Pictures, dizüstünde
-- ~/Resimler. Oturum SDDM'den geldiği için user-dirs.dirs hiçbir yerde
-- ortama alınmıyor. Burada okunup environment.lua'da hl.env ile veriliyor;
-- böylece swappy gibi araçlar save_dir=$XDG_PICTURES_DIR/... yazabiliyor ve
-- aynı satır iki makinede de doğru oluyor.
_G.xdg = {}
do
    local home = os.getenv("HOME") or ""
    local fh = io.open(home .. "/.config/user-dirs.dirs", "r")
    if fh then
        for line in fh:lines() do
            local k, v = line:match('^%s*(XDG_[A-Z]+_DIR)%s*=%s*"(.-)"')
            if k then _G.xdg[k] = (v:gsub("%$HOME", home)) end
        end
        fh:close()
    end
end

-- Renkler (hex formatında)
_G.colors = {
    lavender  = "rgb(b4befe)",
    pink      = "rgb(f5c2e7)",
    text      = "rgba(240, 240, 240, 1.0)",
    subtext   = "rgba(200, 200, 200, 0.9)",
    overlay   = "rgba(00000000)",
}
