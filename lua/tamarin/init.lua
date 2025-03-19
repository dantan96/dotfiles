-- Tamarin TreeSitter Integration
-- Main module for Tamarin/Spthy TreeSitter integration

local M = {}

-- Debug flag - set to true for detailed logging
local DEBUG = true

-- Helper function for logging
local function log(message, level)
  level = level or vim.log.levels.INFO
  if DEBUG then
    vim.notify("[tamarin] " .. message, level)
  end
end

-- Initialize the module
function M.setup()
  log("Initializing Tamarin TreeSitter integration")
  
  -- Load parser module
  local parser = require('tamarin.parser')
  if not parser.has_treesitter() then
    log("TreeSitter not available, using fallback syntax highlighting", vim.log.levels.WARN)
    return false
  end
  
  -- Set up parser
  local parser_ok = parser.setup()
  if not parser_ok then
    log("Failed to set up parser, using fallback syntax highlighting", vim.log.levels.WARN)
    return false
  end
  
  -- Set up autocommands for buffer highlighting
  vim.cmd([[
    augroup TamarinTreeSitter
      autocmd!
      autocmd FileType tamarin lua require('tamarin.highlighter').ensure_highlighting(vim.api.nvim_get_current_buf())
    augroup END
  ]])
  
  log("Tamarin TreeSitter integration initialized successfully")
  return true
end

-- Ensure highlighting for current buffer
function M.ensure_highlighting(bufnr)
  local highlighter = require('tamarin.highlighter')
  return highlighter.ensure_highlighting(bufnr or 0)
end

-- Run diagnostics
function M.diagnose()
  local diagnostics = require('tamarin.diagnostics')
  return diagnostics.run_diagnosis()
end

-- Test query files
function M.test_query_files(bufnr)
  local highlighter = require('tamarin.highlighter')
  return highlighter.test_query_files(bufnr or 0)
end

-- Test garbage collection
function M.test_gc(bufnr)
  local highlighter = require('tamarin.highlighter')
  return highlighter.test_gc(bufnr or 0)
end

-- Clean up existing implementation
function M.cleanup()
  log("Cleaning up previous implementation")
  
  -- Clean up existing autocommands
  vim.cmd([[
    augroup TamarinTreeSitter
      autocmd!
    augroup END
  ]])
  
  -- Reset any global state
  rawset(_G, '_tamarin_setup_done', nil)
  
  return true
end

return M