-- fix_tamarin_neovim_only.lua
-- A script to fix Tamarin TreeSitter integration using Neovim's language mapping
-- Run with: nvim --headless -l fix_tamarin_neovim_only.lua

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
  local log_file = vim.fn.stdpath('cache') .. '/tamarin_neovim_fix.log'
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

-- Main function to fix tamarin TreeSitter integration
local function fix_tamarin_integration()
  log("=== Tamarin TreeSitter Integration Fix (Neovim Only) ===", "info")
  
  local success = true
  
  -- 1. Set up language_add_aliases for 'spthy' to handle 'tamarin'
  log("Setting up language aliases", "info")
  
  local alias_added = pcall(function()
    vim.treesitter.language_add_aliases("spthy", { "tamarin" })
  end)
  
  if alias_added then
    log("Successfully added language alias: spthy -> tamarin", "success")
  else
    log("Failed to add language alias", "error")
    success = false
  end
  
  -- 2. Modify init.lua to ensure the alias is added on startup
  local init_path = vim.fn.stdpath('config') .. '/init.lua'
  if file_exists(init_path) then
    log("Checking init.lua for language alias setup", "info")
    
    local f = io.open(init_path, "r")
    local content = f:read("*a")
    f:close()
    
    -- Check if the alias setup is already in init.lua
    if not content:find("language_add_aliases%s*%(%s*['\"]spthy['\"]%s*,%s*{%s*['\"]tamarin['\"]%s*}") then
      log("Adding language alias setup to init.lua", "info")
      
      -- Prepare the code to add
      local alias_code = [[

-- Add language alias mapping from spthy to tamarin (for TreeSitter)
pcall(function()
  vim.treesitter.language_add_aliases("spthy", { "tamarin" })
end)
]]
      
      -- Append to init.lua
      f = io.open(init_path, "a")
      f:write(alias_code)
      f:close()
      
      log("Added language alias setup to init.lua", "success")
    else
      log("Language alias setup already exists in init.lua", "info")
    end
  else
    log("init.lua not found at: " .. init_path, "warning")
  end
  
  -- 3. Check if nvim-treesitter.parsers is available
  local parsers_available, parsers = pcall(require, "nvim-treesitter.parsers")
  if parsers_available then
    log("nvim-treesitter is available, registering parser config", "info")
    
    -- Register Tamarin filetype to use Spthy parser
    if not parsers.get_parser_configs().tamarin then
      parsers.get_parser_configs().tamarin = {
        install_info = { 
          url = "none", -- No URL needed, we use the existing spthy parser
          files = {},   -- No files needed
        },
        filetype = "tamarin",
        used_by = { "tamarin" },
      }
      
      log("Successfully registered tamarin in parser configs", "success")
    else
      log("tamarin already registered in parser configs", "info")
    end
  else
    log("nvim-treesitter.parsers not available", "warning")
    
    -- Create/update the parser mapping file
    local parser_map_path = vim.fn.stdpath('config') .. '/lua/config/treesitter_parser_map.lua'
    local parser_map_dir = vim.fn.fnamemodify(parser_map_path, ":h")
    
    if vim.fn.isdirectory(parser_map_dir) ~= 1 then
      log("Creating directory: " .. parser_map_dir, "info")
      vim.fn.mkdir(parser_map_dir, "p")
    end
    
    log("Updating treesitter_parser_map.lua", "info")
    
    local parser_map_content = [[
-- treesitter_parser_map.lua
-- Configure nvim-treesitter to use the right parser for Tamarin files

local M = {}

function M.setup()
  -- Check if nvim-treesitter is available
  local has_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if not has_parsers then
    vim.notify("nvim-treesitter is not available, skipping parser mapping setup", vim.log.levels.WARN)
    return false
  end
  
  -- First directly add the language alias
  pcall(function()
    vim.treesitter.language_add_aliases("spthy", { "tamarin" })
  end)
  
  -- Register Tamarin filetype to use Spthy parser
  if not parsers.get_parser_configs().tamarin then
    parsers.get_parser_configs().tamarin = {
      install_info = { 
        url = "none",
        files = {},
      },
      filetype = "tamarin",
      used_by = { "tamarin" },
      maintainers = { "kevinmorio" },
    }
  end
  
  return true
end

return M
]]
    
    local f = io.open(parser_map_path, "w")
    f:write(parser_map_content)
    f:close()
    
    log("Updated treesitter_parser_map.lua", "success")
  end
  
  -- 4. Register filetype detection
  log("Setting up filetype detection for Tamarin files", "info")
  
  -- Add filetype detection to ftdetect directory
  local ftdetect_dir = vim.fn.stdpath('config') .. '/ftdetect'
  if vim.fn.isdirectory(ftdetect_dir) ~= 1 then
    log("Creating ftdetect directory", "info")
    vim.fn.mkdir(ftdetect_dir, "p")
  end
  
  local ftdetect_path = ftdetect_dir .. '/tamarin.vim'
  local ftdetect_content = [[
" Tamarin filetype detection
autocmd BufRead,BufNewFile *.spthy,*.sapic set filetype=tamarin
]]
  
  local f = io.open(ftdetect_path, "w")
  f:write(ftdetect_content)
  f:close()
  
  log("Created filetype detection file", "success")
  
  -- 5. Update the FileType autocommand for tamarin
  local autocmd_setup = pcall(function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "tamarin",
      callback = function()
        -- Try to activate treesitter for this buffer
        local bufnr = vim.api.nvim_get_current_buf()
        pcall(function()
          vim.treesitter.start(bufnr, "spthy")
        end)
      end
    })
  end)
  
  if autocmd_setup then
    log("Registered FileType autocommand for tamarin files", "success")
  else
    log("Failed to register FileType autocommand", "warning")
  end
  
  -- 6. Add autoload script
  local autoload_dir = vim.fn.stdpath('config') .. '/autoload'
  if vim.fn.isdirectory(autoload_dir) ~= 1 then
    log("Creating autoload directory", "info")
    vim.fn.mkdir(autoload_dir, "p")
  end
  
  local autoload_path = autoload_dir .. '/tamarin.vim'
  local autoload_content = [[
" tamarin.vim - Autoload functions for Tamarin integration

" Set up TreeSitter for tamarin files
function! tamarin#setup_treesitter() abort
  if exists('g:loaded_nvim_treesitter')
    lua require'nvim-treesitter.parsers'.get_parser_configs().tamarin = { install_info = { url = "none", files = {} }, filetype = "tamarin", used_by = { "tamarin" } }
    lua vim.treesitter.language_add_aliases("spthy", { "tamarin" })
  endif
endfunction

" Ensure this runs when Tamarin filetype is loaded
augroup TamarinSetup
  autocmd!
  autocmd FileType tamarin call tamarin#setup_treesitter()
augroup END
]]
  
  local f = io.open(autoload_path, "w")
  f:write(autoload_content)
  f:close()
  
  log("Created autoload script for Tamarin", "success")
  
  -- 7. Final verification
  log("Performing final verification", "info")
  
  -- Try to load the spthy parser
  local spthy_ok = pcall(function() return vim.treesitter.language.require_language("spthy") end)
  
  if spthy_ok then
    log("Successfully loaded spthy parser", "success")
  else
    log("Failed to load spthy parser", "error")
    success = false
  end
  
  -- Try to load the tamarin parser using our alias
  local tamarin_ok = pcall(function() 
    return vim.treesitter.language.require_language("tamarin")
  end)
  
  if tamarin_ok then
    log("Successfully loaded tamarin parser through alias", "success")
  else
    log("Failed to load tamarin parser through alias", "warning")
    log("This might require a Neovim restart to take effect", "warning")
  end
  
  -- Create a test buffer with tamarin content
  local test_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(test_buffer, "filetype", "tamarin")
  
  -- Try to set up TreeSitter for this buffer
  pcall(function()
    vim.treesitter.start(test_buffer, "spthy")
  end)
  
  -- Clean up
  vim.api.nvim_buf_delete(test_buffer, {force=true})
  
  if success then
    log("Fix completed successfully! Please restart Neovim for changes to take effect.", "success")
  else
    log("Fix completed with some issues. Please restart Neovim and check again.", "warning")
  end
  
  return success
end

-- Run the fix
local success = fix_tamarin_integration()

-- Exit with appropriate code
if success then
  vim.cmd("quit!")
else
  vim.cmd("cquit!")
end 