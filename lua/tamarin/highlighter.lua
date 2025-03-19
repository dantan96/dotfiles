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

-- Safely call a function with pcall
local function safe_call(fn, ...)
  local status, result = pcall(fn, ...)
  return status, result
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
  local parser_ok, parser = safe_call(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_ok or not parser then
    log("Failed to get parser: " .. tostring(parser), vim.log.levels.WARN)
    return false
  end
  
  -- Create highlighter
  local highlighter_ok, highlighter = safe_call(vim.treesitter.highlighter.new, parser)
  if not highlighter_ok or not highlighter then
    log("Failed to create highlighter: " .. tostring(highlighter), vim.log.levels.WARN)
    return false
  end
  
  -- Store in buffer-local variable to prevent garbage collection
  vim.b[bufnr].tamarin_ts_highlighter = highlighter
  
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
  local cmd = string.format("syntax enable", bufnr)
  vim.cmd(cmd)
  
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
    local is_active = vim.treesitter.highlighter and 
                     vim.treesitter.highlighter.active and 
                     vim.treesitter.highlighter.active[bufnr] ~= nil
    
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

-- Test garbage collection
function M.test_gc(bufnr)
  bufnr = bufnr or 0
  
  log("Testing garbage collection behavior")
  
  -- Test with GC prevention
  log("Setting up highlighter with GC prevention")
  local with_gc_ok = M.setup_highlighting(bufnr)
  
  -- Force garbage collection
  collectgarbage("collect")
  
  -- Check if highlighting is still active
  local with_gc_active = vim.treesitter.highlighter and 
                        vim.treesitter.highlighter.active and 
                        vim.treesitter.highlighter.active[bufnr] ~= nil
  
  log("  Setup: " .. (with_gc_ok and "SUCCESS" or "FAILED"))
  log("  Active after GC: " .. (with_gc_active and "YES" or "NO"))
  
  return {
    setup_ok = with_gc_ok,
    active_after_gc = with_gc_active
  }
end

return M 