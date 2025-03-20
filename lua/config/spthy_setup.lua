-- spthy_setup.lua
-- A streamlined setup for Tamarin Security Protocol Theory (.spthy) files
-- This replaces the multiple files that were previously used

local M = {}

-- Setup function
function M.setup()
  -- 1. Register filetype directly in Neovim
  vim.filetype.add({
    extension = {
      spthy = "spthy",
      sapic = "spthy"
    },
  })
  
  -- 2. Add parser directory to runtimepath to ensure parser is found
  local parser_path = vim.fn.stdpath("config") .. "/parser"
  vim.opt.runtimepath:append(parser_path)
  
  -- 3. Ensure the parser is available and properly registered
  pcall(function()
    -- Check if spthy parser exists in site directory
    local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
    local spthy_path = parser_dir .. '/spthy.so'
    
    -- Register language with TreeSitter if available
    if vim.fn.filereadable(spthy_path) == 1 and vim.treesitter and vim.treesitter.language then
      vim.treesitter.language.register('spthy', 'spthy')
    end
  end)

  -- 4. Setup highlights for spthy files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "spthy",
    callback = function()
      -- Make sure tamarin-colors is loaded first
      require("config.tamarin-colors").setup()
      
      -- Explicitly enable TreeSitter for this buffer
      if vim.fn.exists(':TSBufEnable') == 2 then
        vim.cmd('TSBufEnable highlight')
      elseif vim.treesitter and vim.treesitter.start then
        pcall(function()
          vim.treesitter.start(0, "spthy")
        end)
      end
    end,
  })
  
  -- 5. Register with nvim-treesitter if it's available
  pcall(function()
    local has_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
    if has_parsers and not parsers.get_parser_configs().spthy then
      parsers.get_parser_configs().spthy = {
        install_info = { 
          url = "https://github.com/tree-sitter/tree-sitter-spthy",
          files = {"src/parser.c"},
          branch = "main",
        },
        filetype = "spthy",
        maintainers = { "tree-sitter" },
      }
    end
  end)
  
  return true
end

return M 