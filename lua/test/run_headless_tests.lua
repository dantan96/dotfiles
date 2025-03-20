-- run_headless_tests.lua
-- Non-interactive test script for Tamarin TreeSitter integration

local M = {}

-- Setup colors for output
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  white = "\27[37m",
  reset = "\27[0m",
}

local function debug_print(msg, level)
  level = level or "info"
  local color = colors.white
  if level == "error" then
    color = colors.red
  elseif level == "success" then
    color = colors.green
  elseif level == "warn" then
    color = colors.yellow
  elseif level == "info" then
    color = colors.blue
  end
  
  print(color .. "[TAMARIN TEST] " .. msg .. colors.reset)
end

local function format_result(name, success, message)
  if success then
    return colors.green .. "✓" .. colors.reset .. " " .. name .. ": " .. message
  else 
    return colors.red .. "✗" .. colors.reset .. " " .. name .. ": " .. message
  end
end

-- Run all tests
function M.run_all()
  debug_print("Running non-interactive Tamarin TreeSitter tests", "info")
  
  local results = {}
  local all_pass = true
  
  -- Test 1: Check if spthy parser is available
  local has_parser, parser_inspect = pcall(vim.treesitter.language.inspect, "spthy")
  table.insert(results, format_result(
    "Parser Availability", 
    has_parser, 
    has_parser and "spthy parser is available" or "spthy parser is NOT available"
  ))
  
  if not has_parser then
    all_pass = false
    debug_print("Parser test failed, skipping remaining tests", "error")
    
    -- Print summary and exit early
    print("\n" .. colors.cyan .. "=== Tamarin TreeSitter Test Results ===" .. colors.reset)
    for _, result in ipairs(results) do
      print(result)
    end
    print("\n" .. colors.red .. "Overall: FAIL" .. colors.reset)
    
    -- Force exit with error code
    vim.schedule(function() vim.cmd("qa! 1") end)
    return false
  end
  
  -- Test 2: Check if highlight query exists
  local has_highlight_query = pcall(vim.treesitter.query.get, "spthy", "highlights")
  table.insert(results, format_result(
    "Highlight Query",
    has_highlight_query,
    has_highlight_query and "Highlight query exists" or "Highlight query does not exist"
  ))
  
  if not has_highlight_query then all_pass = false end
  
  -- Test 3: Simple parser test on a string
  local test_string = [[
theory Basic begin
builtins: hashing
end
]]
  
  local parser_test_success = pcall(function() 
    local parser = vim.treesitter.get_string_parser(test_string, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    return root ~= nil
  end)
  
  table.insert(results, format_result(
    "Basic Parsing",
    parser_test_success,
    parser_test_success and "Successfully parsed basic theory" or "Failed to parse basic theory"
  ))
  
  if not parser_test_success then all_pass = false end
  
  -- Print test results
  print("\n" .. colors.cyan .. "=== Tamarin TreeSitter Test Results ===" .. colors.reset)
  for _, result in ipairs(results) do
    print(result)
  end
  
  print("\n" .. (all_pass and colors.green or colors.red) ..
    "Overall: " .. (all_pass and "PASS" or "FAIL") .. colors.reset)
  
  -- Schedule exit with appropriate exit code
  vim.schedule(function()
    vim.cmd("qa! " .. (all_pass and "0" or "1"))
  end)
  
  return all_pass
end

-- Just use this simple entry point that schedules exiting
if not pcall(debug.getlocal, 4, 1) then
  vim.schedule(function()
    M.run_all()
  end)
end

return M 