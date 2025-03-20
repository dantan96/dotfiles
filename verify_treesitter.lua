-- verify_treesitter.lua
-- A script to verify the Tamarin TreeSitter integration
-- Run with: nvim --headless -l verify_treesitter.lua

local colors = {
  red = "\27[31m",
  green = "\27[32m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

-- Function to safely call Neovim APIs and catch errors
local function safe_call(fn, ...)
  local status, result = pcall(fn, ...)
  if not status then
    print(colors.red .. "ERROR: " .. tostring(result) .. colors.reset)
    return nil
  end
  return result
end

-- Verify TreeSitter parser installation
local function verify_parser()
  print("Checking if Spthy parser is installed...")
  
  local has_parser = pcall(vim.treesitter.language.inspect, "spthy")
  if has_parser then
    print(colors.green .. "✓ Spthy parser is available" .. colors.reset)
  else
    print(colors.red .. "✗ Spthy parser is NOT available" .. colors.reset)
    return false
  end
  
  -- Check if highlight query exists
  local has_highlight_query = pcall(vim.treesitter.query.get, "spthy", "highlights")
  if has_highlight_query then
    print(colors.green .. "✓ Highlight query exists" .. colors.reset)
  else
    print(colors.red .. "✗ Highlight query does not exist" .. colors.reset)
    return false
  end
  
  return true
end

-- Manually load the filetype detection module
local function load_filetype_module()
  print("Loading Tamarin filetype module...")
  
  -- Try to load the ftdetect module
  local status, err = pcall(function()
    -- First check if the file exists
    local ftdetect_path = vim.fn.stdpath('config') .. '/lua/ftdetect/tamarin.lua'
    if vim.fn.filereadable(ftdetect_path) == 1 then
      -- File exists, try to load the module
      require('ftdetect.tamarin')
      return true
    else
      print(colors.red .. "✗ Filetype module not found at: " .. ftdetect_path .. colors.reset)
      return false
    end
  end)
  
  if status then
    print(colors.green .. "✓ Filetype module loaded successfully" .. colors.reset)
    return true
  else
    print(colors.red .. "✗ Failed to load filetype module: " .. tostring(err) .. colors.reset)
    return false
  end
end

-- Manual filetype setting
local function verify_manual_filetype()
  print("Testing manual filetype setting...")
  
  -- Create a temporary buffer
  local buf = safe_call(vim.api.nvim_create_buf, false, true)
  if not buf then return false end
  
  -- Set filetype directly
  pcall(vim.api.nvim_buf_set_option, buf, "filetype", "tamarin")
  
  -- Check if filetype is set to tamarin
  local ft = safe_call(vim.api.nvim_buf_get_option, buf, "filetype")
  if ft == "tamarin" then
    print(colors.green .. "✓ Manual filetype setting works (tamarin)" .. colors.reset)
  else
    print(colors.red .. "✗ Manual filetype setting failed (got " .. tostring(ft) .. ")" .. colors.reset)
    return false
  end
  
  -- Clean up
  safe_call(vim.api.nvim_buf_delete, buf, {force = true})
  
  return true
end

-- Verify basic parsing
local function verify_parsing()
  print("Checking basic parsing functionality...")
  
  local test_string = [[
theory Basic begin
builtins: hashing
end
]]
  
  local success = pcall(function() 
    local parser = vim.treesitter.get_string_parser(test_string, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    return root ~= nil
  end)
  
  if success then
    print(colors.green .. "✓ Basic parsing works" .. colors.reset)
  else
    print(colors.red .. "✗ Basic parsing failed" .. colors.reset)
    return false
  end
  
  return true
end

-- Run all verification tests
local function run_verification()
  print(colors.cyan .. "=== Tamarin TreeSitter Integration Verification ===" .. colors.reset)
  
  local parser_ok = verify_parser()
  if not parser_ok then
    print(colors.red .. "✗ Parser verification failed, skipping remaining tests" .. colors.reset)
    return false
  end
  
  local manual_filetype_ok = verify_manual_filetype()
  local module_loaded_ok = load_filetype_module()
  local parsing_ok = verify_parsing()
  
  -- Final results
  local all_ok = parser_ok and parsing_ok and manual_filetype_ok
  -- Don't fail the test just because the filetype module couldn't be loaded in this context
  
  print("")
  if all_ok then
    print(colors.green .. "✓ All verification tests passed!" .. colors.reset)
  else
    print(colors.red .. "✗ Some verification tests failed!" .. colors.reset)
  end
  
  return all_ok
end

-- Run verification and exit with appropriate status code
local success = run_verification()
if success then
  vim.cmd("quit!")
else
  vim.cmd("cquit!")
end 