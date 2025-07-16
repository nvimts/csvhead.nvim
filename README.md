# csvhead.nvim

A Neovim plugin that automatically displays CSV file headers in a dedicated window for better navigation and reference.

## Features

- **Automatic Detection**: Automatically detects CSV files and shows/hides the header window
- **Dynamic Updates**: Responds to buffer changes, automatically updating when switching between files
- **Configurable**: Customizable file extensions, window options, and behavior
- **LazyVim Compatible**: Designed to work seamlessly with LazyVim

## Installation

### With LazyVim

Add to your `~/.config/nvim/lua/plugins/csvhead.lua`:

```lua
return {
  "nvimts/csvhead.nvim",
  ft = "csv", -- Load only for CSV files
  config = function()
    require("csvhead").setup({
      -- Configuration options (see below)
    })
  end,
}
```

### Manual Installation

```lua
-- Using lazy.nvim
{
  "nvimts/csvhead.nvim",
  config = function()
    require("csvhead").setup()
  end,
}

-- Using packer.nvim
use {
  "nvimts/csvhead.nvim",
  config = function()
    require("csvhead").setup()
  end,
}
```

## Usage

### Commands

- `:CSVHead` or `:CSVHead toggle` - Toggle CSV header window
- `:CSVHead enable` - Enable CSV header window  
- `:CSVHead disable` - Disable CSV header window
- `:CH` - Quick toggle alias

### How it works

1. Run `:CSVHead` to activate the plugin
2. The window splits horizontally with a header window on top
3. When you open a CSV file, the header (first line) is displayed in the top window
4. When you switch to non-CSV files, the header window is automatically hidden
5. The header window automatically updates when you switch between different CSV files

## Configuration

Default configuration:

```lua
require("csvhead").setup({
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
  }
})
```

## API

The plugin exposes the following functions:

```lua
local csvhead = require("csvhead")

-- Enable CSV header window
csvhead.enable()

-- Disable CSV header window  
csvhead.disable()

-- Toggle CSV header window
csvhead.toggle()

-- Check if CSV header is active
local is_active = csvhead.is_active()
```

## Key Bindings

You can add key bindings in your configuration:

```lua
-- Example key bindings
vim.keymap.set("n", "<leader>ch", function()
  require("csvhead").toggle()
end, { desc = "Toggle CSV Header" })
```

## Requirements

- Neovim >= 0.7.0
- No external dependencies

## License

MIT License
