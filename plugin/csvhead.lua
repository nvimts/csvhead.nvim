-- This file is optional since we register commands in the setup function
-- But it can be useful for ensuring the plugin is loaded
if vim.g.loaded_csvhead then
  return
end
vim.g.loaded_csvhead = true

-- Auto-setup with default config if user hasn't called setup manually
if not vim.g.csvhead_setup_called then
  vim.schedule(function()
    if not vim.g.csvhead_setup_called then
      require("csvhead").setup()
      vim.g.csvhead_setup_called = true
    end
  end)
end
