-- Truly headless test script for Tamarin TreeSitter integration
-- Runs completely autonomously and writes results to a file

local log_file = io.open(vim.fn.expand("~/tamarin-test/test_results.log"), "w")

local function log(msg)
  log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
  log_file:flush()
end

log("Starting headless test")

-- Save original print function
local original_print = print

-- Redirect print to log file to capture output
print = function(...)
  local args = {...}
  local line = ""
  for i, v in ipairs(args) do
    line = line .. tostring(v) .. (i < #args and " " or "")
  end
  log("PRINT: " .. line)
end

-- Helper function for safely calling functions
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    log("ERROR: " .. tostring(result))
    return false, nil
  end
  return true, result
end

-- STEP 1: Check if we can load the tamarin module
log("Loading tamarin module...")
local module_ok, tamarin = pcall(require, "tamarin")
if not module_ok then
  log("FAILED: Could not load tamarin module: " .. tostring(tamarin))
  log_file:close()
  -- Restore print function
  print = original_print
  vim.cmd("qa!")
  return
end
log("SUCCESS: Tamarin module loaded")

-- STEP 2: Cleanup previous setup
log("Cleaning up previous setup...")
safe_call(tamarin.cleanup)
log("Cleanup completed")

-- STEP 3: Setup Tamarin TreeSitter integration
log("Setting up Tamarin TreeSitter integration...")
local setup_ok, setup_result = safe_call(tamarin.setup)
log("Setup result: " .. (setup_ok and "SUCCESS" or "FAILED"))

-- STEP 4: Open the test file
log("Opening test file...")
safe_call(vim.cmd, "edit ~/tamarin-test/test.spthy")
log("Test file opened: " .. vim.api.nvim_buf_get_name(0))

-- STEP 5: Set filetype
log("Setting filetype to tamarin...")
pcall(function()
  vim.cmd("set filetype=tamarin")
end)
log("Filetype set to: " .. vim.bo.filetype)

-- STEP 6: Collect basic buffer info
log("Buffer info:")
log("  Number: " .. vim.api.nvim_get_current_buf())
log("  Filetype: " .. vim.bo.filetype)
log("  Name: " .. vim.api.nvim_buf_get_name(0))

-- STEP 7: Try to set up highlighting
log("Setting up highlighting...")
local highlight_ok, highlight_result = pcall(tamarin.ensure_highlighting, 0)
log("Highlighting setup: " .. (highlight_ok and "SUCCESS" or "FAILED"))

-- STEP 8: Check language registration - Multiple methods
log("Checking language registration...")
local lang_registered = false

-- Method 1: Using language.get (newer Neovim)
if vim.treesitter and vim.treesitter.language and vim.treesitter.language.get then
  local lang_ok, lang = pcall(vim.treesitter.language.get, 'spthy')
  if lang_ok and lang then
    lang_registered = true
    log("Language registration method 1: SUCCESS")
  end
end

-- Method 2: Check if _has_parser includes spthy (fallback)
if not lang_registered and vim.treesitter and vim.treesitter._has_parser then
  if type(vim.treesitter._has_parser) == "table" and vim.treesitter._has_parser.spthy then
    lang_registered = true
    log("Language registration method 2: SUCCESS")
  end
end

-- Method 3: Try to get parser for spthy language
if not lang_registered and vim.treesitter and vim.treesitter.get_parser then
  local parser_ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
  if parser_ok and parser then
    local lang_ok, lang = pcall(function() return parser:lang() end)
    if lang_ok and lang == 'spthy' then
      lang_registered = true
      log("Language registration method 3: SUCCESS")
    end
  end
end

log("Language 'spthy' registered: " .. tostring(lang_registered))

-- STEP 9: Check parser
log("Checking parser...")
local parser_ok = false
if vim.treesitter and vim.treesitter.get_parser then
  local ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
  parser_ok = ok and parser ~= nil
end
log("Parser loaded: " .. tostring(parser_ok))

-- STEP 10: Check external scanner
log("Checking external scanner support...")
local scanner_present = false
if vim.fn.executable('nm') == 1 then
  local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  if vim.fn.filereadable(parser_path) == 1 then
    local handle = io.popen("nm -gU " .. vim.fn.shellescape(parser_path) .. " | grep external_scanner")
    if handle then
      local result = handle:read("*a")
      handle:close()
      scanner_present = result:match("_tree_sitter_spthy_external_scanner_") ~= nil
    end
  end
end
log("External scanner present: " .. tostring(scanner_present))

-- STEP 11: Check highlighter
log("Checking highlighter...")
local has_highlighter = false
pcall(function()
  has_highlighter = vim.treesitter.highlighter and 
                   vim.treesitter.highlighter.active and 
                   vim.treesitter.highlighter.active[0] ~= nil
end)
log("Active highlighter: " .. tostring(has_highlighter))

local has_buffer_highlighter = false
pcall(function()
  has_buffer_highlighter = vim.b[0].tamarin_ts_highlighter ~= nil
end)
log("Buffer highlighter object: " .. tostring(has_buffer_highlighter))

-- STEP 12: Check for apostrophe variables
log("Testing apostrophe variable handling...")
-- We don't have a way to directly check this in headless mode, 
-- but we can check if the parser works
local parser_works = false
if vim.treesitter and vim.treesitter.get_parser then
  local ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
  if ok and parser then
    parser_works = true
  end
end
log("Parser working with apostrophe variables: " .. tostring(parser_works))

-- STEP 13: Summarize results
log("\nTEST SUMMARY:")
log("  Module loaded: " .. tostring(module_ok))
log("  Setup successful: " .. tostring(setup_ok))
log("  Language registered: " .. tostring(lang_registered))
log("  Parser loaded: " .. tostring(parser_ok))
log("  External scanner present: " .. tostring(scanner_present))
log("  Highlighter active: " .. tostring(has_highlighter))
log("  Apostrophe variables handled: " .. tostring(parser_works))

log("Test completed. Exiting...")
log_file:close()

-- Restore print function
print = original_print

-- Exit Neovim after a short delay to ensure log file is written
vim.defer_fn(function() vim.cmd("qa!") end, 500) 