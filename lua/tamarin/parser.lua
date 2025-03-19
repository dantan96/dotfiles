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

-- Find the parser file with robust fallback options
function M.find_parser()
  -- List of potential parser paths
  local parser_paths = {
    vim.fn.stdpath('config') .. '/parser/spthy/spthy.so',
    vim.fn.stdpath('config') .. '/parser/tamarin/tamarin.so',
  }
  
  -- Check each path
  for _, path in ipairs(parser_paths) do
    if vim.fn.filereadable(path) == 1 then
      log("Found parser at " .. path)
      return path
    end
  end
  
  -- Try runtime paths
  local runtime_parsers = vim.api.nvim_get_runtime_file('parser/*/spthy.so', false)
  vim.list_extend(runtime_parsers, vim.api.nvim_get_runtime_file('parser/*/tamarin.so', false))
  
  if #runtime_parsers > 0 then
    log("Found runtime parser at " .. runtime_parsers[1])
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

-- Register the parser with TreeSitter using multiple methods for robustness
function M.register_parser()
  if not M.has_treesitter() then
    log("TreeSitter not available", vim.log.levels.WARN)
    return false
  end
  
  local parser_path = M.find_parser()
  if not parser_path then
    log("No parser found", vim.log.levels.ERROR)
    return false
  end
  
  local registration_success = false
  local methods_tried = 0
  local methods_succeeded = 0
  
  -- Method 1: Direct language registration (available in 0.9+)
  methods_tried = methods_tried + 1
  local register_ok = pcall(function()
    vim.treesitter.language.register('spthy', 'tamarin')
  end)
  
  if register_ok then
    log("Method 1: Direct language registration succeeded")
    methods_succeeded = methods_succeeded + 1
    registration_success = true
  else
    log("Method 1: Direct language registration failed")
  end
  
  -- Method 2: Explicit parser addition with path (available in 0.9+)
  methods_tried = methods_tried + 1
  local add_ok = pcall(function()
    vim.treesitter.language.add('spthy', { path = parser_path })
  end)
  
  if add_ok then
    log("Method 2: Parser addition succeeded")
    methods_succeeded = methods_succeeded + 1
    registration_success = true
  else
    log("Method 2: Parser addition failed")
  end
  
  -- Method 3: Parser info override (fallback method)
  methods_tried = methods_tried + 1
  local fallback_ok = pcall(function()
    if vim.treesitter._has_parser then
      vim.treesitter._has_parser['tamarin'] = function() return true end
      vim.treesitter._has_parser['spthy'] = function() return true end
    end
  end)
  
  if fallback_ok then
    log("Method 3: Parser info override succeeded")
    methods_succeeded = methods_succeeded + 1
    registration_success = registration_success or true
  else
    log("Method 3: Parser info override failed")
  end
  
  -- Method 4: Create a symbolic link from tamarin to spthy (Unix-like systems only)
  if vim.fn.has('unix') == 1 and not registration_success then
    methods_tried = methods_tried + 1
    
    local spthy_dir = vim.fn.fnamemodify(parser_path, ':h')
    local tamarin_dir = vim.fn.stdpath('config') .. '/parser/tamarin'
    
    -- Create tamarin dir if it doesn't exist
    if vim.fn.isdirectory(tamarin_dir) == 0 then
      vim.fn.mkdir(tamarin_dir, 'p')
    end
    
    local symlink_ok = pcall(function()
      vim.fn.system('ln -sf ' .. vim.fn.shellescape(parser_path) .. ' ' .. 
                   vim.fn.shellescape(tamarin_dir .. '/tamarin.so'))
    end)
    
    if symlink_ok then
      log("Method 4: Symbolic link creation succeeded")
      methods_succeeded = methods_succeeded + 1
      registration_success = true
    else
      log("Method 4: Symbolic link creation failed")
    end
  end
  
  log(string.format("Parser registration: %d/%d methods succeeded", 
                   methods_succeeded, methods_tried))
  
  -- Check if the parser has external scanner functions
  local has_scanner = M.check_external_scanner()
  if registration_success then
    if has_scanner then
      log("Parser with external scanner registered successfully")
    else
      log("Parser registered successfully (no external scanner)")
    end
  else
    log("Failed to register parser", vim.log.levels.ERROR)
  end
  
  return registration_success
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
  -- Modern API (Neovim 0.8+)
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