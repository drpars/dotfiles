-- plugins:full-border
require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

-- plugins:git
th.git = th.git or {}
th.git.unknown_sign = " "
th.git.added_sign = ""
th.git.deleted_sign = ""
th.git.modified_sign = "󰝤"
th.git.untracked_sign = "󰬜"
th.git.clean_sign = "✔"
require("git"):setup({
	-- Order of status signs showing in the linemode
	order = 1500,
})

-- uhs-robert/recycle-bin
require("recycle-bin"):setup({
	-- Optional: Override automatic trash directory discovery
	-- trash_dir = "~/.local/share/Trash/",  -- Uncomment to use specific directory
})
