-- treesitter_playground.lua
-- A module that provides TreeSitter playground functionality for testing Tamarin syntax highlighting

local M = {}

-- Configuration
local config = {
  window_width = 80,
  window_height = 20,
  border = "rounded",
  debug = true,
  auto_refresh = true,
  refresh_delay = 500,
  show_line_numbers = true
}

-- Playground state
local state = {
  bufnr = nil,
  tree_bufnr = nil,
  tree_winnr = nil,
  hover_winnr = nil,
  hover_bufnr = nil,
  matches = {},
  current_node = nil,
  last_update = 0,
  parser = nil,
  tree = nil,
  root = nil,
  playground_open = false
}

-- Set up logging
local function log(msg, level)
  level = level or vim.log.levels.INFO
  if config.debug then
    vim.notify("[TSPlayground] " .. msg, level)
  end
end

-- Clear playground state
local function clear_playground_state()
  if state.tree_winnr and vim.api.nvim_win_is_valid(state.tree_winnr) then
    vim.api.nvim_win_close(state.tree_winnr, true)
  end
  
  if state.hover_winnr and vim.api.nvim_win_is_valid(state.hover_winnr) then
    vim.api.nvim_win_close(state.hover_winnr, true)
  end
  
  if state.tree_bufnr and vim.api.nvim_buf_is_valid(state.tree_bufnr) then
    vim.api.nvim_buf_delete(state.tree_bufnr, { force = true })
  end
  
  if state.hover_bufnr and vim.api.nvim_buf_is_valid(state.hover_bufnr) then
    vim.api.nvim_buf_delete(state.hover_bufnr, { force = true })
  end
  
  state.tree_winnr = nil
  state.tree_bufnr = nil
  state.hover_winnr = nil
  state.hover_bufnr = nil
  state.matches = {}
  state.current_node = nil
  state.playground_open = false
end

-- Format node text for display
local function format_node_text(node, bufnr)
  local text = vim.treesitter.get_node_text(node, bufnr)
  if text then
    -- Truncate long text
    if #text > 40 then
      text = text:sub(1, 37) .. "..."
    end
    
    -- Escape newlines
    text = text:gsub("\n", "\\n")
    text = text:gsub("%s+", " ")
    
    return text
  else
    return ""
  end
end

-- Format a node for display
local function format_node(node, bufnr, indent, prefix)
  indent = indent or 0
  prefix = prefix or ""
  
  if not node then return "" end
  
  local indent_str = string.rep("  ", indent)
  local node_type = node:type()
  local start_row, start_col, end_row, end_col = node:range()
  local text = format_node_text(node, bufnr)
  
  local line = string.format("%s%s(%s) [%d:%d-%d:%d] %s",
    indent_str,
    prefix,
    node_type,
    start_row + 1, start_col + 1,
    end_row + 1, end_col + 1,
    text ~= "" and '"' .. text .. '"' or "")
  
  return line
end

-- Get node at cursor position
local function get_node_at_cursor()
  local bufnr = state.bufnr
  local winnr = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local row, col = cursor[1] - 1, cursor[2]
  
  -- Ensure the parser is available
  if not state.parser then
    log("Parser not available", vim.log.levels.ERROR)
    return nil
  end
  
  local tree = state.tree or state.parser:parse()[1]
  state.tree = tree
  
  local root = tree:root()
  state.root = root
  
  -- Find the deepest node at cursor position
  local node = root:named_descendant_for_range(row, col, row, col)
  return node
end

-- Get all captures at cursor position
local function get_captures_at_cursor()
  local bufnr = state.bufnr
  local winnr = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local row, col = cursor[1] - 1, cursor[2]
  
  local captures = {}
  
  -- Check both traditional syntax highlights and TreeSitter captures
  -- Traditional syntax highlights
  local syntax_id = vim.fn.synID(row + 1, col + 1, 1)
  local syntax_name = vim.fn.synIDattr(syntax_id, "name")
  local trans_id = vim.fn.synIDtrans(syntax_id)
  local trans_name = vim.fn.synIDattr(trans_id, "name")
  
  if syntax_name and syntax_name ~= "" then
    table.insert(captures, {
      type = "syntax",
      name = syntax_name,
      trans_name = trans_name,
      fg = vim.fn.synIDattr(trans_id, "fg"),
      bg = vim.fn.synIDattr(trans_id, "bg"),
      bold = vim.fn.synIDattr(trans_id, "bold") == "1",
      italic = vim.fn.synIDattr(trans_id, "italic") == "1"
    })
  end
  
  -- TreeSitter captures
  pcall(function()
    local ts_captures = vim.treesitter.get_captures_at_pos(bufnr, row, col)
    for _, capture in ipairs(ts_captures) do
      table.insert(captures, {
        type = "treesitter",
        name = capture.capture,
        node_type = capture.node and capture.node:type() or nil,
        text = capture.node and format_node_text(capture.node, bufnr) or nil
      })
    end
  end)
  
  return captures
