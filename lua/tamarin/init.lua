-- Tamarin initialization module
-- Main module for setting up Tamarin syntax highlighting with TreeSitter

local M = {}

-- Helper function to log messages
local function log(msg)
  if vim.fn.isdirectory('/tmp/tamarin-debug') == 0 then
    vim.fn.mkdir('/tmp/tamarin-debug', 'p')
  end
  
  local log_file = io.open("/tmp/tamarin-debug/tamarin_init.log", "a")
  if log_file then
    log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
    log_file:close()
  end
end

-- Setup function - called from init.lua
function M.setup()
  log("Starting Tamarin setup")
  
  -- Register the language for TreeSitter
  if vim.treesitter.language and vim.treesitter.language.register then
    pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
    log("Registered spthy language for tamarin filetype")
  end
  
  -- Set up filetype detection
  vim.filetype.add({
    extension = {
      spthy = "tamarin"
    }
  })
  log("Added filetype detection for .spthy files")
  
  -- Set up TreeSitter integration for better highlighting
  local treesitter = require('tamarin.treesitter')
  treesitter.setup()
  log("Set up tamarin TreeSitter integration")
  
  return true
end

-- For compatibility with the old API
function M.ensure_treesitter_highlighting(bufnr)
  local treesitter = require('tamarin.treesitter')
  return treesitter.ensure_highlighting(bufnr)
end

return M