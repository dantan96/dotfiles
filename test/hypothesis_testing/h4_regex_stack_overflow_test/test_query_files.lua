-- Test TreeSitter query file parsing
-- This script tests if various versions of highlights.scm can be parsed without errors

-- Helper function to test parsing a query file
local function test_query_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    print("Could not open file: " .. file_path)
    return false
  end
  
  local query_text = file:read("*all")
  file:close()
  
  print("\nTesting: " .. file_path)
  
  local ok, result = pcall(function()
    return vim.treesitter.query.parse('spthy', query_text)
  end)
  
  if ok then
    print("✓ Query parsed successfully")
    return true
  else
    print("✗ Query failed to parse:")
    print(result)
    return false
  end
end

-- Configure paths to query files
local config_path = vim.fn.stdpath('config')
local query_files = {
  current = config_path..'/queries/spthy/highlights.scm',
  minimal = config_path..'/queries/spthy/highlights.scm.minimal',
  basic = config_path..'/queries/spthy/highlights.scm.01_basic',
  simple_regex = config_path..'/queries/spthy/highlights.scm.02_simple_regex',
  apostrophes = config_path..'/queries/spthy/highlights.scm.03_apostrophes',
  quantifiers = config_path..'/queries/spthy/highlights.scm.04_quantifiers',
  or_operators = config_path..'/queries/spthy/highlights.scm.05_or_operators'
}

-- Test all query files
print("Testing TreeSitter Query Parsing")
print("============================")

test_query_file(query_files.current)
test_query_file(query_files.minimal)
test_query_file(query_files.basic)
test_query_file(query_files.simple_regex)
test_query_file(query_files.apostrophes)
test_query_file(query_files.quantifiers)
test_query_file(query_files.or_operators)

print("\nAll query file tests completed") 