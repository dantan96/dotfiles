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
    spthy = "tamarin",
    sapic = "tamarin"
  },
})
log("Registered Tamarin filetype")

-- Initialize Tamarin syntax highlighting module
pcall(function()
  log("Loading Tamarin highlighting module")
  require('config.tamarin-highlights').setup()
  log("Tamarin highlighting module loaded")
end)

-- Load Tamarin TreeSitter integration
pcall(function() 
  log("Loading Tamarin TreeSitter parser symlink")
  require('config.spthy_parser_init').setup()
  log("Loading Tamarin TreeSitter parser mapping")
  require('config.treesitter_parser_map').setup()
  log("Tamarin TreeSitter integration loaded")
end)

-- Set the flag that Tamarin is initialized with TreeSitter support
vim.g.tamarin_treesitter_initialized = true
log("Set tamarin_treesitter_initialized flag")

-- Remove auto-session plugin if it's causing issues
pcall(function()
  log("Disabling auto-session plugin")
  vim.g.auto_session_enabled = false
  -- Attempt to reset the plugin if it exists
  if package.loaded["auto-session"] then
    package.loaded["auto-session"] = nil
    log("Unloaded auto-session plugin")
  end
end)

-- Add command to clear session cache
vim.api.nvim_create_user_command("ClearSession", function()
  local session_dir = vim.fn.stdpath("data") .. "/sessions/"
  if vim.fn.isdirectory(session_dir) == 1 then
    vim.fn.delete(session_dir, "rf")
    vim.fn.mkdir(session_dir, "p")
    vim.notify("Session cache cleared", vim.log.levels.INFO)
    log("Session cache cleared")
  end
end, {})

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
