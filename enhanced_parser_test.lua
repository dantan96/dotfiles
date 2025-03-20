-- enhanced_parser_test.lua
-- A comprehensive test script that specifically tests for parser errors
-- Run with: nvim --headless -l enhanced_parser_test.lua

-- Setup colors for output
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m", 
  cyan = "\27[36m",
  reset = "\27[0m",
}

-- Test results
local results = {}
local all_pass = true

-- Helper to add a test result
local function add_result(name, success, message)
  local result = {
    name = name,
    success = success,
    message = message
  }
  
  table.insert(results, result)
  if not success then all_pass = false end
  
  -- Print immediately for real-time feedback
  local symbol = success and colors.green .. "✓" .. colors.reset or colors.red .. "✗" .. colors.reset
  print(symbol .. " " .. name .. ": " .. message)
  
  return success
end

-- Check if file exists
local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- Get parser installation path
local function get_parser_dir()
  return vim.fn.stdpath('data') .. '/site/parser'
end

-- Check parser directory structure
local function test_parser_directory()
  local parser_dir = get_parser_dir()
  
  -- Check if parser directory exists
  local dir_exists = vim.fn.isdirectory(parser_dir) == 1
  add_result(
    "Parser Directory", 
    dir_exists,
    dir_exists and "Parser directory exists at " .. parser_dir or "Parser directory missing: " .. parser_dir
  )
  
  if not dir_exists then return false end
  
  -- Check for spthy.so
  local spthy_path = parser_dir .. '/spthy.so'
  local spthy_exists = file_exists(spthy_path)
  add_result(
    "Spthy Parser", 
    spthy_exists,
    spthy_exists and "spthy.so exists" or "spthy.so missing at " .. spthy_path
  )
  
  -- Check for tamarin.so (this should be a symlink to spthy.so)
  local tamarin_path = parser_dir .. '/tamarin.so'
  local tamarin_exists = file_exists(tamarin_path)
  add_result(
    "Tamarin Parser", 
    tamarin_exists,
    tamarin_exists and "tamarin.so exists" or "tamarin.so missing at " .. tamarin_path
  )
  
  -- If both exist, check if tamarin.so is a symlink to spthy.so
  local is_symlink = false
  if spthy_exists and tamarin_exists then
    local handle = io.popen("ls -la " .. tamarin_path .. " 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      is_symlink = result:find("spthy%.so") ~= nil
      
      add_result(
        "Parser Symlink", 
        is_symlink,
        is_symlink and "tamarin.so is correctly linked to spthy.so" or "tamarin.so is NOT linked to spthy.so"
      )
    end
  end
  
  return spthy_exists and tamarin_exists and is_symlink
end

-- Test parser loading
local function test_parser_loading()
  -- Try loading spthy parser
  local spthy_ok, spthy_err = pcall(function()
    return vim.treesitter.language.require_language("spthy")
  end)
  
  add_result(
    "Load Spthy Parser", 
    spthy_ok,
    spthy_ok and "Successfully loaded spthy parser" or "Failed to load spthy parser: " .. tostring(spthy_err)
  )
  
  -- Try loading tamarin parser (should work if symlink is correct)
  local tamarin_ok, tamarin_err = pcall(function()
    return vim.treesitter.language.require_language("tamarin")
  end)
  
  add_result(
    "Load Tamarin Parser", 
    tamarin_ok,
    tamarin_ok and "Successfully loaded tamarin parser" or "Failed to load tamarin parser: " .. tostring(tamarin_err)
  )
  
  -- Specific check for "symbol not found" error
  local symbol_error = tamarin_err and tostring(tamarin_err):find("symbol not found") ~= nil
  if not tamarin_ok and symbol_error then
    add_result(
      "Symbol Error Check", 
      false,
      "Detected 'symbol not found' error - parser mapping issue"
    )
  end
  
  return spthy_ok and tamarin_ok
end

-- Test filetype detection
local function test_filetype_detection()
  -- Test if we can set tamarin filetype
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set filetype
  local ok = pcall(vim.api.nvim_buf_set_option, buf, "filetype", "tamarin")
  
  -- Check if filetype was set correctly
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")
  local ft_ok = ft == "tamarin"
  
  add_result(
    "Filetype Setting",
    ft_ok,
    ft_ok and "Successfully set tamarin filetype" or "Failed to set tamarin filetype (got " .. tostring(ft) .. ")"
  )
  
  -- Clean up
  vim.api.nvim_buf_delete(buf, {force=true})
  
  return ft_ok
end

-- Test tree-sitter highlighting for tamarin
local function test_highlighting()
  -- Create a buffer with tamarin content
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set sample content
  local sample = [[
theory Test begin
  builtins: hashing
end
]]
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(sample, "\n"))
  
  -- Set filetype
  vim.api.nvim_buf_set_option(buf, "filetype", "tamarin")
  
  -- Check if highlighter attaches
  local highlighter_ok = false
  
  -- Give it a moment to attach
  vim.defer_fn(function()
    pcall(function()
      highlighter_ok = vim.treesitter.highlighter.active[buf] ~= nil
    end)
    
    add_result(
      "Highlighter Attachment",
      highlighter_ok,
      highlighter_ok and "TreeSitter highlighter attached successfully" or "TreeSitter highlighter failed to attach"
    )
    
    -- Clean up
    vim.api.nvim_buf_delete(buf, {force=true})
    
    -- Finish tests and exit
    finish_tests()
  end, 500)
  
  return true  -- Actual result handled in callback
