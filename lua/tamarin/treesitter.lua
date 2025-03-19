-- Tamarin TreeSitter integration
-- Handles TreeSitter integration for Tamarin files, including fixing subdirectory highlighting

local M = {}

-- Start TreeSitter highlighting for a Tamarin buffer
function M.ensure_highlighting(bufnr)
  bufnr = bufnr or 0
  
  -- Skip if not a Tamarin buffer
  if vim.bo[bufnr].filetype ~= "tamarin" then
    return false
  end
  
  -- Register language if needed
  if vim.treesitter.language and vim.treesitter.language.register then
    pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
  end
  
  -- Try both spthy and tamarin languages
  local langs_to_try = {'spthy', 'tamarin'}
  local success = false
  
  for _, lang in ipairs(langs_to_try) do
    -- Attempt to get parser for the buffer
    local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    
    if parser_ok and parser then
      -- Force TreeSitter highlighting
      if vim.treesitter.highlighter then
        local highlighter_ok, highlighter = pcall(vim.treesitter.highlighter.new, parser)
        
        if highlighter_ok and highlighter then
          -- Store in buffer-local variable to prevent garbage collection
          vim.b[bufnr].tamarin_ts_highlighter = highlighter
          success = true
          break
        end
      end
    end
  end
  
  return success
end

-- Setup function
function M.setup()
  -- Register language
  if vim.treesitter.language and vim.treesitter.language.register then
    pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
  end
  
  -- Set up autocmd
  vim.cmd('augroup TamarinTreeSitter')
  vim.cmd('  autocmd!')
  vim.cmd('  autocmd FileType tamarin lua require("tamarin.treesitter").ensure_highlighting(0)')
  vim.cmd('augroup END')
  
  return true
end

return M 