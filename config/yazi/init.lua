-- plugins:full-border
require("full-border"):setup {
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
}

-- plugins:git
th.git = th.git or {}
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
require("git"):setup()

-- uhs-robert/recycle-bin
require("recycle-bin"):setup({
  -- Optional: Override automatic trash directory discovery
  -- trash_dir = "~/.local/share/Trash/",  -- Uncomment to use specific directory
})
