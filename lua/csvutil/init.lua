-- lua/csvutil/init.lua
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
    scrollbind = true,
    scrollopt = "hor",
  },
  -- Window options for main window
  main_window_opts = {
    scrollbind = true,
    scrollopt = "hor",
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

local function split_and_update_top_bottom_win()
  -- Split window horizontally
  vim.cmd("split")

  -- Get window IDs for top and bottom windows
  local tab_windows = vim.api.nvim_tabpage_list_wins(0)

  -- Filter out floating windows and get only normal windows
  local normal_windows = {}
  for _, win in ipairs(tab_windows) do
    local config = vim.api.nvim_win_get_config(win)
    -- Only include normal windows (not floating)
    if config.relative == "" then
      table.insert(normal_windows, win)
    end
  end

  -- Sort windows by position (top to bottom)
  table.sort(normal_windows, function(a, b)
    local pos_a = vim.api.nvim_win_get_position(a)
    local pos_b = vim.api.nvim_win_get_position(b)
    return pos_a[1] < pos_b[1] -- Compare row positions
  end)
  -- vim.notify("normal_windows: " .. vim.inspect(normal_windows))

  -- After split, we should have exact 2 windows
  if #normal_windows == 2 then
    csvhead_state.top_win = normal_windows[1]
    csvhead_state.bottom_win = normal_windows[2]
  else
    vim.notify("CSVUtil enable: Could not identify top and bottom windows", vim.log.levels.ERROR)
    return
  end
end

local function adjust_header(bottom_buf)
  -- vim.notify("CSVUtil: Adjusting")
  vim.api.nvim_win_set_height(csvhead_state.top_win, csvhead_state.config.header_height)
  if csvhead_state.config.set_laststatus then
    vim.opt.laststatus = 3
  end

  -- Set top window to same buffer, cursor on first line
  vim.api.nvim_win_set_buf(csvhead_state.top_win, bottom_buf)

  -- Set cursor to first line in top window
  vim.api.nvim_win_set_cursor(csvhead_state.top_win, { 1, 0 })

  -- Set window-local options
  vim.api.nvim_win_call(csvhead_state.top_win, function()
    for opt, value in pairs(csvhead_state.config.header_window_opts) do
      vim.opt_local[opt] = value
    end
  end)
  vim.api.nvim_win_call(csvhead_state.bottom_win, function()
    for opt, value in pairs(csvhead_state.config.main_window_opts or {}) do
      vim.opt_local[opt] = value
    end
  end)

  -- Make sure focus stays on bottom window
  vim.api.nvim_set_current_win(csvhead_state.bottom_win)
  -- vim.notify("CSVUtil: Adjusted")
end

-- Function to handle CSV head logic
local function update_csvhead()
  -- vim.notify("CSVUtil: Refreshing ...")
  if not csvhead_state.active then
    vim.notify("CSVUtil: try to update when disabled.", vim.log.levels.WARN)
    return
  end
  -- Validate bottom window still exists
  if not (csvhead_state.bottom_win and vim.api.nvim_win_is_valid(csvhead_state.bottom_win)) then
    vim.notify("CSVUtil: try to update when no bottom window.", vim.log.levels.WARN)
    csvhead_state.active = false
    return
  end

  -- Get the buffer and filetype of the bottom window
  local bottom_buf = vim.api.nvim_win_get_buf(csvhead_state.bottom_win)
  local bottom_filename = vim.api.nvim_buf_get_name(bottom_buf)
  local bottom_filetype = vim.bo[bottom_buf].filetype

  -- Check if it's a CSV file
  local is_csv = is_csv_file(bottom_filename, bottom_filetype)

  -- if not CSV: hide header else update header
  if not is_csv then
    if csvhead_state.top_win and vim.api.nvim_win_is_valid(csvhead_state.top_win) then
      -- vim.notify("Hide window!!!")
      vim.api.nvim_win_hide(csvhead_state.top_win)
      -- vim.notify("CSVUtil: hidden")
    end
  else
    -- For CSV files: ensure top window is visible and configured
    local top_win_valid = (csvhead_state.top_win and vim.api.nvim_win_is_valid(csvhead_state.top_win))
    if not top_win_valid then
      vim.api.nvim_set_current_win(csvhead_state.bottom_win)
      split_and_update_top_bottom_win()
    end

    adjust_header(bottom_buf)
    -- vim.notify("CSVUtil: Refreshed")
  end
end

-- Setup autocommands
local function setup_autocmds()
  if csvhead_state.augroup then
    vim.api.nvim_clear_autocmds({ group = csvhead_state.augroup })
  end

  -- Store the last buffer to detect actual changes
  local last_buffer = nil
  csvhead_state.augroup = vim.api.nvim_create_augroup("CSVUtil", { clear = true })

  -- Trigger only when bottom window buffer changes
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = csvhead_state.augroup,
    callback = function()
      if not csvhead_state.active then
        return
      end

      local current_win = vim.api.nvim_get_current_win()

      -- Only update if the current window is the bottom window
      if current_win == csvhead_state.bottom_win then
        -- local current_buffer = vim.api.nvim_win_get_buf(current_win)

        -- Only update if the buffer actually changed
        -- if current_buffer ~= last_buffer then
        --   last_buffer = current_buffer
        -- vim.notify("BufEnter")
        update_csvhead()
        -- end
      end
    end,
  })

  -- Clean up when windows are closed
  vim.api.nvim_create_autocmd("WinClosed", {
    group = csvhead_state.augroup,
    callback = function(ev)
      if csvhead_state.active then
        local closed_win = tonumber(ev.match)
        if closed_win == csvhead_state.top_win then
          -- vim.notify("Top WinClosed")
          M.disable()
        elseif closed_win == csvhead_state.bottom_win then
          -- vim.notify("Bottom WinClosed")
          M.disable()
        end
      end
    end,
  })
