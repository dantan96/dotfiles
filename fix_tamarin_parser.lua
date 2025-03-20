-- fix_tamarin_parser.lua
-- Script to fix Tamarin TreeSitter parser integration issues
-- Run with: nvim --headless -l fix_tamarin_parser.lua

-- Setup colors for output
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

-- Execute shell command and return output
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

-- Get OS type
local function get_os()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return "windows"
  elseif vim.fn.has("macunix") == 1 then
    return "mac"
  else
    return "linux"
  end
end

-- Log with colorized output
local function log(msg, level)
  local color = colors.blue
  if level == "error" then
    color = colors.red
  elseif level == "success" then
    color = colors.green
  elseif level == "warning" then
    color = colors.yellow
  end
  
  print(color .. msg .. colors.reset)
  
  -- Also log to file
  local log_file = vim.fn.stdpath('cache') .. '/tamarin_fix.log'
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
    f:close()
  end
end

-- Fix function for the tamarin parser
local function fix_tamarin_parser()
  log("Starting Tamarin parser fix process", "info")
  
  -- 1. Find parser directories
  log("Checking parser directory structure", "info")
  
  -- Primary parser directory
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  if vim.fn.isdirectory(parser_dir) ~= 1 then
    log("Creating parser directory: " .. parser_dir, "info")
    vim.fn.mkdir(parser_dir, "p")
  end
  
  -- Config parser directory (for custom parsers)
  local config_parser_dir = vim.fn.stdpath('config') .. '/parser'
  local has_config_parser_dir = vim.fn.isdirectory(config_parser_dir) == 1
  
  if not has_config_parser_dir then
    log("Creating config parser directory: " .. config_parser_dir, "info")
    vim.fn.mkdir(config_parser_dir, "p")
  end
  
  -- 2. Check if spthy.so exists in parser directory
  local spthy_path = parser_dir .. '/spthy.so'
  local spthy_exists = file_exists(spthy_path)
  
  -- If spthy.so doesn't exist in the main parser dir, look in config dir
  local config_spthy_path = config_parser_dir .. '/spthy.so'
  local config_spthy_exists = file_exists(config_spthy_path)
  
  -- Also check for spthy directory with parser inside
  local spthy_dir_path = config_parser_dir .. '/spthy'
  local spthy_dir_exists = vim.fn.isdirectory(spthy_dir_path) == 1
  
  if not spthy_exists then
    if config_spthy_exists then
      log("Found spthy.so in config dir, copying to parser dir", "info")
      execute_command("cp " .. config_spthy_path .. " " .. spthy_path)
      spthy_exists = file_exists(spthy_path)
    elseif spthy_dir_exists then
      -- Look for the parser inside the spthy directory
      local parser_in_dir = config_parser_dir .. '/spthy/spthy.so'
      if file_exists(parser_in_dir) then
        log("Found spthy.so in spthy subdir, copying to parser dir", "info")
        execute_command("cp " .. parser_in_dir .. " " .. spthy_path)
        spthy_exists = file_exists(spthy_path)
      end
    end
  end
  
  if not spthy_exists then
    log("spthy.so not found. Cannot proceed with fix", "error")
    return false
  else
    log("Found spthy.so at: " .. spthy_path, "success")
  end
  
  -- 3. Create config directory parser symlink
  if not config_spthy_exists and not spthy_dir_exists then
    log("Creating symlink for spthy.so in config dir", "info")
    
    if get_os() == "windows" then
      execute_command("copy " .. spthy_path .. " " .. config_spthy_path)
    else
      execute_command("ln -sf " .. spthy_path .. " " .. config_spthy_path)
    end
  end
  
  -- 4. Fix tamarin.so symlink in parser dir
  local tamarin_path = parser_dir .. '/tamarin.so'
  local tamarin_exists = file_exists(tamarin_path)
  
  if tamarin_exists then
    -- Check if it's already a symlink to spthy.so
    local result = execute_command("ls -la " .. tamarin_path)
    if result:find("spthy%.so") then
      log("tamarin.so is already correctly linked to spthy.so", "success")
    else
      log("tamarin.so exists but is not linked to spthy.so - replacing", "warning")
      execute_command("rm " .. tamarin_path)
      tamarin_exists = false
    end
  end
  
  if not tamarin_exists then
    log("Creating tamarin.so symlink to spthy.so", "info")
    
    if get_os() == "windows" then
      execute_command("copy " .. spthy_path .. " " .. tamarin_path)
    else
      execute_command("ln -sf " .. spthy_path .. " " .. tamarin_path)
    end
    
    -- Verify the symlink was created
    tamarin_exists = file_exists(tamarin_path)
    if tamarin_exists then
      log("Successfully created tamarin.so", "success")
    else
      log("Failed to create tamarin.so", "error")
      return false
    end
  end
  
  -- 5. Create tamarin.so in config dir
  local config_tamarin_path = config_parser_dir .. '/tamarin.so'
  local config_tamarin_exists = file_exists(config_tamarin_path)
  
  if not config_tamarin_exists then
    log("Creating tamarin.so in config dir", "info")
    
    if get_os() == "windows" then
      execute_command("copy " .. spthy_path .. " " .. config_tamarin_path)
    else
      execute_command("ln -sf " .. spthy_path .. " " .. config_tamarin_path)
    end
    
    config_tamarin_exists = file_exists(config_tamarin_path)
    if config_tamarin_exists then
      log("Successfully created tamarin.so in config dir", "success")
    else
      log("Failed to create tamarin.so in config dir", "warning")
    end
  end
  
  -- 6. Update nvim-treesitter parser config
  log("Updating nvim-treesitter parser config", "info")
  
  local config_updated = pcall(function()
    -- First check if nvim-treesitter is available
    local has_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
    if not has_parsers then
      log("nvim-treesitter is not available", "warning")
      return false
    end
    
    -- Register Tamarin filetype to use Spthy parser
    if not parsers.get_parser_configs().tamarin then
      parsers.get_parser_configs().tamarin = {
        install_info = { 
          url = "none", -- No URL needed, we use the existing spthy parser
          files = {},   -- No files needed
        },
        filetype = "tamarin",
        used_by = { "tamarin" },
        maintainers = { "kevinmorio" },
      }
      
      log("Registered Tamarin filetype in nvim-treesitter", "success")
    end
    
    -- Register alias for the parser
    local has_ts_config, ts_config = pcall(require, "nvim-treesitter.configs")
    if has_ts_config then
      -- Register spthy parser to handle tamarin filetype
      pcall(function()
        vim.treesitter.language_add_aliases("spthy", { "tamarin" })
      end)
    end
    
    return true
  end)
  
  if config_updated then
    log("Parser configuration updated successfully", "success")
  else
    log("Parser configuration update may have failed", "warning")
  end
  
  -- 7. Final verification
  log("Performing final verification", "info")
  
  -- Try to load the parsers
  local spthy_ok = pcall(function() return vim.treesitter.language.require_language("spthy") end)
  local tamarin_ok = pcall(function() return vim.treesitter.language.require_language("tamarin") end)
  
  if spthy_ok then
    log("spthy parser loads successfully", "success")
  else
    log("spthy parser still fails to load", "error")
  end
  
  if tamarin_ok then
    log("tamarin parser loads successfully", "success")
  else
    log("tamarin parser still fails to load", "error")
  end
  
  if spthy_ok and tamarin_ok then
    log("Fix completed successfully!", "success")
    return true
  else
    log("Fix completed but verification failed. Manual investigation needed.", "warning")
    return false
  end
end

-- Run the fix
local success = fix_tamarin_parser()

-- Exit with appropriate code
if success then
  log("Fix completed successfully. Please restart Neovim.", "success")
  vim.cmd("quit!")
else
  log("Fix failed. See log for details.", "error")
  vim.cmd("cquit!")
end 