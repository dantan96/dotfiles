-- treesitter_parser_map.lua
-- Configure nvim-treesitter for Spthy files

local M = {}

function M.setup()
  -- Check if nvim-treesitter is available
  local has_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if not has_parsers then
    vim.notify("nvim-treesitter is not available, skipping parser setup", vim.log.levels.WARN)
    return false
  end
  
  -- Make sure the spthy parser is properly registered
  if not parsers.get_parser_configs().spthy then
    parsers.get_parser_configs().spthy = {
      install_info = { 
        url = "https://github.com/kevinmorio/tree-sitter-spthy",
        files = {"src/parser.c"},
        branch = "main",
      },
      filetype = "spthy",
      maintainers = { "kevinmorio" },
    }
  end
  
  return true
end

return M
