-- tamarin_parser_rename.lua
-- A script that copies the spthy.so parser to tamarin.so and renames the exported symbol
-- Run with: nvim --headless -l tamarin_parser_rename.lua

-- This requires the 'objcopy' tool which is part of GNU binutils
-- Mac users can install it with: brew install binutils
-- Linux users typically have it installed by default

-- Setup colors for output
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

-- Log with colorized output
local function log(msg, level)
  local color = colors.blue
  if level == "error" then
    color = colors.red
  elseif level == "success" then
    color = colors.green
  elseif level == "warning" then
    color = colors.yellow
  elseif level == "cmd" then
    color = colors.cyan
  end
  
  print(color .. msg .. colors.reset)
  
  -- Also log to file
  local log_file = vim.fn.stdpath('cache') .. '/symbol_rename.log'
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
    f:close()
  end
end

-- Wrapper for running shell commands
local function execute_command(cmd)
  log("Running: " .. cmd, "cmd")
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

-- Check if a command is available
local function command_exists(cmd)
  local result = execute_command("which " .. cmd .. " 2>/dev/null")
  return result and result:match("/%w+$") ~= nil
end

-- Get OS information
local function get_os_info()
  local os_name = vim.loop.os_uname().sysname
  local is_mac = os_name == "Darwin"
  local is_linux = os_name == "Linux"
  local is_windows = package.config:sub(1,1) == '\\'
  
  return {
    name = os_name,
    is_mac = is_mac,
    is_linux = is_linux, 
    is_windows = is_windows
  }
end

