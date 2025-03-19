-- Tamarin TreeSitter Highlighter
-- Handles setting up TreeSitter highlighting for Tamarin buffers
-- With proper garbage collection prevention

local M = {}

-- Debug flag - set to true for detailed logging
local DEBUG = true

-- Helper function for logging
local function log(message, level)
  level = level or vim.log.levels.INFO
  if DEBUG then
    vim.notify("[tamarin.highlighter] " .. message, level)
  end
end

-- Safely call a function with proper error handling
local function safe_call(fn, ...)
  local status, result
  status, result = pcall(fn, ...)
  if not status then
    log("Error: " .. tostring(result), vim.log.levels.ERROR)
    return false, nil
  end
  return true, result
end

-- Global storage for highlighters to prevent GC
-- This avoids buffer-local variable type conversion issues
if not _G._tamarin_highlighters then
  _G._tamarin_highlighters = {}
end

-- Set up TreeSitter highlighting for a buffer
function M.setup_highlighting(bufnr)
  bufnr = bufnr or 0
  
  -- Skip if not a Tamarin buffer
  if vim.bo[bufnr].filetype ~= "tamarin" then
    log("Not a Tamarin buffer, skipping highlighting setup", vim.log.levels.DEBUG)
    return false
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
  
  -- Safely create highlighter with a wrapped function
  local highlighter
  local highlighter_ok = pcall(function()
    highlighter = vim.treesitter.highlighter.new(parser)
  end)
  
  if not highlighter_ok or not highlighter then
    log("Failed to create highlighter", vim.log.levels.WARN)
    return false
  end
  
  -- Store in global table to prevent garbage collection
  -- This avoids the type conversion issues with buffer-local variables
  _G._tamarin_highlighters[bufnr] = highlighter
  
  -- Try to store in buffer-local variable as well, but don't worry if it fails
  pcall(function()
    -- Store only a reference to the buffer number to avoid type conversion issues
    vim.b[bufnr].tamarin_ts_highlighter_ref = bufnr
  end)
  
  -- Add autocommand to clean up highlighter when buffer is closed
  pcall(function()
    vim.cmd(string.format([[
      augroup TamarinHighlighter%d
        autocmd!
        autocmd BufDelete <buffer=%d> lua if _G._tamarin_highlighters then _G._tamarin_highlighters[%d] = nil end
      augroup END
    ]], bufnr, bufnr, bufnr))
  end)
  
  log("Highlighting set up for buffer " .. bufnr)
  return true
end

-- Set up fallback syntax highlighting
function M.setup_fallback(bufnr)
  bufnr = bufnr or 0
  
  -- Skip if not a Tamarin buffer
  if vim.bo[bufnr].filetype ~= "tamarin" then
    log("Not a Tamarin buffer, skipping fallback setup", vim.log.levels.DEBUG)
    return false
  end
  
  -- Enable regular syntax highlighting
  pcall(function()
    vim.cmd("syntax enable")
  end)
  
  log("Fallback syntax highlighting enabled", vim.log.levels.INFO)
  return true
end

-- Ensure some form of highlighting is set up
function M.ensure_highlighting(bufnr)
  -- Try TreeSitter first
  local ts_ok = M.setup_highlighting(bufnr)
  
  -- Fall back to regular syntax if TreeSitter fails
  if not ts_ok then
    log("TreeSitter highlighting failed, falling back to regular syntax", vim.log.levels.WARN)
    return M.setup_fallback(bufnr)
  end
  
  return ts_ok
end

