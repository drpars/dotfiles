-- =======================================================
-- TEMA: CURSOR, GTK, ICON
-- =======================================================

-- Cursor
hl.env("HYPRCURSOR_THEME", "Mocu-White-Right")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Mocu-White-Right")
hl.env("XCURSOR_SIZE", "24")

-- GTK teması burada AYARLANMIYOR. Etkin kanal gsettings/dconf
-- (org.gnome.desktop.interface) ve `autostart.lua` onu yazıyor; GTK_THEME env'i
-- aynı değeri ikinci kez söylemekten başka bir şey yapmıyordu. Üstelik zararı
-- var: GTK_THEME en yüksek öncelikli geçersiz kılma olduğu için yazılıyken
-- dconf'tan yapılan tema değişikliği yeni açılan uygulamalarda da tutmaz.
-- Ölçüm → pars/dotfiles/arsiv-2026-08.md
