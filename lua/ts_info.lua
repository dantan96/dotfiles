-- TreeSitter Information Utility
-- Shows TreeSitter status for the current buffer

local M = {}

-- Get detailed TreeSitter information for the current buffer
function M.get_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local result = {
    active = false,
    language = vim.bo.filetype,
    parser_ok = false,
    highlight_active = false,
    captures_at_cursor = {},
    node_at_cursor = nil
  }
  
  -- Check if TreeSitter is active for this buffer
  if vim.treesitter and vim.treesitter.highlighter then
    result.active = vim.treesitter.highlighter.active[bufnr] ~= nil
  end
  
  -- Check if parser is available
  local lang = vim.treesitter.language.get_lang(result.language)
  if lang then
    -- Try to get parser info
    local ok = pcall(function()
      result.parser_ok = vim.treesitter.language.inspect(lang) ~= nil
    end)
    
    if not ok then
      result.parser_ok = false
    end
  end
  
  -- Get current cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  
  -- Get treesitter captures at cursor
  pcall(function()
    result.captures_at_cursor = vim.treesitter.get_captures_at_pos(bufnr, row, col)
  end)
  
  -- Get treesitter node at cursor
  pcall(function()
    local parser = vim.treesitter.get_parser(bufnr)
    local tree = parser:parse()[1]
    local root = tree:root()
    result.node_at_cursor = root:named_descendant_for_range(row, col, row, col)
  end)
  
  return result
end

-- Display TreeSitter information in a floating window
function M.show_info()
  local info = M.get_info()
  
  -- Get buffer name, but escape any special characters
  local bufname = vim.api.nvim_buf_get_name(0)
  bufname = bufname:gsub("\n", "\\n"):gsub("\r", "\\r")
  
  -- Format the information
  local lines = {
    "TreeSitter Status for Current Buffer",
    "───────────────────────────────────────────────────────",
    "• TreeSitter active: " .. (info.active and "Yes ✓" or "No ✗"),
    "• Language: " .. info.language,
    "• Parser available: " .. (info.parser_ok and "Yes ✓" or "No ✗"),
    "• Highlighting: " .. (info.active and "Using TreeSitter" or "Traditional syntax highlighting"),
    ""
  }
  
  -- Add captures at cursor
  if #info.captures_at_cursor > 0 then
    table.insert(lines, "TreeSitter Captures at Cursor:")
    for _, capture in ipairs(info.captures_at_cursor) do
      table.insert(lines, "  - " .. capture.capture)
    end
  else
    table.insert(lines, "No TreeSitter captures at cursor position")
  end
  
  -- Add node at cursor
  if info.node_at_cursor then
    table.insert(lines, "")
    table.insert(lines, "TreeSitter Node at Cursor:")
    table.insert(lines, "  - Type: " .. info.node_at_cursor:type())
    table.insert(lines, "  - Text: '" .. vim.treesitter.get_node_text(info.node_at_cursor, 0) .. "'")
  end
  
  -- Create a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  -- Calculate window dimensions
  local width = 60
  local height = #lines
  local win_height = vim.api.nvim_get_option("lines")
  local win_width = vim.api.nvim_get_option("columns")
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)
  
  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded"
  })
  
  -- Set mappings to close the window
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
  
  return win
end

-- Create a Neovim command
function M.setup()
  vim.api.nvim_create_user_command("TSInfo", function()
    M.show_info()
  end, {})
end

return M 