-- Main rename function
local function rename_parser_symbol()
  log("=== Tamarin Parser Symbol Renaming Utility ===", "info")
  
  -- Get OS information
  local os_info = get_os_info()
  log("Detected OS: " .. os_info.name, "info")
  
  -- 1. Check if required tools are available
  local objcopy_cmd = nil
  
  if command_exists("objcopy") then
    objcopy_cmd = "objcopy"
  elseif command_exists("gobjcopy") then
    objcopy_cmd = "gobjcopy"
  end
  
  if not objcopy_cmd then
    log("ERROR: objcopy tool not found", "error")
    
    if os_info.is_mac then
      log("On macOS, install with: brew install binutils", "warning")
      log("After installation, ensure gobjcopy is in your PATH", "warning")
    elseif os_info.is_linux then
      log("On Linux, install with: sudo apt-get install binutils", "warning")
    else
      log("Please install GNU binutils for your operating system", "warning")
    end
    
    return false
  else
    log("Found objcopy tool: " .. objcopy_cmd, "success")
  end
  
  -- 2. Find the parser directories
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  local config_parser_dir = vim.fn.stdpath('config') .. '/parser'
  
  log("Checking parser directories", "info")
  
  -- Ensure both directories exist
  if vim.fn.isdirectory(parser_dir) ~= 1 then
    log("Creating parser directory: " .. parser_dir, "info")
    vim.fn.mkdir(parser_dir, "p")
  end
  
  if vim.fn.isdirectory(config_parser_dir) ~= 1 then
    log("Creating config parser directory: " .. config_parser_dir, "info")
    vim.fn.mkdir(config_parser_dir, "p")
  end
  
  -- 3. Locate spthy.so
  local spthy_path = parser_dir .. '/spthy.so'
  local config_spthy_path = config_parser_dir .. '/spthy.so'
  
  if not file_exists(spthy_path) and file_exists(config_spthy_path) then
    log("Found spthy.so in config dir, copying to parser dir", "info")
    execute_command("cp " .. config_spthy_path .. " " .. spthy_path)
  end
  
  if not file_exists(spthy_path) then
    log("ERROR: Spthy parser not found at: " .. spthy_path, "error")
    log("The spthy.so parser needs to be installed first.", "warning")
    return false
  else
    log("Found spthy.so parser at: " .. spthy_path, "success")
  end
  
  -- 4. Backup the original spthy.so
  local backup_path = spthy_path .. ".backup." .. os.time()
  log("Creating backup of spthy.so", "info")
  execute_command("cp " .. spthy_path .. " " .. backup_path)
  
  -- 5. Create tamarin.so with renamed symbol
  local tamarin_path = parser_dir .. '/tamarin.so'
  local config_tamarin_path = config_parser_dir .. '/tamarin.so'
  
  -- Remove any existing tamarin.so files
  if file_exists(tamarin_path) then
    log("Removing existing tamarin.so", "info")
    execute_command("rm " .. tamarin_path)
  end
  
  if file_exists(config_tamarin_path) then
    log("Removing existing tamarin.so from config dir", "info")
    execute_command("rm " .. config_tamarin_path)
  end
  
  -- Copy spthy.so to tamarin.so
  log("Creating copy of spthy.so as tamarin.so", "info")
  execute_command("cp " .. spthy_path .. " " .. tamarin_path)
  
  -- Rename the symbol in tamarin.so
  log("Renaming symbol tree_sitter_spthy to tree_sitter_tamarin", "info")
  local rename_result = execute_command(objcopy_cmd .. " --redefine-sym tree_sitter_spthy=tree_sitter_tamarin " .. tamarin_path)
  
  if rename_result and #rename_result > 0 then
    log("Warning during symbol renaming: " .. rename_result, "warning")
  else
    log("Symbol renamed successfully", "success")
  end
  
  -- Also create tamarin.so in config dir
  log("Creating tamarin.so in config dir", "info")
  execute_command("cp " .. tamarin_path .. " " .. config_tamarin_path)
  
  -- 6. Verify the new tamarin.so works
  log("Verifying tamarin.so parser", "info")
  
  -- Try to load the parser to verify
  local ok, err = pcall(function()
    return vim.treesitter.language.require_language("tamarin")
  end)
  
  if ok then
    log("Success! The parser can now be loaded with name 'tamarin'", "success")
    log("The TreeSitter 'symbol not found' error has been fixed.", "success")
  else
    log("Warning: Parser was created but loading still fails", "warning")
    log("Error: " .. tostring(err), "error")
    
    if tostring(err):find("symbol not found") then
      log("This is still a symbol issue. Check if the original parser uses a different symbol name.", "warning")
      
      -- Try detecting the actual symbol name in the original parser
      local nm_cmd = "nm"
      if command_exists("gnm") then nm_cmd = "gnm" end
      
      if command_exists(nm_cmd) then
        log("Attempting to find symbol name in original parser", "info")
        local symbols = execute_command(nm_cmd .. " " .. spthy_path .. " | grep tree_sitter")
        log("Found symbols: " .. symbols, "info")
        
        -- Extract and try alternative symbol names
        for symbol in symbols:gmatch("[%w_]+") do
          if symbol:find("tree_sitter") then
            log("Found potential symbol: " .. symbol, "info")
            
            -- Try with this symbol
            log("Trying to rename from " .. symbol .. " to tree_sitter_tamarin", "info")
            local alt_tamarin_path = tamarin_path .. ".alt"
            execute_command("cp " .. spthy_path .. " " .. alt_tamarin_path)
            execute_command(objcopy_cmd .. " --redefine-sym " .. symbol .. "=tree_sitter_tamarin " .. alt_tamarin_path)
            execute_command("mv " .. alt_tamarin_path .. " " .. tamarin_path)
            
            -- Try loading again
            local alt_ok = pcall(function()
              return vim.treesitter.language.require_language("tamarin")
            end)
            
            if alt_ok then
              log("Success with alternative symbol name: " .. symbol, "success")
              break
            end
          end
        end
      end
    end
    
    log("You may need to restart Neovim for the changes to take effect.", "warning")
  end
  
  -- 7. Set up language mapping
  local mapping_ok = pcall(function()
    vim.treesitter.language_add_aliases("spthy", { "tamarin" })
  end)
  
  if mapping_ok then
    log("Successfully added language mapping: spthy -> tamarin", "success")
  else
    log("Failed to add language mapping", "warning")
  end
  
  -- 8. Check if nvim-treesitter is available to set up parser config
  local has_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if has_parsers then
    -- Register Tamarin filetype to use Spthy parser
    if not parsers.get_parser_configs().tamarin then
      parsers.get_parser_configs().tamarin = {
        install_info = { 
          url = "none", -- No URL needed, we use our custom parser
          files = {},   -- No files needed
        },
        filetype = "tamarin",
        used_by = { "tamarin" },
        maintainers = { "kevinmorio" },
      }
      
      log("Registered tamarin in nvim-treesitter parser configs", "success")
    end
  else
    log("nvim-treesitter not available, skipping parser config registration", "warning")
  end
  
  log("Symbol renaming completed. Please restart Neovim for changes to take effect.", "success")
  return true
end

-- Run the main function
local success = rename_parser_symbol()

-- Exit with appropriate code
if success then
  vim.cmd("quit!")
else
  vim.cmd("cquit!")
end 