-- Configuration module for Tamarin syntax highlighting
-- This coordinates between TreeSitter and fallback highlighting

local M = {}

-- Debug output helper function
local function debug_print(msg)
  if vim.g.tamarin_highlight_debug then
    vim.notify("[Tamarin Highlight] " .. msg)
  end
end

-- Check if TreeSitter is available and properly set up
local function is_treesitter_available()
  -- Check if TreeSitter API exists
  if not vim.treesitter then
    debug_print("TreeSitter API not available")
    return false
  end

  -- Check if the tamarin parser exists
  local parser_ok = pcall(function()
    return vim.treesitter.get_parser(0, "tamarin")
  end)
  
  if not parser_ok then
    debug_print("Tamarin parser not available")
    return false
  end
  
  -- Check if query file exists and is valid
  local query_path = vim.api.nvim_get_runtime_file("queries/spthy/highlights.scm", false)[1]
  if not query_path then
    debug_print("Tamarin query file not found")
    return false
  end
  
  -- Verify query is valid
  local query_ok = pcall(function()
    local file = io.open(query_path, "r")
    if file then
      local content = file:read("*all")
      file:close()
      vim.treesitter.query.parse("spthy", content)
    end
  end)
  
  if not query_ok then
    debug_print("Tamarin query file is invalid")
    return false
  end
  
  return true
end

-- Apply TreeSitter highlighting to current buffer
local function apply_treesitter_highlighting()
  vim.g.tamarin_treesitter_initialized = true
  
  -- Register language if not already registered
  pcall(function()
    vim.treesitter.language.register('tamarin', { 'spthy', 'sapic' })
  end)
  
  -- Ensure highlighting is enabled
  vim.cmd("TSBufEnable highlight")
  
  -- Apply colors for TreeSitter highlighting groups
  pcall(function()
    require('config.tamarin-colors').setup()
  end)
  
  debug_print("TreeSitter highlighting enabled for buffer")
end

-- Apply fallback syntax highlighting when TreeSitter isn't available
local function apply_fallback_highlighting()
  vim.g.tamarin_treesitter_initialized = false
  
  -- The actual highlighting rules are in ftplugin/tamarin.lua
  vim.cmd("syntax enable")
  
  debug_print("Fallback syntax highlighting enabled for buffer")
end

-- Setup function to be called when filetype is detected
function M.setup()
  -- Only setup once per Neovim session
  if vim.g.tamarin_highlights_setup then
    return
  end
  
  vim.g.tamarin_highlights_setup = true
  
  -- Create autocmd to initialize highlighting for each buffer
  local augroup = vim.api.nvim_create_augroup("TamarinHighlighting", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "tamarin",
    callback = function()
      if is_treesitter_available() then
        apply_treesitter_highlighting()
      else
        apply_fallback_highlighting()
      end
    end,
  })
  
  debug_print("Tamarin highlighting setup complete")
end

return M 
