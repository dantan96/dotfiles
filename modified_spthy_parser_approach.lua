-- modified_spthy_parser_approach.lua
-- A different approach to handle Tamarin files with the spthy parser
-- Run with: nvim --headless -l modified_spthy_parser_approach.lua

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
  local log_file = vim.fn.stdpath('cache') .. '/modified_approach.log'
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
    f:close()
  end
end

-- Execute shell command and return output
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

-- Create directory if it doesn't exist
local function ensure_directory(path)
  if vim.fn.isdirectory(path) ~= 1 then
    log("Creating directory: " .. path, "info")
    vim.fn.mkdir(path, "p")
    return true
  end
  return false
end

-- The main fix function
local function apply_modified_approach()
  log("=== Modified Tamarin Parser Approach ===", "info")
  
  -- 1. Instead of trying to alias tamarin to spthy, we'll use spthy directly
  log("Setting up direct spthy parser usage for tamarin files", "info")
  
  -- 2. Ensure we have the spthy parser
  local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
  local spthy_path = parser_dir .. '/spthy.so'
  
  if not file_exists(spthy_path) then
    log("ERROR: spthy.so parser not found at: " .. spthy_path, "error")
    return false
  else
    log("Found spthy.so parser at: " .. spthy_path, "success")
  end
  
  -- 3. Set up filetype detection for Tamarin files
  log("Setting up filetype detection for Tamarin files", "info")
  
  -- Ensure ftdetect directory exists
  local ftdetect_dir = vim.fn.stdpath('config') .. '/ftdetect'
  ensure_directory(ftdetect_dir)
  
  -- Create filetype detection file
  local ftdetect_path = ftdetect_dir .. '/tamarin.vim'
  local ftdetect_content = [[
" Tamarin filetype detection
autocmd BufRead,BufNewFile *.spthy,*.sapic set filetype=spthy
]]
  
  local f = io.open(ftdetect_path, "w")
  f:write(ftdetect_content)
  f:close()
  
  log("Created filetype detection file that maps *.spthy to spthy filetype", "success")
  
  -- 4. Create an ftplugin file
  local ftplugin_dir = vim.fn.stdpath('config') .. '/ftplugin'
  ensure_directory(ftplugin_dir)
  
  local ftplugin_path = ftplugin_dir .. '/spthy.vim'
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
  
  f = io.open(ftplugin_path, "w")
  f:write(ftplugin_content)
  f:close()
  
  log("Created ftplugin for spthy files", "success")
  
  -- 5. Update init.lua to use spthy parser for tamarin files
  local init_path = vim.fn.stdpath('config') .. '/init.lua'
  if file_exists(init_path) then
    local f = io.open(init_path, "r")
    local content = f:read("*a")
    f:close()
    
    -- Check if we need to append our configuration
    if not content:find("filetype%s*=%s*{%s*spthy%s*=%s*\"tamarin\"") then
      log("Updating init.lua to use spthy parser for tamarin files", "info")
      
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
      
      log("Updated init.lua configuration", "success")
    else
      log("init.lua already contains filetype configuration", "info")
    end
  else
    log("init.lua not found - creating new file", "warning")
    
    local init_content = [[
-- init.lua

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
    
    f = io.open(init_path, "w")
    f:write(init_content)
    f:close()
    
    log("Created new init.lua", "success")
  end
  
  -- 6. Verify the setup by testing with a sample file
  log("Testing direct spthy parser usage", "info")
  
  -- Test if we can parse a sample spthy file
  local test_string = [[
theory Basic begin
builtins: hashing
end
]]
  
  local success = pcall(function() 
    local parser = vim.treesitter.get_string_parser(test_string, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    return root ~= nil
  end)
  
  if success then
    log("Successfully parsed spthy content!", "success")
    log("Modified approach applied successfully", "success")
    return true
  else
    log("Failed to parse spthy content", "error")
    log("Modified approach failed to resolve the issue", "error")
    return false
  end
end

-- Run the modified approach
local success = apply_modified_approach()

-- Exit with appropriate code
if success then
  log("Fix completed successfully. Please restart Neovim for changes to take effect.", "success")
  vim.cmd("quit!")
else
  log("Fix failed. See log for details.", "error")
  vim.cmd("cquit!")
end 