-- =======================================================
-- GENEL AYARLAR
-- =======================================================

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 1,

		col = {
			active_border = { colors = { _G.colors.lavender, _G.colors.pink }, angle = 45 },
			inactive_border = _G.colors.overlay,
		},

		resize_on_border = false,
		allow_tearing = true,
		layout = "dwindle",
	},
})
