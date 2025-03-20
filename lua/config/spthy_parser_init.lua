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

-- Check if directory exists, create if it doesn't
local function ensure_directory(dir_path)
  if vim.fn.isdirectory(dir_path) ~= 1 then
    log("Creating directory: " .. dir_path, vim.log.levels.INFO)
    vim.fn.mkdir(dir_path, "p")
    return true
  end
  return false
end

function M.setup()
  log("Setting up Tamarin Spthy parser integration")
  
  -- Get the parser directory paths
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  local config_parser_dir = vim.fn.stdpath('config') .. '/parser'
  
  -- Ensure parser directories exist
  ensure_directory(parser_dir)
  ensure_directory(config_parser_dir)
  
  -- Check main parser directory first
  local spthy_path = parser_dir .. '/spthy.so'
  local config_spthy_path = config_parser_dir .. '/spthy.so'
  local spthy_exists = file_exists(spthy_path)
  local config_spthy_exists = file_exists(config_spthy_path)
  
  if not spthy_exists then
    if config_spthy_exists then
      -- If parser exists in config dir but not in data dir, copy it
      log("Found spthy.so in config dir, copying to parser dir", vim.log.levels.INFO)
      execute_command("cp " .. config_spthy_path .. " " .. spthy_path)
      spthy_exists = file_exists(spthy_path)
    else
      -- Look for parser in the spthy subdirectory
      local spthy_subdir = config_parser_dir .. '/spthy'
      if vim.fn.isdirectory(spthy_subdir) == 1 then
        local parser_in_subdir = spthy_subdir .. '/spthy.so'
        if file_exists(parser_in_subdir) then
          log("Found spthy.so in subdirectory, copying to parser dir", vim.log.levels.INFO)
          execute_command("cp " .. parser_in_subdir .. " " .. spthy_path)
          spthy_exists = file_exists(spthy_path)
        end
      end
    end
  end
  
  if not spthy_exists then
    log("Spthy parser not found at: " .. spthy_path, vim.log.levels.ERROR)
    return false
  end
  
  -- Now ensure that config directory has spthy.so (if it doesn't already)
  if not config_spthy_exists then
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      execute_command("copy " .. spthy_path .. " " .. config_spthy_path)
    else
      execute_command("ln -sf " .. spthy_path .. " " .. config_spthy_path)
    end
    log("Created spthy.so in config directory", vim.log.levels.INFO)
  end
  
  -- Check if tamarin.so already exists in parser dir
  local tamarin_path = parser_dir .. '/tamarin.so'
  local config_tamarin_path = config_parser_dir .. '/tamarin.so'
  
  if file_exists(tamarin_path) then
    -- Check if it's already a symlink to spthy.so
    local result = execute_command("ls -la " .. tamarin_path)
    if result:find("spthy%.so") then
      log("Tamarin parser symlink already exists", vim.log.levels.INFO)
    else
      -- File exists but is not a symlink to spthy.so - back it up
      local backup_path = tamarin_path .. ".backup." .. os.time()
      
      execute_command("mv " .. tamarin_path .. " " .. backup_path)
      log("Renamed existing tamarin.so to " .. backup_path, vim.log.levels.WARN)
      
      -- Create the symlink
      if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        -- Windows uses copy instead of symlink
        execute_command("copy " .. spthy_path .. " " .. tamarin_path)
      else
        -- Unix uses symlink
        execute_command("ln -sf " .. spthy_path .. " " .. tamarin_path)
      end
    end
  else
    -- Create the symlink if tamarin.so doesn't exist
    log("Creating tamarin.so symlink", vim.log.levels.INFO)
    
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      -- Windows uses copy instead of symlink
      execute_command("copy " .. spthy_path .. " " .. tamarin_path)
    else
      -- Unix uses symlink
      execute_command("ln -sf " .. spthy_path .. " " .. tamarin_path)
    end
  end
  
  -- Also create tamarin.so in config directory if it doesn't exist
  if not file_exists(config_tamarin_path) then
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      execute_command("copy " .. spthy_path .. " " .. config_tamarin_path)
    else
      execute_command("ln -sf " .. spthy_path .. " " .. config_tamarin_path)
    end
    log("Created tamarin.so in config directory", vim.log.levels.INFO)
  end
  
  -- Verify both symlinks were created
  if file_exists(tamarin_path) and file_exists(config_tamarin_path) then
    log("Successfully created parser mapping for Tamarin", vim.log.levels.INFO)
    
    -- Try to load the parser to verify
    local ok, err = pcall(function()
      return vim.treesitter.language.require_language("tamarin")
    end)
    
    if ok then
      log("Verified: Parser 'tamarin' loaded successfully", vim.log.levels.INFO)
    else
      log("Warning: Parser created but loading still fails: " .. tostring(err), vim.log.levels.WARN)
      log("This might require a Neovim restart to take effect", vim.log.levels.WARN)
    end
    
    return true
  else
    log("Failed to create parser mapping for Tamarin", vim.log.levels.ERROR)
    return false
  end
end

return M 