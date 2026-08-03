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

-- =======================================================
-- GPU SEÇİMİ — iki dal, birbirini dışlar
-- =======================================================
-- 1) NVIDIA_ENV: makinenin açık politikası, "her şeyi dGPU'ya zorla". Tek
--    kartlı masaüstünde doğru; hibrit kurulumda (iGPU + dGPU birlikte) değil,
--    o yüzden yeteneğe değil host dosyasına bağlı.
-- 2) /dev/dri/amd-igpu: archsetup'ın vfio-igpu-symlink udev kuralı bu symlink'i
--    yalnızca hibrit makinede kuruyor, tek kartlıda yazmayı reddediyor. Yani
--    varlığı "bu makine VFIO passthrough için ayarlandı" demek.
--
-- İkisi aynı anda uygulanamaz: __GLX_VENDOR_LIBRARY_NAME'i zıt değerlere
-- kuruyorlar. Bağımsız iki `if` yazılsaydı kazananı satır sırası belirlerdi;
-- elseif bunu yapısal olarak imkânsız kılıyor.
--
-- Sıra bilinçli: elle yazılmış NVIDIA_ENV bir politika beyanıdır ve donanım
-- olgusunu ezer. Tersi olsaydı hibrit bir makinede compositor'ü dGPU'ya
-- almanın udev kuralını silmek dışında bir yolu kalmazdı; bu yönde kaçış açık.
if host.nvidia_env then
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("LIBVA_DRIVER_NAME", "nvidia")

elseif exists("/dev/dri/amd-igpu") then
    -- Compositor'ü TÜMÜYLE iGPU'ya kilitler. Dördü birlikte gerekli:
    -- AQ_DRM_DEVICES yalnızca Hyprland'in hangi karta çizeceğini söyler, ama
    -- EGL/GLX/Vulkan yükleyicileri kendi ICD taramalarını yapıp nvidia ICD'sini
    -- bulur ve /dev/nvidia0'ı AÇAR. O fd açıkken `modprobe -r nvidia` yapısal
    -- olarak imkânsızdır — yani dGPU misafir VM'e hiç devredilemez.
    -- (2026-08-03 ölçümü: kilitlemeden önce Hyprland 12 fd ile tutuyordu.)
    --
    -- Değişkenler Hyprland BAŞLAMADAN önce set edilmiş olmalı; "VM açılırken
    -- ver" diye bir seçenek yok, bu yüzden yapılandırmaya kalıcı giriyor.
    --
    -- Bedeli: G513RM'de harici DP/HDMI çıkışlarının hepsi dGPU'ya bağlı, bu
    -- blok etkinken ana makine onları süremez. Kabul edildi — harici ekran bu
    -- dizüstünde kullanılmıyor, dahili panel iGPU'da, PRIME offload etkilenmiyor.
    -- Ölçümler ve gerekçe → pars/qemu-vfio/NOTLAR.md
    hl.env("AQ_DRM_DEVICES", "/dev/dri/amd-igpu")
    hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
    hl.env("VK_DRIVER_FILES", "/usr/share/vulkan/icd.d/radeon_icd.json")
end
