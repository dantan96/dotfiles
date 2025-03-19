-- Tamarin TreeSitter - Simplified Parser Loader
-- Based on the simplified approach from simplifying_the_config.md

local M = {}

-- Debug flag - set to true for detailed logging
local DEBUG = false

-- Helper function to log messages when debug is enabled
local function log(msg, level)
  if DEBUG then
    local log_level = level or vim.log.levels.INFO
    vim.notify("[tamarin-simplified] " .. msg, log_level)
  end
end

-- Function to set up Tamarin TreeSitter integration
function M.setup()
  -- Check for required functionality
  if not vim.treesitter or not vim.treesitter.language or not vim.treesitter.language.register then
    log("TreeSitter language registration not available in this Neovim version", vim.log.levels.WARN)
    return false
  end
  
  -- Register the language for the filetype
  local ok, err = pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
  if not ok then
    log("Failed to register Tamarin TreeSitter language: " .. tostring(err), vim.log.levels.WARN)
    return false
  end
  
  log("Successfully registered spthy language for tamarin filetype")
  
  -- Set up filetype detection
  vim.filetype.add({
    extension = {
      spthy = "tamarin",
      sapic = "tamarin"
    }
  })
  
  log("Added filetype detection for .spthy and .sapic files")
  
  return true
end

-- Function to ensure highlighting for a buffer
function M.ensure_highlighting(bufnr)
  bufnr = bufnr or 0
  
  -- Skip if not a Tamarin buffer
  if vim.bo[bufnr].filetype ~= "tamarin" then
    return false
  end
  
  -- Register language if needed
  if vim.treesitter.language and vim.treesitter.language.register then
    pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
  end
  
  -- Check if TreeSitter is available
  if not vim.treesitter or not vim.treesitter.highlighter then
    log("TreeSitter highlighter not available", vim.log.levels.WARN)
    return false
  end
  
  -- Get parser
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_ok or not parser then
    log("Failed to get parser", vim.log.levels.WARN)
    return false
  end
  
  -- Create highlighter
  local highlighter_ok, highlighter = pcall(vim.treesitter.highlighter.new, parser)
  if not highlighter_ok or not highlighter then
    log("Failed to create highlighter", vim.log.levels.WARN)
    return false
  end
  
  -- Store in buffer-local variable to prevent garbage collection
  vim.b[bufnr].tamarin_ts_highlighter = highlighter
  
  log("Highlighting set up for buffer " .. bufnr)
  return true
end

-- Setup function called from autocommand
function M.setup_autocommand()
  -- Register language
  M.setup()
  
  -- Set up autocommand for buffer highlighting
  vim.cmd([[
    augroup TamarinTreeSitter
      autocmd!
      autocmd FileType tamarin lua require('tamarin.simplified_loader').ensure_highlighting(0)
    augroup END
  ]])
  
  return true
end

return M 