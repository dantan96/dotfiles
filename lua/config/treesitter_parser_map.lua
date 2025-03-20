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
    
    vim.notify("Registered Tamarin filetype to use Spthy parser", vim.log.levels.INFO)
  end
  
  -- Register alias for the parser
  local has_ts_config, ts_config = pcall(require, "nvim-treesitter.configs")
  if has_ts_config then
    -- Try to add parser alias
    pcall(function()
      -- Register spthy parser to handle tamarin filetype
      vim.treesitter.language_add_aliases("spthy", { "tamarin" })
    end)
  end
  
  return true
end

return M 