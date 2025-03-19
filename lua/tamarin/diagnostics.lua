-- Tamarin TreeSitter - Diagnostics Module
-- Provides utilities for diagnosing TreeSitter issues

local M = {}

-- Maximum number of diagnostic entries to print
local MAX_DIAG_ENTRIES = 20

-- Check if TreeSitter is available
function M.check_treesitter_available()
  local result = {
    treesitter = vim.treesitter ~= nil,
    language_module = vim.treesitter and vim.treesitter.language ~= nil,
    highlighter = vim.treesitter and vim.treesitter.highlighter ~= nil,
    query = vim.treesitter and vim.treesitter.query ~= nil
  }
  
  print("TreeSitter Availability:")
  vim.pretty_print(result)
  
  return result
end

-- Check parser status
function M.check_parser_status()
  local result = {
    spthy_parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so',
    tamarin_parser_path = vim.fn.stdpath('config') .. '/parser/tamarin/tamarin.so',
    spthy_parser_exists = vim.fn.filereadable(vim.fn.stdpath('config') .. '/parser/spthy/spthy.so') == 1,
    tamarin_parser_exists = vim.fn.filereadable(vim.fn.stdpath('config') .. '/parser/tamarin/tamarin.so') == 1
  }
  
  -- Try to get parser for current buffer
  if vim.treesitter and vim.treesitter.get_parser then
    local parser_ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
    result.parser_loaded = parser_ok and parser ~= nil
    
    if parser_ok and parser then
      result.parser_language = parser:lang()
    end
  end
  
  print("Parser Status:")
  vim.pretty_print(result)
  
  return result
end

-- Check query file status
function M.check_query_files()
  local result = {
    spthy_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm',
    tamarin_query_path = vim.fn.stdpath('config') .. '/queries/tamarin/highlights.scm',
    spthy_query_exists = vim.fn.filereadable(vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm') == 1,
    tamarin_query_exists = vim.fn.filereadable(vim.fn.stdpath('config') .. '/queries/tamarin/highlights.scm') == 1
  }
  
  -- Try to get query for spthy language
  if vim.treesitter and vim.treesitter.query and vim.treesitter.query.get then
    local query_ok, query = pcall(vim.treesitter.query.get, 'spthy', 'highlights')
    result.query_loaded = query_ok and query ~= nil
  end
  
  print("Query Files:")
  vim.pretty_print(result)
  
  return result
end

-- Check highlighting status for current buffer
function M.check_highlighting()
  local result = {
    buffer = vim.api.nvim_get_current_buf(),
    filetype = vim.bo.filetype,
    tamarin_file = vim.bo.filetype == 'tamarin',
    has_highlighter = vim.b[0].tamarin_ts_highlighter ~= nil
  }
  
  -- Check if TreeSitter highlighting is active for the buffer
  if vim.treesitter and vim.treesitter.highlighter and vim.treesitter.highlighter.active then
    result.ts_highlighting_active = vim.treesitter.highlighter.active[0] ~= nil
  end
  
  print("Highlighting Status:")
  vim.pretty_print(result)
  
  return result
end

-- Run a complete diagnosis with limited output
function M.run_diagnosis()
  print("Running Tamarin TreeSitter Diagnostics...")
  print("----------------------------------------")
  
  -- Capture and limit original print function to prevent infinite output
  local original_print = print
  local diag_count = 0
  
  -- Override print to limit output
  _G.print = function(...)
    if diag_count < MAX_DIAG_ENTRIES then
      original_print(...)
      diag_count = diag_count + 1
    elseif diag_count == MAX_DIAG_ENTRIES then
      original_print("... Output truncated for brevity ...")
      diag_count = diag_count + 1
    end
  end
  
  -- Run diagnostics with limited output
  M.check_treesitter_available()
  print("----------------------------------------")
  
  M.check_parser_status()
  print("----------------------------------------")
  
  M.check_query_files()
  print("----------------------------------------")
  
  M.check_highlighting()
  print("----------------------------------------")
  
  print("Diagnosis complete.")
  
  -- Restore original print function
  _G.print = original_print
  
  return true
end

-- Check exported symbols in parser files
function M.check_parser_symbols()
  local spthy_parser = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  local tamarin_parser = vim.fn.stdpath('config') .. '/parser/tamarin/tamarin.so'
  
  print("Checking Parser Symbols:")
  print("- Spthy parser exists: " .. tostring(vim.fn.filereadable(spthy_parser) == 1))
  print("- Tamarin parser exists: " .. tostring(vim.fn.filereadable(tamarin_parser) == 1))
  
  if vim.fn.executable('nm') ~= 1 then
    print("The 'nm' utility is not available. Cannot check symbols.")
    return false
  end
  
  -- Check spthy parser symbols
  if vim.fn.filereadable(spthy_parser) == 1 then
    local handle = io.popen("nm -gU " .. vim.fn.shellescape(spthy_parser) .. " | grep tree_sitter")
    if handle then
      local result = handle:read("*a")
      handle:close()
      
      print("\nSpthy parser symbols:")
      print(result:sub(1, 500)) -- Limit output
      
      if result:match("_tree_sitter_spthy") then
        print("✓ Symbol _tree_sitter_spthy found in spthy parser")
      else
        print("✗ Symbol _tree_sitter_spthy NOT found in spthy parser")
      end
      
      if result:match("_tree_sitter_spthy_external_scanner_") then
        print("✓ External scanner functions found in spthy parser")
      else
        print("✗ No external scanner functions found in spthy parser")
      end
    end
  end
  
  -- Check tamarin parser symbols if it exists
  if vim.fn.filereadable(tamarin_parser) == 1 then
    local handle = io.popen("nm -gU " .. vim.fn.shellescape(tamarin_parser) .. " | grep tree_sitter")
    if handle then
      local result = handle:read("*a")
      handle:close()
      
      print("\nTamarin parser symbols:")
      print(result:sub(1, 500)) -- Limit output
      
      if result:match("_tree_sitter_spthy") and not result:match("tree_sitter_tamarin") then
        print("✓ Symbol _tree_sitter_spthy found in tamarin parser (suggests a name mismatch)")
      end
    end
  end
  
  return true
end

return M