-- =======================================================
-- ÇALIŞMA ALANI KURALLARI
-- =======================================================

-- İsteğe bağlı: Belirli çalışma alanları için özel kurallar
-- hl.workspace_rule({
--     workspace = "w[tv1]",
--     gaps_out  = 0,
--     gaps_in   = 0,
-- })

-- ── Special alanlar: ortada, her eksende %80'lik panel ──
-- 0.57'den once bunu dwindle:special_scale_factor = 0.8 yapiyordu. 0.57.0'da
-- ayar yalnizca TANIMLI duruyor, kaynakta onu okuyan kod yok (v0.57.0
-- etiketinde ConfigValues.cpp disinda eslesme yok); deprecated-config
-- "workspace rules" diyor. Yerine gecen: special alanlara ozel gaps_out.
-- Bosluk PIKSEL, oran degil -- bu yapilandirma iki makinede kosuyor ve
-- ekranlari farkli, o yuzden kural monitor basina buradan hesaplaniyor.
-- Hesap tam monitor boyundan (reserved/waybar dusulmeden): monitor eklendigi
-- anda waybar henuz yok, reserved 0 okunur.
local SPECIAL_SCALE = 0.8
local _special_rules = {}

local function special_gaps(mon)
    if not mon or _special_rules[mon.name] then return end
    local base = 10 -- general.lua gaps_out; degisirse burasi da
    local w = mon.width / mon.scale
    local h = mon.height / mon.scale
    local mx = math.floor(base + (w - 2 * base) * (1 - SPECIAL_SCALE) / 2 + 0.5)
    local my = math.floor(base + (h - 2 * base) * (1 - SPECIAL_SCALE) / 2 + 0.5)
    _special_rules[mon.name] = hl.workspace_rule({
        workspace = "s[true] m[" .. mon.name .. "]",
        gaps_out  = { top = my, right = mx, bottom = my, left = mx },
    })
end

-- Reload'da monitorler zaten var; ilk aciliste config monitorlerden once
-- okunabilir, o dal monitor.added'dan gelir.
for _, mon in ipairs(hl.get_monitors()) do special_gaps(mon) end
hl.on("monitor.added", special_gaps)
