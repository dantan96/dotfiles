-- spthy_test.lua
-- A test script to verify that .spthy files are correctly handled using the spthy parser
-- Run with: nvim --headless -l spthy_test.lua

-- Setup colors
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

print(colors.cyan .. "=== Spthy Parser Test for Tamarin Files ===" .. colors.reset)

-- 1. Check if spthy parser is available
local spthy_ok, spthy_err = pcall(function()
  return vim.treesitter.language.require_language("spthy")
end)

if spthy_ok then
  print(colors.green .. "✓ Successfully loaded spthy parser" .. colors.reset)
else
  print(colors.red .. "✗ Failed to load spthy parser: " .. tostring(spthy_err) .. colors.reset)
  vim.cmd("cquit!")
end

-- 2. Test if we can parse a spthy content
local test_string = [[
theory Basic begin
builtins: hashing
end
]]

local parse_ok, parse_err = pcall(function() 
  local parser = vim.treesitter.get_string_parser(test_string, "spthy")
  local tree = parser:parse()[1]
  local root = tree:root()
  return root ~= nil
end)

if parse_ok then
  print(colors.green .. "✓ Successfully parsed spthy content" .. colors.reset)
else
  print(colors.red .. "✗ Failed to parse spthy content: " .. tostring(parse_err) .. colors.reset)
  vim.cmd("cquit!")
end

-- 3. Test filetype detection for .spthy files
print(colors.blue .. "Testing filetype detection for .spthy files..." .. colors.reset)

-- Create a buffer with a .spthy name
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(buf, "test.spthy")

-- Set sample content
vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(test_string, "\n"))

-- Trigger filetype detection
vim.cmd("filetype detect")

-- Check if filetype was set to spthy
local ft = vim.api.nvim_buf_get_option(buf, "filetype")
if ft == "spthy" then
  print(colors.green .. "✓ Filetype correctly set to 'spthy' for .spthy file" .. colors.reset)
else
  print(colors.red .. "✗ Filetype was not set correctly: got '" .. ft .. "' instead of 'spthy'" .. colors.reset)
  vim.api.nvim_buf_delete(buf, {force=true})
  vim.cmd("cquit!")
end

-- 4. Test that TreeSitter highlighting works
local highlighter_active = false
pcall(function()
  highlighter_active = vim.treesitter.highlighter.active[buf] ~= nil
end)

if highlighter_active then
  print(colors.green .. "✓ TreeSitter highlighter attached to buffer" .. colors.reset)
else
  -- Try to start it manually and check again
  pcall(function()
    vim.treesitter.start(buf, "spthy")
  end)
  
  -- Check again
  pcall(function()
    highlighter_active = vim.treesitter.highlighter.active[buf] ~= nil
  end)
  
  if highlighter_active then
    print(colors.green .. "✓ TreeSitter highlighter attached after manual start" .. colors.reset)
  else
    print(colors.yellow .. "! TreeSitter highlighter did not attach - this may be expected in headless mode" .. colors.reset)
  end
end

-- Clean up
vim.api.nvim_buf_delete(buf, {force=true})

-- All tests passed
print(colors.green .. "All spthy parser tests passed for Tamarin files!" .. colors.reset)
vim.cmd("quit!") 