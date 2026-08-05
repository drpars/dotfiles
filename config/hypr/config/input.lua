-- =======================================================
-- INPUT AYARLARI
-- =======================================================

hl.config({
	input = {
		-- Fiziksel klavye makineye göre değişiyor (bkz. config/hosts/).
		kb_layout = host.kb_layout,
		kb_options = "grp:alt_shift_toggle",
		kb_variant = "",
		kb_model = "",
		kb_rules = "",
		numlock_by_default = true,
		follow_mouse = 1,

		-- Uyarlamalı (adaptive) fare ivmesini kapat: 1:1, hareket hızından
		-- bağımsız sabit oran (Windows hissine yakın, daha kontrollü).
		accel_profile = "flat",

		touchpad = {
			natural_scroll = false,
			clickfinger_behavior = true,
		},
	},
})

-- =======================================================
-- HAREKETLER (GESTURES)
-- =======================================================
-- Üç parmak yatay kaydırma → çalışma alanı değiştir.
--
-- Bu ayrı bir çağrı, `gestures` bölümünün altında bir anahtar DEĞİL: Hyprland
-- 0.51'de hareketler yeniden yazıldı ve açma/kapama anahtarı olan
-- `gestures:workspace_swipe` KALDIRILDI (0.56.1'de `hyprctl getoption` "no such
-- option" diyor). `gestures` altında yalnızca ayar düğmeleri kaldı —
-- `workspace_swipe_distance`, `_invert`, `_cancel_ratio`, `_create_new` … —
-- ama hiçbiri hareketi var etmiyor; hareketin kendisi burada bildirilir.
-- Bu yüzden .conf'tan Lua'ya geçerken sessizce düştü: taşınacak bir anahtar
-- yoktu. Karşılığı dağıtımın örnek dosyasında duruyor: /usr/share/hypr/hyprland.lua.
--
-- Makine koruması yok: touchpad'i olmayan makinede hareket hiç tetiklenmez,
-- yani masaüstünde ölü değil, sadece sessiz.
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
