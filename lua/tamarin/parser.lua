-- Tamarin TreeSitter Parser Loader
-- Handles loading and registering the TreeSitter parser for Tamarin/Spthy files
-- With proper support for external scanners

local M = {}

-- Debug flag - set to true for detailed logging
local DEBUG = true

-- Helper function for logging
local function log(message, level)
  level = level or vim.log.levels.INFO
  if DEBUG then
    vim.notify("[tamarin.parser] " .. message, level)
  end
end

-- Safely call a function with pcall and return a boolean result
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  return ok and result ~= nil
end

-- Check if the TreeSitter API is available
function M.has_treesitter()
  return vim.treesitter ~= nil and vim.treesitter.language ~= nil
end

-- Find the parser file
function M.find_parser()
  local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  if vim.fn.filereadable(parser_path) == 1 then
    log("Found parser at " .. parser_path)
    return parser_path
  end
  
  local runtime_parsers = vim.api.nvim_get_runtime_file('parser/spthy/spthy.so', false)
  if #runtime_parsers > 0 then
    log("Found parser at " .. runtime_parsers[1])
    return runtime_parsers[1]
  end
  
  log("Parser file not found", vim.log.levels.WARN)
  return nil
end

-- Check if external scanner functions are defined in the parser
function M.check_external_scanner()
  local parser_path = M.find_parser()
  if not parser_path then
    return false
  end
  
  if vim.fn.executable('nm') == 1 then
    local handle = io.popen("nm -gU " .. vim.fn.shellescape(parser_path) .. " | grep external_scanner")
    if handle then
      local result = handle:read("*a")
      handle:close()
      
      if result:match("_tree_sitter_spthy_external_scanner_create") then
        log("External scanner functions found in parser")
        return true
      end
    end
  end
  
  log("No external scanner functions found in parser", vim.log.levels.WARN)
  return false
end

-- Register the parser with TreeSitter
function M.register_parser()
  if not M.has_treesitter() then
    log("TreeSitter not available", vim.log.levels.WARN)
    return false
  end
  
  local parser_path = M.find_parser()
  if not parser_path then
    return false
  end
  
  -- Register language to filetype mapping
  local register_ok = safe_call(vim.treesitter.language.register, 'spthy', 'tamarin')
  if not register_ok then
    log("Failed to register language", vim.log.levels.WARN)
    return false
  end
  
  -- Add parser from path (Neovim 0.9+)
  if vim.treesitter.language.add then
    local add_ok = safe_call(vim.treesitter.language.add, 'spthy', { path = parser_path })
    if not add_ok then
      log("Failed to add parser", vim.log.levels.WARN)
      return false
    end
  end
  
  -- Check if the parser has external scanner functions
  local has_scanner = M.check_external_scanner()
  if has_scanner then
    log("Parser with external scanner registered successfully")
  else
    log("Parser registered successfully (no external scanner)")
  end
  
  return true
end

-- Clean up inconsistent directory structure
function M.cleanup_directories()
  local tamarin_parser = vim.fn.stdpath('config') .. '/parser/tamarin/tamarin.so'
  local backup_dir = vim.fn.stdpath('config') .. '/backup/parser'
  
  -- Create backup directory if it doesn't exist
  if vim.fn.isdirectory(backup_dir) == 0 then
    vim.fn.mkdir(backup_dir, 'p')
  end
  
  -- Move redundant parser to backup if it exists
  if vim.fn.filereadable(tamarin_parser) == 1 then
    local cmd = "mv " .. vim.fn.shellescape(tamarin_parser) .. " " .. vim.fn.shellescape(backup_dir) .. "/"
    local handle = io.popen(cmd)
    if handle then
      handle:close()
      log("Moved redundant parser to backup directory")
    end
  end
  
  -- Ensure query directory exists
  local query_dir = vim.fn.stdpath('config') .. '/queries/spthy'
  if vim.fn.isdirectory(query_dir) == 0 then
    vim.fn.mkdir(query_dir, 'p')
  end
  
  return true
end

-- Set up filetype detection
function M.setup_filetype_detection()
  vim.filetype.add({
    extension = {
      spthy = "tamarin",
      sapic = "tamarin"
    }
  })
  
  log("Filetype detection set up for .spthy and .sapic files")
  return true
end

-- Complete setup function
function M.setup()
  -- Clean up directories first
  M.cleanup_directories()
  
  -- Register parser
  local parser_ok = M.register_parser()
  if not parser_ok then
    log("Failed to register parser, using fallback syntax highlighting", vim.log.levels.WARN)
    return false
  end
  
  -- Set up filetype detection
  M.setup_filetype_detection()
  
  log("Tamarin parser setup complete")
  return true
end

return M 