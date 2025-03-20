-- TreeSitter Diagnostic and Fix Script
-- This script diagnoses and fixes TreeSitter issues for spthy files

-- Utility functions
local function log(message, level)
  level = level or "INFO"
  print("[" .. level .. "] " .. message)
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function dir_exists(path)
  return vim.fn.isdirectory(path) == 1
end

local function run_command(cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Check TreeSitter installation
local function check_treesitter()
  log("Checking TreeSitter installation...")
  
  local has_treesitter = pcall(require, "nvim-treesitter")
  if not has_treesitter then
    log("nvim-treesitter is not installed or not found in runtimepath", "ERROR")
    return false
  end
  
  log("nvim-treesitter is installed ✓")
  return true
end

-- Check for parser files
local function check_parser_files()
  log("Checking parser files...")
  
  local config_parser_dir = vim.fn.stdpath('config') .. '/parser'
  local site_parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  
  -- Check directories exist
  if not dir_exists(site_parser_dir) then
    log("TreeSitter parser directory does not exist: " .. site_parser_dir, "ERROR")
    return false
  end
  
  if not dir_exists(config_parser_dir) then
    log("Config parser directory does not exist: " .. config_parser_dir)
    vim.fn.mkdir(config_parser_dir, "p")
    log("Created config parser directory ✓")
  end
  
  -- Check for spthy.so parser
  local site_spthy_path = site_parser_dir .. '/spthy.so'
  local config_spthy_path = config_parser_dir .. '/spthy.so'
  
  if not file_exists(site_spthy_path) then
    log("spthy.so not found in site parser directory: " .. site_spthy_path, "ERROR")
    return false
  end
  
  log("Found spthy.so in site parser directory ✓")
  
  -- Verify parser binary
  log("Checking parser binary symbols...")
  local symbols = run_command("nm -gU " .. vim.fn.shellescape(site_spthy_path) .. " | grep tree_sitter")
  if not symbols:match("tree_sitter_spthy") then
    log("tree_sitter_spthy symbol not found in parser binary", "ERROR")
    log("Symbols found: " .. symbols)
    return false
  end
  
  log("tree_sitter_spthy symbol found in parser binary ✓")
  
  -- Create symlink if needed
  if not file_exists(config_spthy_path) then
    log("Creating symlink for spthy.so in config parser directory...")
    local result = os.execute("ln -sf " .. vim.fn.shellescape(site_spthy_path) .. " " .. vim.fn.shellescape(config_spthy_path))
    if result then
      log("Created symlink for spthy.so ✓")
    else
      log("Failed to create symlink", "ERROR")
    end
  end
  
  return true
end

-- Verify parser registration
local function check_parser_registration()
  log("Checking parser registration...")
  
  -- Add parser directory to runtimepath
  local parser_path = vim.fn.stdpath("config") .. "/parser"
  vim.opt.runtimepath:append(parser_path)
  
  -- Check if spthy filetype is recognized
  local ft = vim.filetype.match({ filename = "test.spthy" })
  log("Detected filetype for .spthy: " .. (ft or "none"))
  
  if ft ~= "spthy" then
    log("Filetype detection for .spthy files is not working correctly", "ERROR")
    return false
  end
  
  -- Check if spthy parser is registered
  local has_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if not has_parsers then
    log("nvim-treesitter.parsers module not found", "ERROR")
    return false
  end
  
  if parsers.get_parser_configs().spthy then
    log("spthy parser is registered in nvim-treesitter ✓")
  else
    log("spthy parser is not registered in nvim-treesitter", "ERROR")
    log("Registering spthy parser...")
    parsers.get_parser_configs().spthy = {
      install_info = {
        url = "https://github.com/tree-sitter/tree-sitter-spthy",
        files = {"src/parser.c"},
        branch = "main",
      },
      filetype = "spthy",
    }
    log("Registered spthy parser ✓")
  end
  
  -- Test loading the parser
  log("Testing parser loading...")
  
  local spthy_ok = pcall(function()
    return vim.treesitter.language.require_language("spthy")
  end)
  
  if not spthy_ok then
    log("Failed to load spthy parser", "ERROR")
    
    -- Try to register the language manually
    log("Attempting manual language registration...")
    pcall(function()
      vim.treesitter.language.register('spthy', 'spthy')
    end)
    
    -- Test again
    spthy_ok = pcall(function()
      return vim.treesitter.language.require_language("spthy")
    end)
    
    if not spthy_ok then
      log("Manual registration failed", "ERROR")
      return false
    end
  end
  
  log("spthy parser loads successfully ✓")
  return true
end

-- Test parser with a sample file
local function test_parser_with_file()
  log("Testing parser with a sample file...")
  
  -- Create a test buffer
  local test_content = [[
theory Test
begin

builtins: symmetric-encryption, hashing

rule Hello:
  [ ]
  -->
  [ Out('hello') ]

end
]]
  
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(test_content, "\n"))
  vim.api.nvim_buf_set_option(bufnr, "filetype", "spthy")
  vim.api.nvim_set_current_buf(bufnr)
  
  -- Enable TreeSitter
  vim.cmd("syntax on")
  if vim.fn.exists(":TSBufEnable") == 2 then
    vim.cmd("TSBufEnable highlight")
  end
  
  -- Wait for highlighting to be applied
  vim.cmd("sleep 300m")
  
  -- Check if TreeSitter highlighter is active
  local active = false
  if vim.treesitter and vim.treesitter.highlighter then
    active = vim.treesitter.highlighter.active[bufnr] ~= nil
  end
  
  if active then
    log("TreeSitter highlighting is active for the test buffer ✓")
  else
    log("TreeSitter highlighting is NOT active for the test buffer", "ERROR")
    
    -- Check if a parser was created
    local parser_ok = pcall(function() 
      return vim.treesitter.get_parser(bufnr)
    end)
    
    if parser_ok then
      log("Parser created but highlighter not active", "WARN")
    else
      log("Failed to create parser for the buffer", "ERROR")
    end
    
    return false
  end
  
  -- Check TreeSitter captures
  local has_captures = false
  pcall(function()
    local captures = vim.treesitter.get_captures_at_pos(bufnr, 0, 0)
    has_captures = #captures > 0
  end)
  
  if has_captures then
    log("TreeSitter captures found in test buffer ✓")
  else
    log("No TreeSitter captures found in test buffer", "WARN")
  end
  
  return active
