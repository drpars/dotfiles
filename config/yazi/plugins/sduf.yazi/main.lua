local DEFAULT = {
	filled_bg = "#227d02",
	filled_bg_warn = "#a27001",
	filled_bg_danger = "#991237",
	unfilled_bg = "#45475A",
	text_fg = "#FFFFFF",
	error_fg = "red",
	warn_at = 75,
	danger_at = 90,
	border_open = "",
	border_close = "",
	margin = " ",
	position = 2900,
}

local setup = ya.sync(function(state, conf)
	state.conf = conf

	if state._done then
		return
	end
	state._done = true

	-- Cache df output, refetch when the directory changes
	local cached = { used_total = "??", percent = "??" }
	local df_handle
	local started = false

	local function refresh(cwd)
		if df_handle then
			df_handle:abort()
		end
		-- Run df in the background (doesn't freeze the UI)
		df_handle = ya.async(function()
			local output = Command("df"):arg({ "-h", tostring(cwd) }):output()

			-- Grab the 2nd line, split it into columns (FS, Size, Used, Avail, Use%)
			local data = (output and output.stdout or ""):match("[^\n]+\n([^\n]+)")
			local cols = {}
			if data then
				for token in data:gmatch("%S+") do
					cols[#cols + 1] = token
				end
			end

			local used_total = cols[2] and (cols[3] .. "/" .. cols[2]) or "??"
			local percent = cols[5] or "??"

			cached.used_total, cached.percent = used_total, percent
			df_handle = nil
			ui.render()
		end)
	end

	-- Refetch on every directory change (g shortcuts, arrows, back/forward, ...)
	ps.sub("cd", function()
		refresh(cx.active.current.cwd)
	end)

	Status:children_add(function(_)
		local c = state.conf

		-- First render, before any cd event: cx is only valid here
		if not started then
			started = true
			refresh(cx.active.current.cwd)
		end

		local used_total, percent = cached.used_total, cached.percent

		-- Fill the bar based on usage percentage
		local display = c.margin .. used_total .. c.margin .. percent .. c.margin
		local num = tonumber(percent:match("%d+"))

		if used_total == "??" or not num then
			return ui.Line({ ui.Span(" Disk: ?? "):fg(c.error_fg) })
		end

		local filled_bg = c.filled_bg
		if num >= c.danger_at then
			filled_bg = c.filled_bg_danger
		elseif num >= c.warn_at then
			filled_bg = c.filled_bg_warn
		end

		local len = #display
		-- Where to cut the bar: 0% = empty, 100% = full
		local split_idx = math.floor((num / 100) * len)

		local s1 = display:sub(1, split_idx)
		local s2 = display:sub(split_idx + 1)

		local left_cap_color = (split_idx > 0) and filled_bg or c.unfilled_bg
		local right_cap_color = (split_idx < len) and c.unfilled_bg or filled_bg

		return ui.Line({
			ui.Span(c.margin),
			ui.Span(c.border_open):fg(left_cap_color),
			ui.Span(s1):bg(filled_bg):fg(c.text_fg),
			ui.Span(s2):bg(c.unfilled_bg):fg(c.text_fg),
			ui.Span(c.border_close):fg(right_cap_color),
		})
	end, conf.position, Status.CENTER)
end)

return {
	setup = function(_, args)
		local conf = {}
		for k, v in pairs(DEFAULT) do
			conf[k] = v
		end
		for k, v in pairs(args or {}) do
			conf[k] = v
		end
		setup(conf)
	end,
}
