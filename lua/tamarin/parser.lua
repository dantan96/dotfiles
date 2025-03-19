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
  if not ok then
    log("Error calling function: " .. tostring(result), vim.log.levels.ERROR)
    return false, nil
  end
  return true, result
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
  
  -- Check neovim version for API compatibility
  local nvim_version = vim.version()
  local nvim_0_9_plus = (nvim_version and nvim_version.major >= 0 and nvim_version.minor >= 9)
  
  -- Try different registration methods based on Neovim version
  local registration_ok = false
  
  -- Method 1: Simple language registration
  local ok1, _ = safe_call(vim.treesitter.language.register, 'spthy', 'tamarin')
  log("Basic language registration result: " .. tostring(ok1))
  
  -- Method 2: For Neovim 0.9+, use explicit language addition with path
  if nvim_0_9_plus and vim.treesitter.language.add then
    local ok2, _ = safe_call(vim.treesitter.language.add, 'spthy', { path = parser_path })
    log("Advanced language add result: " .. tostring(ok2))
    registration_ok = ok1 or ok2
  else
    registration_ok = ok1
  end
  
  -- Method 3: Try setting parser_info as a fallback
  if not registration_ok then
    log("Attempting fallback registration method", vim.log.levels.INFO)
    -- Check if parser_info exists in treesitter
    if vim.treesitter._has_parser then
      local ok3 = pcall(function()
        vim.treesitter._has_parser['tamarin'] = function() return true end
        vim.treesitter._has_parser['spthy'] = function() return true end
      end)
      log("Fallback registration result: " .. tostring(ok3))
      registration_ok = ok3
    end
  end
  
  -- Check if the parser has external scanner functions
  local has_scanner = M.check_external_scanner()
  if registration_ok then
    if has_scanner then
      log("Parser with external scanner registered successfully")
    else
      log("Parser registered successfully (no external scanner)")
    end
  else
    log("Failed to register parser", vim.log.levels.ERROR)
  end
  
  return registration_ok
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
  if vim.filetype and vim.filetype.add then
    vim.filetype.add({
      extension = {
        spthy = "tamarin",
        sapic = "tamarin"
      }
    })
  else
    -- Fallback for older Neovim versions
    vim.cmd([[
      augroup TamarinFiletype
        autocmd!
        autocmd BufRead,BufNewFile *.spthy set filetype=tamarin
        autocmd BufRead,BufNewFile *.sapic set filetype=tamarin
      augroup END
    ]])
  end
  
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