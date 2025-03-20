-- spthy_parser_init.lua
-- Create a symlink from tamarin.so to spthy.so to prevent "symbol not found" errors

local M = {}

-- Wrapper for running shell commands
local function execute_command(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  local result = handle:read("*a")
  handle:close()
  return result
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

-- Log message with timestamps
local function log(msg, level)
  level = level or vim.log.levels.INFO
  
  local log_file = vim.fn.stdpath('cache') .. '/spthy_parser_init.log'
  local f = io.open(log_file, "a")
  if f then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local level_str = level == vim.log.levels.ERROR and "ERROR" or 
                     level == vim.log.levels.WARN and "WARN" or "INFO"
    
    f:write(string.format("[%s] [%s] %s\n", timestamp, level_str, msg))
    f:close()
  end
  
  -- Also notify the user
  vim.notify(msg, level)
end

function M.setup()
  log("Setting up Tamarin Spthy parser integration")
  
  -- Get the parser directory path
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  
  -- Check if it exists
  if vim.fn.isdirectory(parser_dir) ~= 1 then
    log("Parser directory does not exist: " .. parser_dir, vim.log.levels.ERROR)
    return false
  end
  
  -- Check if spthy.so exists
  local spthy_path = parser_dir .. '/spthy.so'
  if not file_exists(spthy_path) then
    log("Spthy parser not found at: " .. spthy_path, vim.log.levels.ERROR)
    return false
  end
  
  -- Check if tamarin.so already exists
  local tamarin_path = parser_dir .. '/tamarin.so'
  
  if file_exists(tamarin_path) then
    -- Check if it's already a symlink to spthy.so
    local result = execute_command("ls -la " .. tamarin_path)
    if result:find("spthy%.so") then
      log("Tamarin parser symlink already exists", vim.log.levels.INFO)
      return true
    else
      -- File exists but is not a symlink to spthy.so - back it up
      local backup_path = tamarin_path .. ".backup." .. os.time()
      
      execute_command("mv " .. tamarin_path .. " " .. backup_path)
      log("Renamed existing tamarin.so to " .. backup_path, vim.log.levels.WARN)
    end
  end
  
  -- Create the symlink
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- Windows uses copy instead of symlink for compatibility
    execute_command("copy " .. spthy_path .. " " .. tamarin_path)
    log("Copied spthy.so to tamarin.so", vim.log.levels.INFO)
  else
    -- Unix uses symlink
    execute_command("ln -sf " .. spthy_path .. " " .. tamarin_path)
    log("Created symlink from tamarin.so to spthy.so", vim.log.levels.INFO)
  end
  
  -- Verify the symlink was created
  if file_exists(tamarin_path) then
    log("Successfully created parser mapping for Tamarin", vim.log.levels.INFO)
    return true
  else
    log("Failed to create parser mapping for Tamarin", vim.log.levels.ERROR)
    return false
  end
end

return M 