end

-- Fix configuration issues
local function fix_configuration()
  log("Fixing configuration issues...")
  
  -- Update treesitter_parser_map.lua if it exists
  local parser_map_path = vim.fn.stdpath('config') .. '/lua/config/treesitter_parser_map.lua'
  if file_exists(parser_map_path) then
    log("Updating treesitter_parser_map.lua...")
    
    -- Read current content
    local lines = vim.fn.readfile(parser_map_path)
    local new_lines = {}
    local found_setup = false
    
    -- Update the setup function
    for _, line in ipairs(lines) do
      if line:match("function%s+M%.setup") then
        found_setup = true
        table.insert(new_lines, line)
      elseif found_setup and line:match("return%s+true") then
        -- Before returning, make sure we register the spthy parser explicitly
        table.insert(new_lines, [[
  -- Ensure direct parser loading
  pcall(function()
    vim.treesitter.language.register('spthy', 'spthy')
  end)
  
  -- Test spthy parser loading
  local spthy_ok = pcall(function()
    return vim.treesitter.language.require_language("spthy")
  end)
  
  if not spthy_ok then
    vim.notify("Failed to load spthy parser", vim.log.levels.WARN)
  end]])
        table.insert(new_lines, line)
        found_setup = false
      else
        table.insert(new_lines, line)
      end
    end
    
    -- Write back the file
    vim.fn.writefile(new_lines, parser_map_path)
    log("Updated treesitter_parser_map.lua ✓")
  end
  
  -- Update plugins/treesitter.lua if it exists
  local ts_plugin_path = vim.fn.stdpath('config') .. '/lua/plugins/treesitter.lua'
  if file_exists(ts_plugin_path) then
    log("Updating plugins/treesitter.lua...")
    
    -- Read current content
    local lines = vim.fn.readfile(ts_plugin_path)
    local new_lines = {}
    local found_config = false
    
    -- Update the config function
    for _, line in ipairs(lines) do
      if line:match("config%s*=%s*function") then
        found_config = true
        table.insert(new_lines, line)
      elseif found_config and line:match("end,") then
        -- Before ending, make sure we register spthy explicitly
        table.insert(new_lines, [[
    -- Explicitly register spthy parser with the correct location
    local parser_path = vim.fn.stdpath("config") .. "/parser"
    vim.opt.runtimepath:append(parser_path)
    
    -- Register the spthy parser if it exists
    local spthy_parser_path = parser_path .. "/spthy.so"
    if vim.fn.filereadable(spthy_parser_path) == 1 then
      -- Direct language registration
      pcall(function()
        vim.treesitter.language.register('spthy', 'spthy')
      end)
      
      -- Also register using the add method
      pcall(vim.treesitter.language.add, 'spthy', {
        path = spthy_parser_path
      })
    end]])
        table.insert(new_lines, line)
        found_config = false
      else
        table.insert(new_lines, line)
      end
    end
    
    -- Write back the file
    vim.fn.writefile(new_lines, ts_plugin_path)
    log("Updated plugins/treesitter.lua ✓")
  end
  
  -- Update init.lua to ensure early parser registration
  local init_path = vim.fn.stdpath('config') .. '/init.lua'
  if file_exists(init_path) then
    log("Updating init.lua for early parser registration...")
    
    -- Read current content
    local lines = vim.fn.readfile(init_path)
    local new_lines = {}
    local added_parser_reg = false
    
    -- Find appropriate place to add parser registration
    for i, line in ipairs(lines) do
      table.insert(new_lines, line)
      
      -- After setting up filetype detection but before loading plugins
      if line:match("Registered Tamarin filetype") and not added_parser_reg then
        table.insert(new_lines, [[
-- Ensure spthy TreeSitter parser is properly registered
pcall(function()
  local parser_path = vim.fn.stdpath("config") .. "/parser"
  vim.opt.runtimepath:append(parser_path)
  
  -- Register spthy language directly if TreeSitter is available
  if vim.treesitter and vim.treesitter.language then
    vim.treesitter.language.register('spthy', 'spthy')
  end
end)]])
        added_parser_reg = true
      end
    end
    
    -- Write back the file
    vim.fn.writefile(new_lines, init_path)
    log("Updated init.lua ✓")
  end
  
  return true
