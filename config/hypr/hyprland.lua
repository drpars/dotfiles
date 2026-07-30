-- =======================================================
--  __  _____  _____      __  ____  ____
-- /  |/  / / / / / | /| / / / __ \/ __/
-- / /|_/ / /_/_  _/ |/ |/ / / /_/ /\ \
-- /_/  /_/____//_/ |__/|__/  \____/___/
--
-- Hyprland Modüler Yapılandırma
-- =======================================================

-- Yardımcılar ve ortak değişkenler (önce yüklenmeli)
require("config.helpers")

-- Makineye özgü olgular: config/hosts/<board_name>.lua varsa host tablosunu
-- ezer. Aşağıdaki modüllerden ÖNCE yüklenmeli. Dosya yoksa sessizce atlanır;
-- varsa ve içinde hata varsa hata gizlenmez (bilerek pcall kullanılmıyor).
local board = (dmi("board_name") or ""):gsub("[^%w%-_]", "_")
if board ~= "" and exists(os.getenv("HOME") .. "/.config/hypr/config/hosts/" .. board .. ".lua") then
    require("config.hosts." .. board)
end

-- Sistem ve donanım
require("config.monitors")
require("config.input")
require("config.environment")

-- Görünüm ve tema
require("config.theme")
require("config.general")
require("config.decoration")
require("config.animations")
require("config.layouts")
require("config.misc")

-- Fonksiyonel modüller
require("config.autostart")
require("config.keybindings")
require("config.windowrules")
require("config.workspacerules")
require("config.plugins")