-- Test highlighting with different query files
function M.test_query_files(bufnr)
  bufnr = bufnr or 0
  local results = {}
  
  -- Skip if not a Tamarin buffer
  if vim.bo[bufnr].filetype ~= "tamarin" then
    log("Not a Tamarin buffer, skipping test", vim.log.levels.WARN)
    return false
  end
  
  -- Get list of query files
  local query_dir = vim.fn.stdpath('config') .. '/queries/spthy'
  local query_files = vim.fn.glob(query_dir .. '/highlights.scm.*', false, true)
  table.insert(query_files, query_dir .. '/highlights.scm')
  
  -- Original query file
  local original_query = vim.fn.readfile(query_dir .. '/highlights.scm')
  
  -- Test each query file
  for _, path in ipairs(query_files) do
    local name = vim.fn.fnamemodify(path, ':t')
    log("Testing query file: " .. name)
    
    -- Read the query file
    local content = vim.fn.readfile(path)
    
    -- Write to the active query file
    vim.fn.writefile(content, query_dir .. '/highlights.scm')
    
    -- Try to set up highlighting
    local success = M.setup_highlighting(bufnr)
    
    -- Check if highlighting is active
    local is_active = false
    pcall(function()
      is_active = vim.treesitter.highlighter and 
                 vim.treesitter.highlighter.active and 
                 vim.treesitter.highlighter.active[bufnr] ~= nil
    end)
    
    results[name] = {
      success = success,
      active = is_active
    }
    
    log("  Setup: " .. (success and "SUCCESS" or "FAILED"))
    log("  Active: " .. (is_active and "YES" or "NO"))
  end
  
  -- Restore original query file
  vim.fn.writefile(original_query, query_dir .. '/highlights.scm')
  
  -- Set up highlighting again with the original file
  M.setup_highlighting(bufnr)
  
  return results
end

-- Check if buffer has an active highlighter
function M.has_active_highlighter(bufnr)
  bufnr = bufnr or 0
  
  -- Check global registry first (our new approach)
  if _G._tamarin_highlighters and _G._tamarin_highlighters[bufnr] then
    return true
  end
  
  -- Check traditional methods as well (for backwards compatibility)
  if vim.b[bufnr].tamarin_ts_highlighter then
    return true
  end
  
  -- Check if TreeSitter's internal highlighter tracking shows it as active
  if vim.treesitter and vim.treesitter.highlighter and vim.treesitter.highlighter.active then
    return vim.treesitter.highlighter.active[bufnr] ~= nil
  end
  
  return false
end

-- Test garbage collection prevention
function M.test_gc(bufnr)
  bufnr = bufnr or 0
  
  log("Testing garbage collection prevention...")
  
  -- First, ensure we have a highlighter
  local has_highlighter_before = M.has_active_highlighter(bufnr)
  
  -- Force a garbage collection
  collectgarbage("collect")
  
  -- Check if highlighter is still active
  local has_highlighter_after = M.has_active_highlighter(bufnr)
  
  -- Report results
  log("Before GC: " .. tostring(has_highlighter_before))
  log("After GC: " .. tostring(has_highlighter_after))
  log("Registry entry: " .. tostring(_G._tamarin_highlighters and _G._tamarin_highlighters[bufnr] ~= nil))
  
  return has_highlighter_before and has_highlighter_after
end

-- Clean up highlighter for buffer
function M.cleanup_highlighting(bufnr)
  bufnr = bufnr or 0
  
  -- Remove from global registry
  if _G._tamarin_highlighters and _G._tamarin_highlighters[bufnr] then
    _G._tamarin_highlighters[bufnr] = nil
  end
  
  -- Clear buffer variable
  pcall(function()
    vim.b[bufnr].tamarin_ts_highlighter = nil
    vim.b[bufnr].tamarin_ts_highlighter_ref = nil
  end)
  
  log("Highlighting cleaned up for buffer " .. bufnr, vim.log.levels.DEBUG)
  return true
end

-- Clean up all highlighters
function M.cleanup_all()
  if _G._tamarin_highlighters then
    for bufnr, _ in pairs(_G._tamarin_highlighters) do
      _G._tamarin_highlighters[bufnr] = nil
    end
  end
  
  -- Reset global table
  _G._tamarin_highlighters = {}
  
  log("All highlighters cleaned up")
  return true
end

return M 