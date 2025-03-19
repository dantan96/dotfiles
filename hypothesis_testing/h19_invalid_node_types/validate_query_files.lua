-- Script to validate original and fixed query files
-- To run: nvim --headless -n -u NORC -c "luafile /path/to/this/file.lua" -c "qa!"

-- Initialize TreeSitter for 'spthy' language
local function setup()
  -- Register language
  if vim.treesitter.language and vim.treesitter.language.register then
    vim.treesitter.language.register('spthy', 'tamarin')
  end
  
  -- Add parser with explicit path (Neovim 0.9+)
  local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  if vim.treesitter.language and vim.treesitter.language.add and vim.fn.filereadable(parser_path) == 1 then
    vim.treesitter.language.add('spthy', { path = parser_path })
  end
  
  return true
end

-- Validate a query file
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

-- Setup TreeSitter
setup()

-- Test original query
local original_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
local original_result = validate_query(original_query_path)

-- Test fixed query
local fixed_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm.fixed'
local fixed_result = validate_query(fixed_query_path)

-- Display results
print("ORIGINAL QUERY:")
print("Valid: " .. (original_result.valid and "YES" or "NO"))
if not original_result.valid then
  print("Error: " .. tostring(original_result.error))
end

print("\nFIXED QUERY:")
print("Valid: " .. (fixed_result.valid and "YES" or "NO"))
if not fixed_result.valid then
  print("Error: " .. tostring(fixed_result.error))
end 