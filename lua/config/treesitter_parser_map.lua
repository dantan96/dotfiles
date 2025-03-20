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
