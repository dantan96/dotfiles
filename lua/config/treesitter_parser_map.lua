-- treesitter_parser_map.lua
-- Configure nvim-treesitter to use the right parser for Tamarin files

local M = {}

-- Log message with timestamps
local function log(msg, level)
  level = level or vim.log.levels.INFO
  
  local log_file = vim.fn.stdpath('cache') .. '/treesitter_parser_map.log'
  local f = io.open(log_file, "a")
  if f then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local level_str = level == vim.log.levels.ERROR and "ERROR" or 
                     level == vim.log.levels.WARN and "WARN" or "INFO"
    
    f:write(string.format("[%s] [%s] %s\n", timestamp, level_str, msg))
    f:close()
  end
  
  -- Also notify the user
  if level >= vim.log.levels.WARN then
    vim.notify(msg, level)
  end
end

function M.setup()
  log("Setting up TreeSitter parser mapping for Tamarin")
  
  -- Check if nvim-treesitter is available
  local has_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if not has_parsers then
    vim.notify("nvim-treesitter is not available, skipping parser mapping setup", vim.log.levels.WARN)
    return false
  end
  
  -- First directly add the language alias
  pcall(function()
    vim.treesitter.language_add_aliases("spthy", { "tamarin" })
    log("Added language alias: spthy -> tamarin")
  end)
  
  -- Register Tamarin filetype to use Spthy parser
  if not parsers.get_parser_configs().tamarin then
    parsers.get_parser_configs().tamarin = {
      install_info = { 
        url = "none", -- No URL needed, we use the existing spthy parser
        files = {},   -- No files needed
      },
      filetype = "tamarin",  -- Explicit mapping
      used_by = { "tamarin" },
      maintainers = { "kevinmorio" },
    }
    
    log("Registered Tamarin filetype to use Spthy parser")
  end
  
  -- Try to verify if the parsers are properly loaded and mapped
  local spthy_ok = pcall(vim.treesitter.language.inspect, "spthy")
  local tamarin_ok = pcall(vim.treesitter.language.inspect, "tamarin")
  
  if not spthy_ok then
    log("Warning: Spthy parser inspection failed", vim.log.levels.WARN)
  end
  
  if not tamarin_ok then
    log("Warning: Tamarin parser inspection failed", vim.log.levels.WARN)
    
    -- Try direct loading
    local load_ok, load_err = pcall(function()
      return vim.treesitter.language.require_language("tamarin")
    end)
    
    if not load_ok then
      log("Error loading tamarin parser: " .. tostring(load_err), vim.log.levels.ERROR)
      
      -- Check for common errors
      if tostring(load_err):find("symbol not found") then
        log("Symbol not found error detected. This might be fixed by running 'fix_tamarin_parser.lua'", vim.log.levels.WARN)
      elseif tostring(load_err):find("no such file") then
        log("Parser file not found. Run 'fix_tamarin_parser.lua' to create proper symlinks", vim.log.levels.WARN)
      end
    end
  end
  
  -- Register for filetype events
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "tamarin",
    callback = function()
      -- Try to activate treesitter for this buffer
      local bufnr = vim.api.nvim_get_current_buf()
      pcall(function()
        vim.treesitter.start(bufnr, "tamarin")
      end)
    end
  })
  
  return spthy_ok or tamarin_ok
end

return M 