end

-- Build the syntax tree display
local function build_tree_display(node, bufnr)
  local lines = {}
  
  -- Function to traverse the tree recursively
  local function traverse(current_node, indent, field_name)
    if not current_node then return end
    
    local prefix = field_name and field_name .. ": " or ""
    table.insert(lines, format_node(current_node, bufnr, indent, prefix))
    
    -- Process children with field names if available
    for child, field in current_node:iter_children() do
      traverse(child, indent + 1, field)
    end
  end
  
  -- Start traversal from the provided node
  traverse(node, 0)
  
  return lines
end

-- Create the tree display window
local function create_tree_window()
  -- Create buffer for tree display
  state.tree_bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer options
  vim.api.nvim_buf_set_option(state.tree_bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(state.tree_bufnr, "filetype", "treesitterplayground")
  vim.api.nvim_buf_set_option(state.tree_bufnr, "modifiable", false)
  
  -- Create window configuration
  local win_opts = {
    relative = "editor",
    width = config.window_width,
    height = config.window_height,
    row = math.floor((vim.o.lines - config.window_height) / 2),
    col = math.floor((vim.o.columns - config.window_width) / 2),
    style = "minimal",
    border = config.border,
    title = "TreeSitter Playground",
    title_pos = "center"
  }
  
  -- Create window
  state.tree_winnr = vim.api.nvim_open_win(state.tree_bufnr, false, win_opts)
  
  -- Configure window options
  if config.show_line_numbers then
    vim.api.nvim_win_set_option(state.tree_winnr, "number", true)
  end
  
  -- Set up keymaps for the tree window
  local function set_keymap(lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(state.tree_bufnr, "n", lhs, rhs, opts or { noremap = true, silent = true })
  end
  
  set_keymap("q", [[<cmd>lua require('test.treesitter_playground').close()<CR>]])
  set_keymap("<CR>", [[<cmd>lua require('test.treesitter_playground').select_node()<CR>]])
  set_keymap("r", [[<cmd>lua require('test.treesitter_playground').refresh()<CR>]])
  set_keymap("?", [[<cmd>lua require('test.treesitter_playground').show_help()<CR>]])
  set_keymap("c", [[<cmd>lua require('test.treesitter_playground').toggle_syntax_captures()<CR>]])
  set_keymap("t", [[<cmd>lua require('test.treesitter_playground').toggle_treesitter_highlights()<CR>]])
end

-- Create hover window for displaying node details
local function create_hover_window(text)
  -- Create buffer for hover display
  state.hover_bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Split text into lines
  local lines = vim.split(text, "\n")
  vim.api.nvim_buf_set_lines(state.hover_bufnr, 0, -1, false, lines)
  
  -- Configure buffer options
  vim.api.nvim_buf_set_option(state.hover_bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(state.hover_bufnr, "filetype", "markdown")
  vim.api.nvim_buf_set_option(state.hover_bufnr, "modifiable", false)
  
  -- Calculate dimensions based on content
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end
  width = math.min(width + 2, vim.o.columns - 10)
  local height = math.min(#lines, 15)
  
  -- Create window configuration
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = config.border,
    title = "Node Details",
    title_pos = "center"
  }
  
  -- Create window
  state.hover_winnr = vim.api.nvim_open_win(state.hover_bufnr, true, win_opts)
  
  -- Set up keymaps for the hover window
  vim.api.nvim_buf_set_keymap(state.hover_bufnr, "n", "q", 
    [[<cmd>lua vim.api.nvim_win_close(require('test.treesitter_playground').get_state().hover_winnr, true)<CR>]],
    { noremap = true, silent = true })
end

-- Update the tree display
local function update_tree_display()
  if not state.tree_bufnr or not vim.api.nvim_buf_is_valid(state.tree_bufnr) then
    return
  end
  
  local node = get_node_at_cursor()
  if not node then
    log("No node at cursor position", vim.log.levels.WARN)
    return
  end
  
  state.current_node = node
  
  -- Build tree display lines
  local lines = build_tree_display(node, state.bufnr)
  
  -- Update buffer with new content
  vim.api.nvim_buf_set_option(state.tree_bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.tree_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.tree_bufnr, "modifiable", false)
end

-- Show details of the current node
local function show_node_details()
  if not state.current_node then
    log("No current node selected", vim.log.levels.WARN)
    return
  end
  
  local node = state.current_node
  local start_row, start_col, end_row, end_col = node:range()
  local text = vim.treesitter.get_node_text(node, state.bufnr)
  
  -- Format the detailed view
  local details = {
    "# Node Details",
    "",
    "## Type",
    node:type(),
    "",
    "## Range",
    string.format("Start: Line %d, Column %d", start_row + 1, start_col + 1),
    string.format("End: Line %d, Column %d", end_row + 1, end_col + 1),
    "",
    "## Text",
    text and '"' .. text:gsub("\n", "\\n") .. '"' or "(empty)",
    ""
  }
  
  -- Get captures information
  local captures = {}
  pcall(function()
    local query_captures = vim.treesitter.query.get_captures_at_position(
      state.bufnr,
      "spthy",
      "highlights",
      start_row,
      start_col
    )
    
    if query_captures and #query_captures > 0 then
      table.insert(details, "## Captures")
      for _, capture in ipairs(query_captures) do
        table.insert(details, "- @" .. capture.capture)
      end
    else
      table.insert(details, "## Captures")
      table.insert(details, "No captures found for this node")
    end
  end)
  
  -- Create hover window with details
  create_hover_window(table.concat(details, "\n"))
end

-- Toggle between traditional and TreeSitter highlighting
local function toggle_treesitter_highlights()
  local bufnr = state.bufnr
  
  -- Check if TreeSitter highlighting is currently enabled
  local is_enabled = false
  pcall(function()
    is_enabled = vim.treesitter.highlighter.active[bufnr] ~= nil
  end)
  
  if is_enabled then
    -- Disable TreeSitter highlighting
    vim.cmd("TSBufDisable highlight")
    vim.notify("TreeSitter highlighting disabled")
  else
    -- Enable TreeSitter highlighting
    vim.cmd("TSBufEnable highlight")
    vim.notify("TreeSitter highlighting enabled")
  end
  
  -- Refresh the display
  update_tree_display()
end

-- Toggle traditional syntax highlighting
local function toggle_syntax_highlighting()
  local bufnr = state.bufnr
  
  if vim.bo[bufnr].syntax == "OFF" then
    -- Enable syntax
    vim.bo[bufnr].syntax = "tamarin"
    vim.cmd("syntax enable")
    vim.notify("Traditional syntax highlighting enabled")
  else
    -- Disable syntax
    vim.bo[bufnr].syntax = "OFF"
    vim.notify("Traditional syntax highlighting disabled")
  end
  
  -- Refresh the display
  update_tree_display()
end

-- Show help information
local function show_help()
  local help_text = {
    "# TreeSitter Playground Help",
    "",
    "## Keybindings",
    "- `q`: Close the playground",
    "- `<CR>`: Show details of the node at cursor",
    "- `r`: Refresh the playground",
    "- `?`: Show this help message",
    "- `c`: Toggle traditional syntax highlighting",
    "- `t`: Toggle TreeSitter highlighting",
    "",
    "## Tips",
    "- Move your cursor in the main buffer to see the syntax tree at that position",
    "- The playground updates automatically as you type",
    "- Compare traditional and TreeSitter highlighting using the toggle commands",
    ""
  }
  
  create_hover_window(table.concat(help_text, "\n"))
end

-- Setup auto-refresh
local function setup_auto_refresh()
  if config.auto_refresh then
    -- Set up autocommands for auto-refresh
    vim.cmd([[
      augroup TreesitterPlayground
        autocmd!
        autocmd CursorMoved <buffer> lua require('test.treesitter_playground').cursor_moved()
        autocmd TextChanged,TextChangedI <buffer> lua require('test.treesitter_playground').text_changed()
      augroup END
    ]])
  end
end

-- Clean up auto-refresh
local function cleanup_auto_refresh()
  vim.cmd([[
    augroup TreesitterPlayground
      autocmd!
    augroup END
  ]])
end

-- Select a node in the tree view
function M.select_node()
  show_node_details()
end

-- Get the current state (for use in keymaps)
function M.get_state()
  return state
end

-- Handle cursor moved event
function M.cursor_moved()
  -- Throttle updates to avoid too many refreshes
  local now = vim.loop.now()
  if now - state.last_update < config.refresh_delay then
    return
  end
  
  state.last_update = now
  update_tree_display()
end

-- Handle text changed event
function M.text_changed()
  -- Throttle updates to avoid too many refreshes
  local now = vim.loop.now()
  if now - state.last_update < config.refresh_delay then
    return
  end
  
  state.last_update = now
  
  -- Re-parse the buffer
  if state.parser then
    state.tree = state.parser:parse()[1]
    state.root = state.tree:root()
  end
  
  update_tree_display()
end

-- Manually refresh the playground
function M.refresh()
  if state.parser then
    state.tree = state.parser:parse()[1]
    state.root = state.tree:root()
  end
  
  update_tree_display()
  vim.notify("Playground refreshed")
end

-- Toggle TreeSitter highlighting
function M.toggle_treesitter_highlights()
  toggle_treesitter_highlights()
end

-- Toggle traditional syntax highlighting
function M.toggle_syntax_captures()
  toggle_syntax_highlighting()
end

-- Show help message
function M.show_help()
  show_help()
end

-- Close the playground
function M.close()
  cleanup_auto_refresh()
  clear_playground_state()
  vim.notify("TreeSitter playground closed")
end

-- Open the playground for the current buffer
function M.open()
  if not is_treesitter_available() then
    vim.notify("TreeSitter is not available", vim.log.levels.ERROR)
    return false
  end
  
  local current_buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[current_buf].filetype
  
  if ft ~= "tamarin" then
    vim.notify("Current buffer is not a Tamarin file", vim.log.levels.WARN)
    return false
  end
  
  -- Check for spthy parser
  local has_parser = pcall(vim.treesitter.language.inspect, "spthy")
  if not has_parser then
    vim.notify("Spthy parser not found", vim.log.levels.ERROR)
    return false
  end
  
  -- Create output buffer for tree visualization
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create a split window
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  
  -- Get source content
  local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Try to parse the content
  local parser = vim.treesitter.get_string_parser(content, "spthy")
  if not parser then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "# Tamarin Parse Tree Playground",
      "",
      "Error: Could not create parser for Spthy"
    })
    return false
  end
  
  -- Parse the tree
  local tree = parser:parse()[1]
  local root = tree:root()
  
  if not root then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "# Tamarin Parse Tree Playground",
      "",
      "Error: Could not parse Tamarin source"
    })
    return false
  end
  
  -- Generate tree visualization
  local result = {
    "# Tamarin Parse Tree Playground",
    "",
    "Press q to close this window",
    "",
    "Parse Tree:",
    "----------"
  }
  
  -- Function to traverse and visualize the tree
  local function visualize_node(node, depth, is_last)
    if not node then return end
    
    local indent = string.rep("  ", depth)
    local prefix = is_last and "└─ " or "├─ "
    
    if depth > 0 then
      indent = indent .. prefix
    end
    
    local node_type = node:type()
    local range = {node:range()}
    local start_row, start_col, end_row, end_col = unpack(range)
    
    local line_text = ""
    if start_row == end_row then
      local line = lines[start_row + 1]
      if line then
        line_text = line:sub(start_col + 1, end_col)
        if #line_text > 20 then
          line_text = line_text:sub(1, 17) .. "..."
        end
        line_text = " \"" .. line_text .. "\""
      end
    end
    
    local type_str = node_type .. " [" .. start_row + 1 .. ":" .. start_col + 1 .. 
                    " - " .. end_row + 1 .. ":" .. end_col .. "]" .. line_text
    
    table.insert(result, indent .. type_str)
    
    -- Add children
    local child_count = node:child_count()
    if child_count > 0 then
      for i = 0, child_count - 1 do
        visualize_node(node:child(i), depth + 1, i == child_count - 1)
      end
    end
  end
  
  -- Start visualization from root
  visualize_node(root, 0, true)
  
  -- Add highlight info
  table.insert(result, "")
  table.insert(result, "Highlight Queries:")
  table.insert(result, "----------------")
  
  local highlight_query = vim.treesitter.query.get("spthy", "highlights")
  if highlight_query then
    local query_str = highlight_query.query_string or "No query string available"
    
    -- Format query string with line breaks
    local query_lines = {}
    for line in query_str:gmatch("[^\r\n]+") do
      table.insert(query_lines, line)
    end
    
    for _, line in ipairs(query_lines) do
      table.insert(result, line)
    end
  else
    table.insert(result, "No highlight query found for Spthy")
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  -- Add keymapping to close the window
  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, {buffer = buf, noremap = true})
  
  debug_print("Opened Tamarin TreeSitter playground")
  
  return true
end

-- Debug helper
local function debug_print(msg)
  if vim.g.tamarin_test_debug then
    print("[PLAYGROUND DEBUG] " .. msg)
  end
end

-- Check if TreeSitter is available
local function is_treesitter_available()
  return pcall(function() return vim.treesitter end)
end

return M 