# CSVUtil.nvim

A Neovim plugin that provides a persistent header window for CSV files, making it easier to work with large CSV files by keeping column headers visible at all times.

## Features

- **Persistent Header Window**: Automatically creates a top window showing the first row (headers) of CSV files
- **Horizontal Scroll Synchronization**: Both header and main windows scroll horizontally together for perfect column alignment
- **Auto-detection**: Automatically detects CSV files by extension and filetype
- **Smart Window Management**: Handles window splitting and management seamlessly
- **Configurable**: Customizable file extensions, window options, and behavior
- **Toggle Functionality**: Easy key binding to enable/disable the header window

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nvimts/csvutil.nvim",
  ft = { "csv" },
  keys = {
    {
      "<leader>ch",
      function()
        require("csvutil").toggle()
      end,
      desc = "Toggle CSV Util",
    },
  },
  config = function()
    require("csvutil").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "nvimts/csvutil.nvim",
  config = function()
    require("csvutil").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvimts/csvutil.nvim'
```

Then add to your init.lua:
```lua
require("csvutil").setup()
```

## Usage

### Commands

- `:CSVUtil` or `:CSVUtil toggle` - Toggle the CSV header window
- `:CSVUtil enable` - Enable the CSV header window
- `:CSVUtil disable` - Disable the CSV header window
- `:CH` - Quick toggle command (alias for `:CSVUtil toggle`)

### Basic Workflow

1. Open a CSV file in Neovim
2. Press `<leader>ch` to activate the header window
3. The screen will split horizontally with the top window showing the CSV headers
4. Navigate through your CSV file - the headers remain visible in the top window
5. Both windows will scroll horizontally together for easy column alignment
6. Press `<leader>ch` again to close the header window

## Configuration

The plugin comes with sensible defaults, but you can customize it:

```lua
require("csvutil").setup({
  -- Auto-detect CSV files by extension
  auto_detect_csv = true,
  
  -- File extensions to consider as CSV
  csv_extensions = { "csv", "tsv" },
  
  -- Filetype names to consider as CSV
  csv_filetypes = { "csv" },
  
  -- Height of the header window
  header_height = 1,
  
  -- Set laststatus to 3 when active (unified statusline)
  set_laststatus = true,
  
  -- Window options for the header window
  header_window_opts = {
    wrap = false,
    scrollbind = true,
    scrollopt = "hor",
  },
  
  -- Window options for the main window
  main_window_opts = {
    scrollbind = true,
    scrollopt = "hor",
  },
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `auto_detect_csv` | boolean | `true` | Automatically detect CSV files by extension |
| `csv_extensions` | table | `{"csv", "tsv"}` | File extensions to treat as CSV |
| `csv_filetypes` | table | `{"csv"}` | Neovim filetypes to treat as CSV |
| `header_height` | number | `1` | Height of the header window in lines |
| `set_laststatus` | boolean | `true` | Set laststatus to 3 for unified statusline |
| `header_window_opts` | table | See above | Window-local options for header window (includes scrollbind) |
| `main_window_opts` | table | See above | Window-local options for main window (includes scrollbind) |

## Key Bindings

The plugin includes a convenient key binding when using lazy.nvim:

- `<leader>ch` - Toggle CSV header window

You can also add additional custom key bindings:

```lua
-- Add to your init.lua
vim.keymap.set("n", "<leader>ce", ":CSVUtil enable<CR>", { desc = "Enable CSV header" })
vim.keymap.set("n", "<leader>cd", ":CSVUtil disable<CR>", { desc = "Disable CSV header" })
```

## How It Works

1. When enabled, the plugin splits the current window horizontally
2. The top window displays the first row of the CSV file (headers)
3. The bottom window is used for normal navigation and editing
4. Both windows are synchronized for horizontal scrolling, keeping column headers aligned with data
5. The header window automatically updates when switching between different CSV files
6. For non-CSV files, the header window is hidden automatically
7. Window management is handled automatically, including cleanup when windows are closed

## Automatic Behavior

- **File Detection**: Automatically detects CSV files based on extension (`.csv`, `.tsv`) and filetype
- **Window Management**: Handles window creation, positioning, and cleanup
- **Buffer Switching**: Updates header content when switching between different CSV files
- **Non-CSV Files**: Hides header window when switching to non-CSV files

## API

The plugin exposes a simple API:

```lua
local csvutil = require("csvutil")

-- Enable CSV header window
csvutil.enable()

-- Disable CSV header window
csvutil.disable()

-- Toggle CSV header window
csvutil.toggle()

-- Check if CSV header is active
local is_active = csvutil.is_active()
```

## Troubleshooting

### Header window doesn't appear
- Ensure the file has a CSV extension (`.csv`, `.tsv`) or the filetype is set to `csv`
- Check that the plugin is properly installed and configured
- Try manually running `:CSVUtil enable`

### Windows behave unexpectedly
- The plugin manages window state automatically
- Closing either the header or main window will disable the feature
- Use `:CSVUtil disable` to cleanly reset the state

### Performance with large files
- The header window only displays the first row, so performance impact is minimal
- The plugin doesn't load the entire file into memory

## Contributing

Contributions are welcome! Please feel free to:

1. Report bugs by opening an issue
2. Suggest new features
3. Submit pull requests

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the need for better CSV file navigation in Neovim
- Built using Neovim's powerful window management API
