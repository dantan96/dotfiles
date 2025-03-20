-- tamarin_parser_rename.lua
-- A script that copies the spthy.so parser to tamarin.so and renames the exported symbol
-- Run with: nvim --headless -l tamarin_parser_rename.lua

-- This requires the 'objcopy' tool which is part of GNU binutils
-- Mac users can install it with: brew install binutils
-- Linux users typically have it installed by default

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
  print_colored("yellow", "Running: " .. cmd)
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
  local _, return_code = vim.fn.system("which " .. cmd)
  return return_code == 0
end

-- Main logic
local function main()
  print_colored("blue", "=== Tamarin Parser Symbol Renaming Utility ===")
  
  -- 1. Check if required tools are available
  local has_objcopy = command_exists("objcopy") or command_exists("gobjcopy")
  if not has_objcopy then
    print_colored("red", "ERROR: objcopy tool not found")
    print_colored("yellow", "On macOS, install with: brew install binutils")
    print_colored("yellow", "On Linux, install with: sudo apt-get install binutils")
    vim.cmd("cquit!")
    return false
  end
  
  -- Determine objcopy command name (may be prefixed with 'g' on macOS from Homebrew)
  local objcopy_cmd = "objcopy"
  if command_exists("gobjcopy") then
    objcopy_cmd = "gobjcopy"
  end
  
  -- 2. Find the parser directory
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  
  print_colored("yellow", "Checking parser directory: " .. parser_dir)
  if vim.fn.isdirectory(parser_dir) ~= 1 then
    print_colored("red", "Parser directory does not exist: " .. parser_dir)
    print_colored("yellow", "Creating parser directory...")
    vim.fn.mkdir(parser_dir, "p")
  end
  
  -- 3. Check if spthy.so exists
  local spthy_path = parser_dir .. '/spthy.so'
  if not file_exists(spthy_path) then
    print_colored("red", "ERROR: Spthy parser not found at: " .. spthy_path)
    print_colored("yellow", "The spthy.so parser needs to be installed first.")
    vim.cmd("cquit!")
    return false
  else
    print_colored("green", "Found spthy.so parser at: " .. spthy_path)
  end
  
  -- 4. Backup the original spthy.so if needed
  local backup_path = spthy_path .. ".backup." .. os.time()
  print_colored("yellow", "Creating backup of spthy.so at: " .. backup_path)
  execute_command("cp " .. spthy_path .. " " .. backup_path)
  
  -- 5. Create a copy for tamarin.so
  local tamarin_path = parser_dir .. '/tamarin.so'
  print_colored("yellow", "Creating copy of spthy.so as tamarin.so")
  execute_command("cp " .. spthy_path .. " " .. tamarin_path)
  
  -- 6. Rename the symbol in tamarin.so
  print_colored("yellow", "Renaming symbol tree_sitter_spthy to tree_sitter_tamarin")
  local rename_result = execute_command(objcopy_cmd .. " --redefine-sym tree_sitter_spthy=tree_sitter_tamarin " .. tamarin_path)
  print_colored("yellow", rename_result)
  
  -- 7. Verify the new tamarin.so file works
  print_colored("yellow", "Verifying tamarin.so parser...")
  
  -- Try to load the parser to verify
  local ok, err = pcall(function()
    return vim.treesitter.language.require_language("tamarin")
  end)
  
  if ok then
    print_colored("green", "Success! The parser can now be loaded with name 'tamarin'")
    print_colored("green", "The TreeSitter 'symbol not found' error has been fixed.")
  else
    print_colored("red", "Warning: Parser was created but loading still fails:")
    print_colored("red", tostring(err))
    print_colored("yellow", "You need to restart Neovim for the changes to take effect.")
  end
  
  -- Exit
  print_colored("blue", "Fix completed! Please restart Neovim for changes to take effect.")
  vim.cmd("quit!")
  return true
end

-- Run the main function
main() 