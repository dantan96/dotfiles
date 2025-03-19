-- Tamarin initialization module
-- Main module for setting up Tamarin syntax highlighting with TreeSitter

local M = {}

-- Setup function - called from init.lua
function M.setup()
  -- Load the parser loader
  local parser_loader = require('tamarin.parser_loader')
  
  -- Set up filetype detection
  vim.filetype.add({
    extension = {
      spthy = "tamarin",
      sapic = "tamarin"
    },
  })
  
  -- Create autocmd to load parsers when needed
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.spthy", "*.sapic" },
    callback = function()
      -- Try to load parsers
      local result = parser_loader.ensure_parsers_loaded()
      
      -- Try to start TreeSitter highlighting
      local bufnr = vim.api.nvim_get_current_buf()
      local success = parser_loader.start_highlighting(bufnr)
      
      -- If highlighting failed, fall back to config.tamarin-highlights
      if not success then
        -- Log the fallback
        if vim.fn.exists('/tmp/tamarin-debug') == 1 then
          local log_file = io.open("/tmp/tamarin-debug/tamarin_init.log", "a")
          if log_file then
            log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " Falling back to traditional syntax highlighting\n")
            log_file:close()
          end
        end
        
        -- Load traditional syntax highlighting
        require("config.tamarin-highlights").setup()
      end
    end
  })
end

return M 