-- =======================================================
-- OTOMATİK BAŞLATMA
-- =======================================================

hl.on("hyprland.start", function()
    -- Sistem servisleri
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Duvar kağıdı
    hl.exec_cmd("awww-daemon")
    -- hl.exec_cmd("hyprpaper")

    -- Arayüz
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")

    -- Pano
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- RGB ve cihazlar
    hl.exec_cmd("openrgb --server")
    hl.exec_cmd("sleep 1 && openrgb -p pars-white")
    hl.exec_cmd("hyprpm reload")
    hl.exec_cmd("sleep 5 && openrazer-daemon -r")
    hl.exec_cmd("sleep 7 && cd ~/.razer/RazerBatteryTray && uv run razer-battery-tray 'DeathStalker' &")
    -- hl.exec_cmd("polychromatic-tray-applet")
    -- hl.exec_cmd("sleep 7 && razer-cli -e reactive,4 brightness,25 -c FFFFFF")

    -- GTK teması
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.wm.preferences theme 'Tokyonight-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Qogir-Dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Mocu-White-Right'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Ubuntu Nerd Font Regular 10'")
    hl.exec_cmd("gsettings set org.gnome.desktop.wm.preferences button-layout ''")
end)
