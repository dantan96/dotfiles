-- node_type_debug.lua
-- Helper script to identify available node types in Tamarin files
-- Run with ':lua dofile("queries/tamarin/node_type_debug.lua")'

local function print_node_types()
  local buf = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(buf)
  local tree = parser:parse()[1]
  local root = tree:root()
  
  local types = {}
  local function collect_types(node)
    local type = node:type()
    types[type] = true
    
    for child in node:iter_children() do
      collect_types(child)
    end
  end
  
  collect_types(root)
  
  local type_list = {}
  for type, _ in pairs(types) do
    table.insert(type_list, type)
  end
  
  table.sort(type_list)
  print("Available node types in Tamarin TreeSitter grammar:")
  for _, type in ipairs(type_list) do
    print("- " .. type)
  end
  
  print("\nTotal node types: " .. #type_list)
end

-- Helper function to check if a specific node type exists
local function check_node_type(node_type)
  local buf = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(buf)
  local tree = parser:parse()[1]
  local root = tree:root()
  
  local found = false
  local function find_type(node)
    if node:type() == node_type then
      found = true
      print("Found node type '" .. node_type .. "' at:")
      local start_row, start_col, end_row, end_col = node:range()
      print(string.format("Line %d, Col %d to Line %d, Col %d", 
                        start_row + 1, start_col + 1, 
                        end_row + 1, end_col + 1))
      return
    end
    
    for child in node:iter_children() do
      if not found then
        find_type(child)
      end
    end
  end
  
  find_type(root)
  
  if not found then
    print("Node type '" .. node_type .. "' not found in current buffer")
  end
end

-- Function to print captures at cursor position
local function print_captures_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Convert to 0-based
  
  local captures = vim.treesitter.get_captures_at_pos(bufnr, row, col)
  
  if #captures == 0 then
    print("No TreeSitter captures at cursor position")
    return
  end
  
  print("TreeSitter captures at cursor position:")
  for i, capture in ipairs(captures) do
    print(string.format("%d. %s", i, capture.capture))
  end
end

-- Print all node types
print_node_types()

-- To check a specific node type, uncomment and modify:
-- check_node_type("macro")

-- To print captures at cursor, uncomment:
-- print_captures_at_cursor() 