end

function M.enable()
  -- vim.notify("CSVUtil: Enabling ...", vim.log.levels.INFO)
  -- If already active, do nothing
  if csvhead_state.active then
    return
  end

  split_and_update_top_bottom_win()

  setup_autocmds()

  csvhead_state.active = true
  update_csvhead()
  -- vim.notify("CSVUtil: Enabled", vim.log.levels.INFO)
end

function M.disable()
  if not csvhead_state.active then
    return
  end

  csvhead_state.active = false

  -- Close top window if it exists
  if csvhead_state.top_win and vim.api.nvim_win_is_valid(csvhead_state.top_win) then
    -- vim.notify("Close window!!!")
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

  -- vim.notify("CSVUtil: Disabled", vim.log.levels.INFO)
end

-- Toggle CSV head functionality
function M.toggle()
  if csvhead_state.active then
    M.disable()
  else
    M.enable()
  end
  -- vim.notify("CSVUtil: Toggled", vim.log.levels.INFO)
end

-- Check if CSV head is active
function M.is_active()
  return csvhead_state.active
end

-- Setup function for the plugin
function M.setup(opts)
  -- vim.notify("Setup start")
  -- Merge user config with defaults
  csvhead_state.config = vim.tbl_deep_extend("force", default_config, opts or {})
  -- vim.notify(vim.inspect(csvhead_state.config))

  -- Create user commands
  vim.api.nvim_create_user_command("CSVUtil", function(args)
    local action = args.args
    if action == "enable" then
      M.enable()
    elseif action == "disable" then
      M.disable()
    elseif action == "toggle" or action == "" then
      M.toggle()
    else
      vim.notify(
        "CSVUtil: Unknown action '" .. action .. "'. Use 'enable', 'disable', or 'toggle'",
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
    desc = "Toggle CSV header",
  })

  -- vim.notify("Setup end")
end

return M
