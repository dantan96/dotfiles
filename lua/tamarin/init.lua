-- Tamarin initialization module
-- Main module for setting up Tamarin syntax highlighting with TreeSitter

local M = {}

-- Helper function to log messages
local function log(msg)
  if vim.fn.isdirectory('/tmp/tamarin-debug') == 0 then
    vim.fn.mkdir('/tmp/tamarin-debug', 'p')
  end
  
  local log_file = io.open("/tmp/tamarin-debug/tamarin_init.log", "a")
  if log_file then
    log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
    log_file:close()
  end
end

-- Setup function - called from init.lua
function M.setup()
  log("Starting Tamarin setup")
  
  -- Load the parser loader
  local parser_loader = require('tamarin.parser_loader')
  
  -- Set up filetype detection
  vim.filetype.add({
    extension = {
      spthy = "tamarin",
      sapic = "tamarin"
    },
  })
  
  -- Direct language registration (for Neovim 0.9+)
  if vim.treesitter and vim.treesitter.language and vim.treesitter.language.register then
    log("Using direct language registration (Neovim 0.9+)")
    
    -- Register 'spthy' language for 'tamarin' filetype
    -- This handles the case where the parser is named 'spthy' but filetype is 'tamarin'
    local ok, err = pcall(function()
      vim.treesitter.language.register('spthy', 'tamarin')
      return true
    end)
    
    if ok then
      log("Successfully registered spthy language for tamarin filetype")
    else
      log("Failed to register language: " .. tostring(err))
    end
  else
    log("Direct language registration not available (requires Neovim 0.9+)")
  end
  
  -- Create autocmd to load parsers when needed
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.spthy", "*.sapic" },
    callback = function()
      log("Tamarin file detected, loading parsers")
      
      -- Try to load parsers with comprehensive error handling
      local result = parser_loader.ensure_parsers_loaded()
      log("Parser loading result: " .. vim.inspect(result))
      
      -- Check if we need to create symlinks for symbol name mismatches
      if result.tamarin_parser_found and not result.tamarin_loaded then
        log("Attempting to fix symbol name mismatch")
        
        -- Create symlinks between parsers to handle name mismatches
        local config_dir = vim.fn.stdpath('config')
        local tamarin_parser_path = config_dir .. "/parser/tamarin/tamarin.so"
        local spthy_parser_path = config_dir .. "/parser/spthy/spthy.so"
        
        -- Create a spthy.so symlink in the tamarin directory
        if vim.fn.filereadable(tamarin_parser_path) == 1 then
          local cmd = string.format("ln -sf %s %s", 
            vim.fn.shellescape(tamarin_parser_path),
            vim.fn.shellescape(vim.fn.fnamemodify(tamarin_parser_path, ":h") .. "/spthy.so"))
          
          vim.fn.system(cmd)
          log("Created symlink: " .. cmd)
        end
        
        -- Try loading parsers again after creating symlinks
        result = parser_loader.ensure_parsers_loaded()
        log("Parser loading result after symlinks: " .. vim.inspect(result))
      end
      
      -- Try to start TreeSitter highlighting
      local bufnr = vim.api.nvim_get_current_buf()
      local success = parser_loader.start_highlighting(bufnr)
      
      if success then
        log("Successfully started TreeSitter highlighting")
      else
        log("Failed to start TreeSitter highlighting, falling back to traditional syntax")
        
        -- Load traditional syntax highlighting as fallback
        require("config.tamarin-highlights").setup()
      end
    end
  })
  
  -- Set up a minimal highlights.scm if one doesn't exist
  local function ensure_minimal_query_exists()
    local config_dir = vim.fn.stdpath('config')
    local spthy_query_dir = config_dir .. "/queries/spthy"
    local tamarin_query_dir = config_dir .. "/queries/tamarin"
    local spthy_highlights = spthy_query_dir .. "/highlights.scm"
    local tamarin_highlights = tamarin_query_dir .. "/highlights.scm"
    
    -- Create directories if they don't exist
    vim.fn.mkdir(spthy_query_dir, "p")
    vim.fn.mkdir(tamarin_query_dir, "p")
    
    -- Create a minimal highlights.scm if it doesn't exist
    if vim.fn.filereadable(spthy_highlights) == 0 then
      log("Creating minimal highlights.scm for spthy")
      
      local minimal_query = [[
;; Ultra-minimal highlights.scm for Tamarin/Spthy
(comment) @comment
(string) @string
(identifier) @variable
]]
      
      local file = io.open(spthy_highlights, "w")
      if file then
        file:write(minimal_query)
        file:close()
        log("Created minimal highlights.scm at " .. spthy_highlights)
      end
    end
    
    -- Create a symlink from tamarin/highlights.scm to spthy/highlights.scm if needed
    if vim.fn.filereadable(tamarin_highlights) == 0 then
      local cmd = string.format("ln -sf %s %s", 
        vim.fn.shellescape(spthy_highlights),
        vim.fn.shellescape(tamarin_highlights))
      
      vim.fn.system(cmd)
      log("Created symlink: " .. cmd)
    end
  end
  
  -- Ensure minimal query files exist
  ensure_minimal_query_exists()
  
  log("Tamarin setup completed")
end

return M