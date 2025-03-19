-- Tamarin TreeSitter Integration - Simplified Main Module
-- Main entry point for the simplified Tamarin TreeSitter integration

local M = {}

-- Setup function - initializes the Tamarin TreeSitter integration
function M.setup()
  -- Load the simplified loader
  local loader = require('tamarin.simplified_loader')
  local success = loader.setup()
  
  -- Set up autocommand for buffer highlighting
  if success then
    vim.cmd([[
      augroup TamarinTreeSitter
        autocmd!
        autocmd FileType tamarin lua require('tamarin.simplified_loader').ensure_highlighting(0)
      augroup END
    ]])
  end
  
  return success
end

-- Ensure highlighting for the current buffer
function M.ensure_highlighting(bufnr)
  local loader = require('tamarin.simplified_loader')
  return loader.ensure_highlighting(bufnr or 0)
end

-- Run diagnostics to troubleshoot issues
function M.diagnose()
  local diagnostics = require('tamarin.diagnostics')
  return diagnostics.run_diagnosis()
end

-- Check parser symbols (useful for debugging)
function M.check_symbols()
  local diagnostics = require('tamarin.diagnostics')
  return diagnostics.check_parser_symbols()
end

return M 