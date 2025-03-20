-- tamarin_setup.lua
-- A comprehensive setup for Tamarin Spthy files in Neovim
-- Place this in your Neovim config directory and require it from init.lua

local M = {}

-- Setup function
function M.setup()
  local log_file = vim.fn.stdpath('cache') .. '/tamarin_setup.log'
  
  -- Helper function to log messages
  local function log(msg)
    local f = io.open(log_file, "a")
    if f then
      f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
      f:close()
    end
    vim.notify(msg)
  end
  
  -- Ensure necessary directories exist
  local function ensure_dirs()
    local dirs = {
      vim.fn.stdpath('config') .. '/ftdetect',
      vim.fn.stdpath('config') .. '/ftplugin',
      vim.fn.stdpath('config') .. '/syntax',
    }
    
    for _, dir in ipairs(dirs) do
      if vim.fn.isdirectory(dir) ~= 1 then
        vim.fn.mkdir(dir, "p")
      end
    end
  end
  
  -- Create filetype detection file if it doesn't exist
  local function setup_ftdetect()
    local path = vim.fn.stdpath('config') .. '/ftdetect/tamarin.vim'
    if vim.fn.filereadable(path) ~= 1 then
      local content = [[
" Tamarin filetype detection
autocmd BufRead,BufNewFile *.spthy,*.sapic set filetype=spthy
]]
      local f = io.open(path, "w")
      if f then
        f:write(content)
        f:close()
        log("Created filetype detection file")
      end
    end
  end
  
  -- Register filetype in Neovim directly
  local function register_filetype()
    vim.filetype.add({
      extension = {
        spthy = "spthy",
        sapic = "spthy"
      },
    })
    log("Registered Tamarin filetypes")
  end
  
  -- Try to set up TreeSitter integration if available
  local function setup_treesitter()
    -- Check if spthy parser exists
    local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
    local spthy_path = parser_dir .. '/spthy.so'
    local spthy_exists = vim.fn.filereadable(spthy_path) == 1
    
    if not spthy_exists then
      log("Spthy TreeSitter parser not found at: " .. spthy_path)
      return false
    end
    
    -- Add autocommand to activate TreeSitter for spthy files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "spthy",
      callback = function()
        local success = pcall(function()
          vim.treesitter.start(0, "spthy")
        end)
        
        if not success then
          -- Fallback to standard syntax highlighting
          vim.cmd("syntax enable")
        end
      end,
    })
    
    log("Set up TreeSitter integration for spthy files")
    return true
  end
  
  -- Main setup
  ensure_dirs()
  setup_ftdetect()
  register_filetype()
  local ts_ok = setup_treesitter()
  
  if ts_ok then
    log("Tamarin setup complete with TreeSitter support")
  else
    log("Tamarin setup complete with fallback syntax highlighting")
  end
  
  return true
end

return M 