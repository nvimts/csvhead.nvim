-- lua/csvhead/init.lua
local M = {}

-- Default configuration
local default_config = {
	-- Auto-detect CSV files by extension
	auto_detect_csv = true,
	-- File extensions to consider as CSV
	csv_extensions = { "csv", "tsv" },
	-- Filetype names to consider as CSV
	csv_filetypes = { "csv" },
	-- Top window height
	header_height = 1,
	-- Set laststatus to 3 when active
	set_laststatus = true,
	-- Window options for header window
	header_window_opts = {
		wrap = false,
		scrollbind = false,
		cursorbind = false,
	},
}

-- Plugin state
local csvhead_state = {
	top_win = nil,
	bottom_win = nil,
	active = false,
	config = {},
	augroup = nil,
}

-- Check if a file is CSV based on config
local function is_csv_file(filename, filetype)
	local config = csvhead_state.config

	-- Check by filetype
	for _, ft in ipairs(config.csv_filetypes) do
		if filetype == ft then
			return true
		end
	end

	-- Check by extension
	if config.auto_detect_csv then
		for _, ext in ipairs(config.csv_extensions) do
			if filename:match("%." .. ext .. "$") then
				return true
			end
		end
	end

	return false
end

-- Function to handle CSV head logic
local function update_csvhead()
	if not csvhead_state.active then
		return
	end

	-- Validate windows still exist
	if
		not (
			csvhead_state.top_win
			and vim.api.nvim_win_is_valid(csvhead_state.top_win)
			and csvhead_state.bottom_win
			and vim.api.nvim_win_is_valid(csvhead_state.bottom_win)
		)
	then
		csvhead_state.active = false
		return
	end

	-- Get the buffer and filetype of the bottom window
	local bottom_buf = vim.api.nvim_win_get_buf(csvhead_state.bottom_win)
	local bottom_filename = vim.api.nvim_buf_get_name(bottom_buf)
	local bottom_filetype = vim.api.nvim_buf_get_option(bottom_buf, "filetype")

	-- Check if it's a CSV file
	local is_csv = is_csv_file(bottom_filename, bottom_filetype)

	if not is_csv then
		-- Hide top window completely if not a CSV file
		vim.api.nvim_win_hide(csvhead_state.top_win)
	else
		-- For CSV files: ensure top window is visible and configured
		pcall(function()
			-- Make sure top window is visible (unhide if hidden)
			vim.api.nvim_win_set_config(csvhead_state.top_win, {})

			-- Set top window height and configure laststatus
			vim.api.nvim_win_set_height(csvhead_state.top_win, csvhead_state.config.header_height)

			if csvhead_state.config.set_laststatus then
				vim.opt.laststatus = 3
			end

			-- Set top window to same buffer, cursor on first line
			vim.api.nvim_win_set_buf(csvhead_state.top_win, bottom_buf)

			-- Set cursor to first line in top window
			vim.api.nvim_win_set_cursor(csvhead_state.top_win, { 1, 0 })

			-- Set window-local options for better CSV header display
			vim.api.nvim_win_call(csvhead_state.top_win, function()
				for opt, value in pairs(csvhead_state.config.header_window_opts) do
					vim.opt_local[opt] = value
				end
			end)
		end)
	end
end

-- Setup autocommands
local function setup_autocmds()
	if csvhead_state.augroup then
		vim.api.nvim_clear_autocmds({ group = csvhead_state.augroup })
	end

	csvhead_state.augroup = vim.api.nvim_create_augroup("CSVHead", { clear = true })

	-- Trigger on buffer enter/change in any window
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		group = csvhead_state.augroup,
		callback = function()
			-- Only update if the current window is the bottom window
			if csvhead_state.active and vim.api.nvim_get_current_win() == csvhead_state.bottom_win then
				update_csvhead()
			end
		end,
	})

	-- Trigger on filetype changes
	vim.api.nvim_create_autocmd("FileType", {
		group = csvhead_state.augroup,
		callback = function()
			if csvhead_state.active then
				update_csvhead()
			end
		end,
	})

	-- Clean up when windows are closed
	vim.api.nvim_create_autocmd("WinClosed", {
		group = csvhead_state.augroup,
		callback = function(ev)
			if csvhead_state.active then
				local closed_win = tonumber(ev.match)
				if closed_win == csvhead_state.top_win or closed_win == csvhead_state.bottom_win then
					M.disable()
				end
			end
		end,
	})
end

-- Enable CSV head functionality
function M.enable()
	-- If already active, do nothing
	if csvhead_state.active then
		return
	end

	-- Split window horizontally
	vim.cmd("split")

	-- Get window IDs for top and bottom windows
	local tab_windows = vim.api.nvim_tabpage_list_wins(0)

	-- Sort windows by position (top to bottom)
	table.sort(tab_windows, function(a, b)
		local pos_a = vim.api.nvim_win_get_position(a)
		local pos_b = vim.api.nvim_win_get_position(b)
		return pos_a[1] < pos_b[1] -- Compare row positions
	end)

	-- After split, we should have at least 2 windows
	if #tab_windows >= 2 then
		csvhead_state.top_win = tab_windows[1]
		csvhead_state.bottom_win = tab_windows[2]
		csvhead_state.active = true
	else
		vim.notify("CSVHead: Could not identify top and bottom windows", vim.log.levels.ERROR)
		return
	end

	-- Setup autocommands
	setup_autocmds()

	-- Initial setup
	update_csvhead()

	vim.notify("CSVHead: Enabled - will automatically update on buffer changes", vim.log.levels.INFO)
end

-- Disable CSV head functionality
function M.disable()
	if not csvhead_state.active then
		return
	end

	csvhead_state.active = false

	-- Close top window if it exists
	if csvhead_state.top_win and vim.api.nvim_win_is_valid(csvhead_state.top_win) then
		vim.api.nvim_win_close(csvhead_state.top_win, false)
	end

	-- Clear autocommands
	if csvhead_state.augroup then
		vim.api.nvim_clear_autocmds({ group = csvhead_state.augroup })
	end

	-- Reset state
	csvhead_state.top_win = nil
	csvhead_state.bottom_win = nil
	csvhead_state.augroup = nil

	vim.notify("CSVHead: Disabled", vim.log.levels.INFO)
end

-- Toggle CSV head functionality
function M.toggle()
	if csvhead_state.active then
		M.disable()
	else
		M.enable()
	end
end

-- Check if CSV head is active
function M.is_active()
	return csvhead_state.active
end

-- Setup function for the plugin
function M.setup(opts)
	-- Merge user config with defaults
	csvhead_state.config = vim.tbl_deep_extend("force", default_config, opts or {})

	-- Create user commands
	vim.api.nvim_create_user_command("CSVHead", function(args)
		local action = args.args
		if action == "enable" then
			M.enable()
		elseif action == "disable" then
			M.disable()
		elseif action == "toggle" or action == "" then
			M.toggle()
		else
			vim.notify(
				"CSVHead: Unknown action '" .. action .. "'. Use 'enable', 'disable', or 'toggle'",
				vim.log.levels.ERROR
			)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "enable", "disable", "toggle" }
		end,
		desc = "Control CSV header window functionality",
	})

	-- Create shorter alias
	vim.api.nvim_create_user_command("CH", function()
		M.toggle()
	end, {
		desc = "Toggle CSV header window (CSVHead alias)",
	})
end

return M
