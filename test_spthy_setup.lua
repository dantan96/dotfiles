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
  log("Parser info found")
else
  log("ERROR: Parser not available. TreeSitter won't work without it.")
end

-- 2. Check highlight query
local has_query, query = pcall(function()
  return vim.treesitter.query.get("spthy", "highlights")
end)
log("Highlight query available: " .. tostring(has_query))
if not has_query then
  log("ERROR: Highlight query not found. Check queries/spthy/highlights.scm")
end

-- 3. Check runtime paths
log("\nChecking runtimepath for parser directory:")
local runtime_paths = vim.api.nvim_get_option('runtimepath')
local parser_path = vim.fn.stdpath("config") .. "/parser"
if runtime_paths:find(parser_path, 1, true) then
  log("Parser directory is in runtimepath")
else
  log("ERROR: Parser directory not in runtimepath")
end

-- 4. Check if parser files exist
log("\nChecking parser files:")
local site_parser = vim.fn.stdpath('data') .. '/site/parser/spthy.so'
local config_parser = vim.fn.stdpath('config') .. '/parser/spthy.so'

if vim.fn.filereadable(site_parser) == 1 then
  log("Parser found at: " .. site_parser)
else
  log("Parser NOT found at: " .. site_parser)
end

if vim.fn.filereadable(config_parser) == 1 then
  log("Parser found at: " .. config_parser)
else
  log("Parser NOT found at: " .. config_parser)
end

-- 5. Check if we can load a sample file
local test_file = "test.spthy"
if vim.fn.filereadable(test_file) == 1 then
  log("\nTest file exists: " .. test_file)
  
  -- Try to load the file
  local bufnr = vim.fn.bufadd(test_file)
  vim.fn.bufload(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  vim.bo[bufnr].filetype = "spthy"
  
  log("Buffer loaded with filetype: " .. vim.bo[bufnr].filetype)
  
  -- Try to enable TreeSitter manually
  log("Trying to enable TreeSitter manually:")
  
  local ts_ok = pcall(function()
    if vim.treesitter.start then
      vim.treesitter.start(bufnr, "spthy")
      log("  - vim.treesitter.start() called successfully")
    else
      log("  - vim.treesitter.start not available")
    end
  end)
  
  if not ts_ok then
    log("  - Error calling vim.treesitter.start()")
  end
  
  -- Check if TreeSitter is active
  local active = false
  pcall(function()
    active = vim.treesitter.highlighter.active[bufnr] ~= nil
  end)
  log("TreeSitter highlighting active: " .. tostring(active))
  
  if not active then
    log("DIAGNOSTIC: TreeSitter highlighting not active.")
    log("Possible causes:")
    log("1. Missing or incompatible parser")
    log("2. TreeSitter module not properly initialized")
    log("3. Missing or invalid highlight query file")
    log("4. Need to enable treesitter explicitly with TSEnable")
  end
  
  -- Try to get the syntax tree
  local has_tree = false
  pcall(function()
    local parser = vim.treesitter.get_parser(bufnr, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    has_tree = root ~= nil
    if has_tree then
      log("  - Successfully parsed syntax tree")
    end
  end)
  
  if not has_tree then
    log("  - Failed to parse syntax tree")
  end
  
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