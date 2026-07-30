-- =======================================================
-- MAKİNE: MSI MEG Z490 UNIFY (masaüstü, PANTHERA-ARCH)
-- =======================================================
-- DMI board_name = "MEG Z490 UNIFY (MS-7C71)". Boşluk ve parantez dosya adına
-- çevrilirken sadeleşiyor (bkz. hyprland.lua) → MEG_Z490_UNIFY_MS-7C71.lua
--
-- Buraya YALNIZCA yeteneğe sorulamayan olgular yazılır. "Araç kurulu mu"
-- türünden her şey helpers.lua'daki has()/exists() ile çözülür.

-- MSI MAG274QRF-QD
host.monitor = {
    output   = "DP-1",
    mode     = "2560x1440@120",
    position = "0x0",
    scale    = 1,
    bitdepth = 10,
    cm       = "wide", -- wide|hdr
}

-- Tek GPU: RTX 3070, amdgpu yok. Hibrit olmadığı için her şeyi nvidia-drm'e
-- yönlendirmek burada doğru.
host.nvidia_env = true

-- OpenRGB profilleri (pars-white/pars-off) ve openrazer cihazları burada.
host.rgb_devices = true

-- US klavye.
host.kb_layout = "us,tr"