end

-- Main function
local function main()
  log("=== TreeSitter Diagnostic and Fix for spthy files ===")
  
  local ts_ok = check_treesitter()
  if not ts_ok then
    log("TreeSitter is not properly installed. Fix this first.", "ERROR")
    return false
  end
  
  local files_ok = check_parser_files()
  if not files_ok then
    log("Parser files are not correctly set up. Fix this first.", "ERROR")
    return false
  end
  
  local reg_ok = check_parser_registration()
  if not reg_ok then
    log("Parser registration failed. Attempting to fix configuration...", "WARN")
    fix_configuration()
  else
    log("Parser registration looks good! ✓")
  end
  
  local test_ok = test_parser_with_file()
  if test_ok then
    log("TreeSitter is working for spthy files! ✓")
  else
    log("TreeSitter still not working properly for spthy files", "ERROR")
    log("Attempting final fixes...")
    fix_configuration()
    log("Please restart Neovim and try again")
  end
  
  log("=== Diagnostic complete ===")
  return test_ok
end

-- Run the main function
local success = main()

-- Final message
if success then
  log("\nTreeSitter should now be working for spthy files!")
  log("To verify, open a .spthy file and run: :TSBufInfo")
else
  log("\nTreeSitter issues could not be fully resolved automatically.")
  log("Manual intervention may be needed. Check the logs above for details.")
end 