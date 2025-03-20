-- final_cleanup.lua
-- A script to verify and finalize the solution for Tamarin Spthy parser integration
-- Run with: nvim --headless -l final_cleanup.lua

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
  elseif level == "info" then
    color = colors.blue
  elseif level == "header" then
    color = colors.cyan
  end
  
  print(color .. msg .. colors.reset)
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

-- Create directory if it doesn't exist
local function ensure_directory(path)
  if vim.fn.isdirectory(path) ~= 1 then
    log("Creating directory: " .. path, "info")
    vim.fn.mkdir(path, "p")
    return true
  end
  return false
end

-- Verify the spthy parser
local function verify_spthy_parser()
  log("Verifying spthy parser", "header")
  
  local spthy_ok = pcall(function()
    return vim.treesitter.language.require_language("spthy")
  end)
  
  if spthy_ok then
    log("✓ spthy parser loads successfully", "success")
  else
    log("✗ Failed to load spthy parser", "error")
    return false
  end
  
  -- Try parsing a sample string
  local success = pcall(function() 
    local test_string = [[
theory Basic begin
builtins: hashing
end
]]
    local parser = vim.treesitter.get_string_parser(test_string, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    return root ~= nil
  end)
  
  if success then
    log("✓ Successfully parsed spthy content", "success")
  else
    log("✗ Failed to parse spthy content", "error")
    return false
  end
  
  return true
end

-- Verify filetype detection
local function verify_filetype_detection()
  log("Verifying filetype detection for .spthy files", "header")
  
  -- Ensure ftdetect directory exists
  local ftdetect_dir = vim.fn.stdpath('config') .. '/ftdetect'
  ensure_directory(ftdetect_dir)
  
  -- Check for tamarin.vim
  local ftdetect_path = ftdetect_dir .. '/tamarin.vim'
  if not file_exists(ftdetect_path) then
    log("Creating filetype detection file", "info")
    
    local ftdetect_content = [[
" Tamarin filetype detection
autocmd BufRead,BufNewFile *.spthy,*.sapic set filetype=spthy
]]
    
    local f = io.open(ftdetect_path, "w")
    f:write(ftdetect_content)
    f:close()
    
    log("✓ Created filetype detection file", "success")
  else
    log("✓ Filetype detection file exists", "success")
  end
  
  return true
end

-- Verify ftplugin setup
local function verify_ftplugin()
  log("Verifying ftplugin for spthy files", "header")
  
  -- Ensure ftplugin directory exists
  local ftplugin_dir = vim.fn.stdpath('config') .. '/ftplugin'
  ensure_directory(ftplugin_dir)
  
  -- Check for spthy.vim
  local ftplugin_path = ftplugin_dir .. '/spthy.vim'
  if not file_exists(ftplugin_path) then
    log("Creating ftplugin file for spthy", "info")
    
    local ftplugin_content = [[
" ftplugin for Tamarin spthy files
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Set up TreeSitter
if exists('g:loaded_nvim_treesitter')
  lua vim.treesitter.start(0, 'spthy')
endif

" Use spthy parser for tamarin files
let b:tamarin_treesitter_initialized = 1
]]
    
    local f = io.open(ftplugin_path, "w")
    f:write(ftplugin_content)
    f:close()
    
    log("✓ Created ftplugin file for spthy", "success")
  else
    log("✓ ftplugin file for spthy exists", "success")
  end
  
  return true
end

-- Verify init.lua setup
local function verify_init_lua()
  log("Verifying init.lua configuration", "header")
  
  local init_path = vim.fn.stdpath('config') .. '/init.lua'
  if not file_exists(init_path) then
    log("✗ init.lua not found", "error")
    return false
  end
  
  -- Read init.lua content
  local f = io.open(init_path, "r")
  local content = f:read("*a")
  f:close()
  
  -- Check for the filetype configuration
  local has_filetype_config = content:find("extension%s*=%s*{%s*spthy%s*=%s*\"spthy\"") ~= nil
  
  if not has_filetype_config then
    log("Adding filetype configuration to init.lua", "info")
    
    local init_append = [[

-- Set up filetype detection for Tamarin files using spthy parser
vim.filetype.add({
  extension = {
    spthy = "spthy",
    sapic = "spthy"
  },
})

-- Add autocommand to use spthy parser for tamarin files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "spthy",
  callback = function()
    pcall(function()
      vim.treesitter.start(0, "spthy")
    end)
  end,
})
]]
    
    f = io.open(init_path, "a")
    f:write(init_append)
    f:close()
    
    log("✓ Added filetype configuration to init.lua", "success")
  else
    log("✓ init.lua already contains filetype configuration", "success")
  end
  
  return true
end

-- Clean up old files
local function cleanup_old_files()
  log("Cleaning up old tamarin parser files", "header")
  
  -- Remove tamarin.so from parser directories if it exists
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  local tamarin_path = parser_dir .. '/tamarin.so'
  
  if file_exists(tamarin_path) then
    -- Check if it's a symlink to spthy.so
    local is_symlink = false
    local handle = io.popen("ls -la " .. tamarin_path .. " 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      is_symlink = result:find("spthy%.so") ~= nil
    end
    
    if not is_symlink then
      log("Removing tamarin.so parser file (it's not a symlink to spthy.so)", "info")
      os.remove(tamarin_path)
      log("✓ Removed tamarin.so", "success")
    else
      log("tamarin.so is a symlink to spthy.so, keeping it", "info")
    end
  end
  
  return true
end

-- Main function to run all verification and cleanup
local function main()
  log("=== Tamarin Spthy Parser Integration Cleanup ===", "header")
  
  -- Run all verification checks
  local spthy_parser_ok = verify_spthy_parser()
  local filetype_ok = verify_filetype_detection()
  local ftplugin_ok = verify_ftplugin()
  local init_ok = verify_init_lua()
  local cleanup_ok = cleanup_old_files()
  
  -- Overall status
  if spthy_parser_ok and filetype_ok and ftplugin_ok and init_ok and cleanup_ok then
    log("\n✓ All checks passed!", "success")
    log("The Tamarin Spthy parser integration is properly configured.", "success")
    log("Restart Neovim for all changes to take effect.", "success")
    vim.cmd("quit!")
  else
    log("\n✗ Some checks failed", "error")
    log("Please review the log for details and fix the issues manually.", "warning")
    vim.cmd("cquit!")
  end
end

-- Run the main function
main() 