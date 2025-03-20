-- test_spthy_setup.lua
-- Test script to verify spthy configuration is working
-- Run with: nvim --headless -l test_spthy_setup.lua

local function log(msg)
  print(msg)
end

log("=== Testing Spthy Setup ===")

-- 1. Check if spthy parser is available
local has_parser, parser_info = pcall(vim.treesitter.language.inspect, "spthy")
log("Parser available: " .. tostring(has_parser))
if has_parser then
  log("Parser info: " .. vim.inspect(parser_info))
end

-- 2. Check highlight query
local has_query, query = pcall(function()
  return vim.treesitter.query.get("spthy", "highlights")
end)
log("Highlight query available: " .. tostring(has_query))

-- 3. Check if we can load a sample file
local test_file = "test.spthy"
if vim.fn.filereadable(test_file) == 1 then
  log("Test file exists: " .. test_file)
  
  -- Try to load the file
  local bufnr = vim.fn.bufadd(test_file)
  vim.fn.bufload(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  vim.bo[bufnr].filetype = "spthy"
  
  log("Buffer loaded with filetype: " .. vim.bo[bufnr].filetype)
  
  -- Check if TreeSitter is active
  local active = false
  pcall(function()
    active = vim.treesitter.highlighter.active[bufnr] ~= nil
  end)
  log("TreeSitter highlighting active: " .. tostring(active))
  
  -- Check highlight groups
  log("\nChecking highlight groups:")
  local highlight_groups = {
    "@keyword", "@function", "@variable", "@fact.persistent", 
    "@operator", "@punctuation.bracket", "@comment"
  }
  
  for _, group in ipairs(highlight_groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
    log(string.format("  %-20s defined: %s", group, tostring(ok and hl ~= nil)))
  end
end

log("\n=== Test Complete ===")

-- Exit nvim
vim.cmd("qa!") 