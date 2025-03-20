-- error_logger.lua
-- A script to capture and log errors in Neovim, particularly focusing on TreeSitter errors
-- Run with: nvim --headless -l error_logger.lua

-- Setup colors for output
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

-- Track captured messages
local captured_messages = {}
local found_errors = false
local parser_error_pattern = "Failed to load parser"
local original_notify = vim.notify

-- Temporary log file path
local log_file = vim.fn.stdpath('cache') .. '/treesitter_errors.log'

-- Initialize log file
local function init_log_file()
  local file = io.open(log_file, "w")
  if file then
    file:write("Neovim TreeSitter Error Detection Log\n")
    file:write("====================================\n\n")
    file:close()
    return true
  else
    print(colors.red .. "ERROR: Could not create log file: " .. log_file .. colors.reset)
    return false
  end
end

-- Append message to log file
local function log_to_file(msg, level)
  local level_str = "INFO"
  if level == vim.log.levels.ERROR then level_str = "ERROR"
  elseif level == vim.log.levels.WARN then level_str = "WARN" 
  end
  
  local file = io.open(log_file, "a")
  if file then
    file:write("[" .. level_str .. "] " .. msg .. "\n")
    file:close()
  end
end

-- Override vim.notify to capture messages
local function capture_notify(msg, level, opts)
  -- Call original notify
  original_notify(msg, level, opts)
  
  -- Capture and log message
  log_to_file(msg, level)
  table.insert(captured_messages, {msg = msg, level = level})
  
  -- Check if this is a parser error
  if level == vim.log.levels.ERROR and msg:find(parser_error_pattern) then
    found_errors = true
    print(colors.red .. "TreeSitter Parser Error Detected: " .. msg .. colors.reset)
  end
end

-- Function to try loading a TreeSitter parser specifically
local function test_parser_loading(parser_name)
  print(colors.blue .. "Testing parser loading for: " .. parser_name .. colors.reset)
  
  local ok, err = pcall(function()
    return vim.treesitter.language.require_language(parser_name)
  end)
  
  if ok then
    print(colors.green .. "✓ Successfully loaded parser: " .. parser_name .. colors.reset)
    return true
  else
    print(colors.red .. "✗ Failed to load parser: " .. parser_name .. colors.reset)
    print(colors.red .. "  Error: " .. tostring(err) .. colors.reset)
    return false
  end
end

-- Try to create a temporary buffer with specific filetype
local function test_filetype_association(filetype, extension)
  print(colors.blue .. "Testing filetype association for: " .. filetype .. " (" .. extension .. ")" .. colors.reset)
  
  -- Create a buffer and set filename with extension
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "test." .. extension)
  
  -- Explicitly set the filetype
  vim.api.nvim_buf_set_option(bufnr, "filetype", filetype)
  
  -- Check if TreeSitter attached
  vim.defer_fn(function()
    local has_ts = false
    pcall(function()
      has_ts = vim.treesitter.highlighter.active[bufnr] ~= nil
    end)
    
    if has_ts then
      print(colors.green .. "✓ TreeSitter highlighting activated for filetype: " .. filetype .. colors.reset)
    else
      print(colors.red .. "✗ TreeSitter highlighting not activated for filetype: " .. filetype .. colors.reset)
    end
    
    -- Clean up buffer
    vim.api.nvim_buf_delete(bufnr, {force = true})
  end, 100)
  
  return true
end

-- Run diagnostics
local function run_diagnostics()
  print(colors.cyan .. "=== Neovim TreeSitter Error Diagnostics ===" .. colors.reset)
  
  -- Check TreeSitter availability
  if not pcall(function() return vim.treesitter end) then
    print(colors.red .. "✗ TreeSitter module not available" .. colors.reset)
    return false
  else
    print(colors.green .. "✓ TreeSitter module is available" .. colors.reset)
  end
  
  -- Check for parser installation paths
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  if vim.fn.isdirectory(parser_dir) == 1 then
    print(colors.green .. "✓ Parser directory exists: " .. parser_dir .. colors.reset)
    
    -- List installed parsers
    local parser_files = vim.fn.glob(parser_dir .. '/*.so', false, true)
    if #parser_files > 0 then
      print(colors.green .. "Found " .. #parser_files .. " parser files:" .. colors.reset)
      for _, file in ipairs(parser_files) do
        print("  - " .. vim.fn.fnamemodify(file, ':t'))
      end
    else
      print(colors.yellow .. "⚠ No parser files found in " .. parser_dir .. colors.reset)
    end
  else
    print(colors.yellow .. "⚠ Parser directory does not exist: " .. parser_dir .. colors.reset)
  end
  
  -- Test loading spthy parser
  local spthy_ok = test_parser_loading("spthy")
  
  -- Test loading tamarin parser (should fail, showing the error we're dealing with)
  local tamarin_ok = test_parser_loading("tamarin")
  
  -- Test filetype associations
  test_filetype_association("tamarin", "spthy")
  
  -- Check captured messages for errors
  if #captured_messages > 0 then
    print(colors.blue .. "\nCaptured " .. #captured_messages .. " messages:" .. colors.reset)
    local error_count = 0
    
    for i, msg_data in ipairs(captured_messages) do
      if msg_data.level == vim.log.levels.ERROR then
        error_count = error_count + 1
        if i <= 5 then -- Show only first 5 errors
          print(colors.red .. "ERROR: " .. msg_data.msg .. colors.reset)
        end
      end
    end
    
    if error_count > 5 then
      print(colors.yellow .. "...and " .. (error_count - 5) .. " more errors" .. colors.reset)
    end
    
    print(colors.blue .. "Full logs written to: " .. log_file .. colors.reset)
  else
    print(colors.green .. "\n✓ No messages captured" .. colors.reset)
  end
  
  -- Summary
  if found_errors then
    print(colors.red .. "\n✗ TreeSitter parser errors were detected" .. colors.reset)
  else
    print(colors.green .. "\n✓ No TreeSitter parser errors detected" .. colors.reset)
  end
  
  return true
end

-- Initialize
init_log_file()

-- Override notify to capture messages
vim.notify = capture_notify

-- Run diagnostics with a delay to allow for startup messages
vim.defer_fn(function()
  run_diagnostics()
  
  -- Exit after diagnostics
  vim.defer_fn(function()
    if found_errors then
      vim.cmd("cquit!")
    else
      vim.cmd("quit!")
    end
  end, 500)
end, 1000)

-- Restore notify on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.notify = original_notify
  end,
}) 