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
