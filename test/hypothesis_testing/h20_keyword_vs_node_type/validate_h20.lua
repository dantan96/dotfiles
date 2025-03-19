-- Simple script to validate original and fixed query files
-- Complete with proper exit

-- Paths
local original_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
local fixed_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm.h20'
local results_file = '/tmp/query_results.txt'

-- Initialize TreeSitter for 'spthy' language
local setup_ok = pcall(function()
  -- Register language if function exists
  if vim.treesitter.language and vim.treesitter.language.register then
    vim.treesitter.language.register('spthy', 'tamarin')
  end
  
  -- Add parser with explicit path (Neovim 0.9+)
  local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  if vim.treesitter.language and vim.treesitter.language.add and vim.fn.filereadable(parser_path) == 1 then
    vim.treesitter.language.add('spthy', { path = parser_path })
  end
end)

-- Function to validate a query file
local function validate_query(path)
  -- Read the query file
  local file = io.open(path, 'r')
  if not file then
    return {
      valid = false,
      error = "Could not open query file: " .. path
    }
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Try to parse the query
  local ok, result = pcall(vim.treesitter.query.parse, 'spthy', content)
  
  if not ok then
    return {
      valid = false,
      error = result
    }
  end
  
  return {
    valid = true
  }
end

-- Test both queries
local original_result = validate_query(original_query_path)
local fixed_result = validate_query(fixed_query_path)

-- Write results to file
local results = {
  "Setup successful: " .. (setup_ok and "YES" or "NO"),
  "",
  "ORIGINAL QUERY:",
  "Valid: " .. (original_result.valid and "YES" or "NO"),
  original_result.valid and "" or ("Error: " .. tostring(original_result.error)),
  "",
  "FIXED QUERY:",
  "Valid: " .. (fixed_result.valid and "YES" or "NO"),
  fixed_result.valid and "" or ("Error: " .. tostring(fixed_result.error))
}

local file = io.open(results_file, 'w')
if file then
  file:write(table.concat(results, '\n'))
  file:close()
  print("Results written to " .. results_file)
else
  print("Failed to write results to file")
end

-- Ensure script exits
vim.cmd('qa!') 