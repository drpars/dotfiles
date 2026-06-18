-- =======================================================
-- INPUT AYARLARI
-- =======================================================

hl.config({
	input = {
		kb_layout = "us,tr",
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