end

-- Test parser ability to parse tamarin
local function test_parsing()
  local test_string = [[
theory Basic begin
builtins: hashing
end
]]
  
  -- Try parsing with spthy parser
  local spthy_ok = pcall(function() 
    local parser = vim.treesitter.get_string_parser(test_string, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    return root ~= nil
  end)
  
  add_result(
    "Parse with Spthy", 
    spthy_ok,
    spthy_ok and "Successfully parsed using spthy parser" or "Failed to parse using spthy parser"
  )
  
  -- Try parsing with tamarin parser
  local tamarin_ok = pcall(function() 
    local parser = vim.treesitter.get_string_parser(test_string, "tamarin")
    local tree = parser:parse()[1]
    local root = tree:root()
    return root ~= nil
  end)
  
  add_result(
    "Parse with Tamarin", 
    tamarin_ok,
    tamarin_ok and "Successfully parsed using tamarin parser" or "Failed to parse using tamarin parser"
  )
  
  return spthy_ok and tamarin_ok
end

-- Print summary and exit
local function finish_tests()
  print("\n" .. colors.cyan .. "=== Tamarin Parser Test Results ===" .. colors.reset)
  
  for _, result in ipairs(results) do
    local symbol = result.success and colors.green .. "✓" .. colors.reset or colors.red .. "✗" .. colors.reset
    print(symbol .. " " .. result.name .. ": " .. result.message)
  end
  
  -- Check if tamarin parser failures are critical
  local tamarin_load_failed = false
  local tamarin_parse_failed = false
  
  for _, result in ipairs(results) do
    if result.name == "Load Tamarin Parser" and not result.success then
      tamarin_load_failed = true
    end
    if result.name == "Parse with Tamarin" and not result.success then
      tamarin_parse_failed = true
    end
  end
  
  -- If both tamarin parser tests fail, we consider this a critical failure
  local critical_failure = tamarin_load_failed and tamarin_parse_failed
  
  print("\n" .. (all_pass and colors.green or colors.red) ..
    "Overall: " .. (all_pass and "PASS" or "FAIL") .. colors.reset)
  
  -- Force the test to fail if we have critical failures
  if critical_failure then
    print(colors.red .. "Critical failures detected with Tamarin parser" .. colors.reset)
    vim.cmd('cquit!')
  else
    -- Exit with appropriate code based on if all tests pass
    if all_pass then
      vim.cmd('quit!')
    else
      vim.cmd('cquit!')
    end
  end
end

-- Run all tests
print(colors.cyan .. "=== Running Enhanced Tamarin Parser Tests ===" .. colors.reset)

test_parser_directory()
test_parser_loading()
test_filetype_detection()
test_parsing()
test_highlighting()  -- This will call finish_tests() when done 