-- tamarin_setup.lua
-- A comprehensive setup for Tamarin Spthy files in Neovim
-- Place this in your Neovim config directory and require it from init.lua

local M = {}

-- Setup function
function M.setup(opts)
  opts = opts or {}
  local silent = opts.silent or false
  local log_file = vim.fn.stdpath('cache') .. '/tamarin_setup.log'
  
  -- Helper function to log messages
  local function log(msg, notify)
    local f = io.open(log_file, "a")
    if f then
      f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
      f:close()
    end
    -- Only notify if explicitly asked or not in silent mode
    if notify or (not silent and notify ~= false) then
      vim.notify(msg)
    end
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
        log("Created filetype detection file", false)
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
    log("Registered Tamarin filetypes", false)
  end
  
  -- Try to set up TreeSitter integration if available
  local function setup_treesitter()
    -- Check if spthy parser exists
    local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
    local spthy_path = parser_dir .. '/spthy.so'
    local spthy_exists = vim.fn.filereadable(spthy_path) == 1
    
    if not spthy_exists then
      log("Spthy TreeSitter parser not found at: " .. spthy_path, false)
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
    
    log("Set up TreeSitter integration for spthy files", false)
    return true
  end
  
  -- Safely handle and suppress expected TreeSitter errors
  local function suppress_treesitter_errors()
    -- Override the require_language function to silently handle expected errors
    local old_require_language = vim.treesitter.language.require_language
    vim.treesitter.language.require_language = function(lang, path)
      -- If it's the problematic tamarin parser, log silently and return false
      if lang == "tamarin" then
        log("Silently handling tamarin parser load request", false)
        return false
      end
      -- Otherwise call the original function
      return old_require_language(lang, path)
    end
  end
  
  -- Main setup
  ensure_dirs()
  setup_ftdetect()
  register_filetype()
  suppress_treesitter_errors()
  local ts_ok = setup_treesitter()
  
  if ts_ok then
    log("Tamarin setup complete with TreeSitter support", false)
  else
    log("Tamarin setup complete with fallback syntax highlighting", false)
  end
  
  return true
end

return M 