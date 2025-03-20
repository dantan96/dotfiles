-- Enable 24-bit RGB colors in the terminal
vim.opt.termguicolors = true

-- Define a debug log file for Tamarin
local TAMARIN_LOG_FILE = vim.fn.stdpath("cache") .. "/tamarin_init.log"

-- Initialize log file
local function init_log_file()
  local f = io.open(TAMARIN_LOG_FILE, "w")
  if f then
    f:write("Tamarin Initialization Log\n")
    f:write("==========================\n\n")
    f:write("Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    f:close()
    return true
  end
  return false
end

-- Log message to file
local function log(msg)
  local f = io.open(TAMARIN_LOG_FILE, "a")
  if f then
    f:write(os.date("%H:%M:%S") .. " - " .. msg .. "\n")
    f:close()
  end
end

-- Initialize log
init_log_file()
log("Starting Neovim initialization")

-- Set up filetype detection for Tamarin files - do this as early as possible
vim.filetype.add({
  extension = {
    spthy = "spthy",
    sapic = "spthy"
  },
})
log("Registered Tamarin filetype")

-- Load the simplified Tamarin setup with proper fallback
pcall(function()
  log("Loading Tamarin setup module")
  local tamarin_setup = require('tamarin_setup')
  tamarin_setup.setup()
  log("Tamarin setup complete")
end)

-- Load lazy.nvim plugin manager
log("Loading plugin manager")
require("config.lazy")
log("Plugin manager loaded")

-- General keymaps
vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", "<cmd>:.lua<CR>")
vim.keymap.set("v", "<space>x", "<cmd>:lua<CR>")

-- Basic editor settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.wrap = false

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Oil.nvim keymaps
vim.keymap.set("n", "<leader>-", "<cmd>Oil<CR>")
vim.keymap.set("n", "<leader>vim", "<cmd>Oil ~/.config/nvim/<CR>")

-- Toggle diagnostics
local isLspDiagnosticsVisible = true
vim.keymap.set("n", "<leader>lx", function()
  isLspDiagnosticsVisible = not isLspDiagnosticsVisible
  vim.diagnostic.config({
    virtual_text = isLspDiagnosticsVisible,
    underline = isLspDiagnosticsVisible
  })
end)

-- Add debug commands for Tamarin
vim.api.nvim_create_user_command("TamarinDebug", function()
  log("Running Tamarin debug command")
  vim.notify("Analyzing Tamarin highlighting, please wait...", vim.log.levels.INFO)
  pcall(function() require("highlight_debugger").run() end)
end, {})

log("Initialization complete")
