-- =======================================================
-- ORTAM DEĞİŞKENLERİ
-- =======================================================

-- Kullanıcı
hl.env("EDITOR", "nvim")
-- hl.env("TERMINAL", "kitty")

-- Toolkit Backend
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")

-- XDG kullanıcı dizinleri (~/.config/user-dirs.dirs'ten, bkz. helpers.lua).
-- Oturum SDDM'den geldiği için bunlar hiçbir yerde ortama girmiyordu; burada
-- verilince swappy gibi araçlar `save_dir=$XDG_PICTURES_DIR/...` yazabiliyor
-- ve aynı satır hem ~/Resimler hem ~/Pictures olan makinede doğru oluyor.
for key, value in pairs(xdg) do
    hl.env(key, value)
end

-- XDG
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_MENU_PREFIX", "arch-")

-- QT
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- qt6ct, hyprqt6engine

-- NVIDIA — yalnızca dGPU'ya zorlanan makinelerde. Hibrit kurulumda (iGPU +
-- dGPU birlikte) doğru değil, o yüzden makineye bağlı.
if host.nvidia_env then
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
end
