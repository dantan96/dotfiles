-- fix_tamarin_parser.lua
-- A standalone script that fixes the TreeSitter parser loading error for Tamarin
-- Run with: nvim --headless -l fix_tamarin_parser.lua

-- Print function with colors
local function print_colored(color, message)
  local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    reset = "\27[0m",
  }
  print(colors[color] .. message .. colors.reset)
end

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

-- Create the symlink
local function create_parser_symlink(spthy_path, tamarin_path)
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- Windows uses copy instead of symlink for compatibility
    execute_command("copy " .. spthy_path .. " " .. tamarin_path)
    print_colored("green", "Copied spthy.so to tamarin.so")
  else
    -- Unix uses symlink
    execute_command("ln -sf " .. spthy_path .. " " .. tamarin_path)
    print_colored("green", "Created symlink from tamarin.so to spthy.so")
  end
end

-- Main logic
local function main()
  print_colored("blue", "=== Tamarin Parser Fix Utility ===")
  
  -- 1. First find the parser directory
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  
  print_colored("yellow", "Checking parser directory: " .. parser_dir)
  if vim.fn.isdirectory(parser_dir) ~= 1 then
    print_colored("red", "Parser directory does not exist: " .. parser_dir)
    print_colored("yellow", "Creating parser directory...")
    vim.fn.mkdir(parser_dir, "p")
  end
  
  -- 2. Check if spthy.so exists
  local spthy_path = parser_dir .. '/spthy.so'
  if not file_exists(spthy_path) then
    print_colored("red", "ERROR: Spthy parser not found at: " .. spthy_path)
    print_colored("yellow", "The spthy.so parser needs to be installed first.")
    print_colored("yellow", "Please compile it from the tree-sitter-spthy repository")
    print_colored("yellow", "and place it in: " .. parser_dir)
    vim.cmd("cquit!")
    return false
  else
    print_colored("green", "Found spthy.so parser at: " .. spthy_path)
  end
  
  -- 3. Check if tamarin.so already exists
  local tamarin_path = parser_dir .. '/tamarin.so'
  
  if file_exists(tamarin_path) then
    -- Check if it's already a symlink to spthy.so
    local result = execute_command("ls -la " .. tamarin_path)
    if result:find("spthy%.so") then
      print_colored("green", "Tamarin parser symlink already exists")
    else
      -- File exists but is not a symlink to spthy.so - back it up
      local backup_path = tamarin_path .. ".backup." .. os.time()
      
      print_colored("yellow", "Existing tamarin.so found but is not a symlink to spthy.so")
      print_colored("yellow", "Creating backup at: " .. backup_path)
      
      execute_command("mv " .. tamarin_path .. " " .. backup_path)
      
      -- Now create the symlink
      create_parser_symlink(spthy_path, tamarin_path)
    end
  else
    print_colored("yellow", "No tamarin.so found, creating symlink...")
    create_parser_symlink(spthy_path, tamarin_path)
  end
  
  -- 4. Verify fix
  if file_exists(tamarin_path) then
    print_colored("green", "Successfully created Tamarin parser mapping")
    
    -- Try to load the parser to verify
    local ok, err = pcall(function()
      return vim.treesitter.language.require_language("tamarin")
    end)
    
    if ok then
      print_colored("green", "Verified: Parser 'tamarin' can now be loaded successfully!")
      print_colored("green", "The TreeSitter 'symbol not found' error has been fixed.")
    else
      print_colored("red", "Warning: Parser symlink created but loading still fails:")
      print_colored("red", tostring(err))
      print_colored("yellow", "This might require a Neovim restart to take effect.")
    end
  else
    print_colored("red", "Failed to create tamarin.so")
    vim.cmd("cquit!")
    return false
  end
  
  -- Exit
  print_colored("blue", "Fix completed successfully! Restart Neovim for changes to take effect.")
  vim.cmd("quit!")
  return true
end

-- Run the main function
main() 