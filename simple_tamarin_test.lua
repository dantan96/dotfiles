-- simple_tamarin_test.lua
-- A simple direct test of the tamarin parser
-- Run with: nvim --headless -l simple_tamarin_test.lua

-- Setup colors
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

print(colors.cyan .. "=== Simple Tamarin Parser Test ===" .. colors.reset)

-- Directly attempt to load the tamarin parser
local tamarin_ok, tamarin_err = pcall(function()
  return vim.treesitter.language.require_language("tamarin")
end)

if tamarin_ok then
  print(colors.green .. "✓ Successfully loaded tamarin parser" .. colors.reset)
else
  print(colors.red .. "✗ Failed to load tamarin parser: " .. tostring(tamarin_err) .. colors.reset)
  
  -- Check for specific error patterns
  if tamarin_err:find("symbol not found") then
    print(colors.yellow .. "  This is a symbol error - the parser exists but has wrong symbol name" .. colors.reset)
  elseif tamarin_err:find("no such file") then  
    print(colors.yellow .. "  This is a file error - the parser file is missing" .. colors.reset)
  end
  
  -- Exit with error
  vim.cmd("cquit!")
end

-- If we made it here, try to parse a simple tamarin string
local test_string = [[
theory Basic begin
builtins: hashing
end
]]

local parse_ok, parse_err = pcall(function() 
  local parser = vim.treesitter.get_string_parser(test_string, "tamarin")
  local tree = parser:parse()[1]
  local root = tree:root()
  return root ~= nil
end)

if parse_ok then
  print(colors.green .. "✓ Successfully parsed tamarin code" .. colors.reset)
else
  print(colors.red .. "✗ Failed to parse tamarin code: " .. tostring(parse_err) .. colors.reset)
  -- Exit with error
  vim.cmd("cquit!")
end

-- All tests passed
print(colors.green .. "All tamarin parser tests passed!" .. colors.reset)
vim.cmd("quit!") 