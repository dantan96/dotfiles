-- Node type validation script for Tamarin/Spthy
-- This script analyzes the parser to find valid node types

local M = {}

-- Create log file
local log_file = io.open(vim.fn.expand("~/.cache/nvim/tamarin_node_types.log"), "w")

local function log(msg)
  log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
  log_file:flush()
  print(msg)
end

-- Get all node types from a parsed tree
function M.get_node_types(bufnr)
  bufnr = bufnr or 0
  local node_types = {}
  
  -- Try to get a parser
  local ok, parser = pcall(function()
    return vim.treesitter.get_parser(bufnr, 'spthy')
  end)
  
  if not ok or not parser then
    log("ERROR: Failed to get parser")
    return {}
  end
  
  -- Parse the buffer
  local tree = parser:parse()[1]
  if not tree then
    log("ERROR: Failed to parse buffer")
    return {}
  end
  
  -- Get root node
  local root = tree:root()
  if not root then
    log("ERROR: Failed to get root node")
    return {}
  end
  
  -- Function to collect node types recursively
  local function collect_node_types(node)
    local type = node:type()
    node_types[type] = true
    
    -- Process child nodes recursively
    for child in node:iter_children() do
      collect_node_types(child)
    end
  end
  
  -- Start the collection
  collect_node_types(root)
  
  return node_types
end

-- Validate the highlights.scm file
function M.validate_highlights_file()
  log("Validating highlights.scm file...")
  
  -- Read the highlights.scm file
  local highlights_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
  local file = io.open(highlights_path, "r")
  if not file then
    log("ERROR: Could not open highlights.scm file")
    return false
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Try to parse the query
  local ok, result = pcall(function()
    return vim.treesitter.query.parse('spthy', content)
  end)
  
  if not ok then
    log("ERROR: Failed to parse query: " .. tostring(result))
    return false
  end
  
  log("SUCCESS: highlights.scm file parsed successfully")
  return true
end

-- Run a complete validation
function M.run_validation()
  log("Starting node type validation for Tamarin/Spthy...")
  
  -- Open test file
  local test_file = vim.fn.stdpath('config') .. '/test/verification/test_tamarin.spthy'
  vim.cmd("edit " .. test_file)
  vim.cmd("set filetype=tamarin")
  
  -- Get node types from the file
  local node_types = M.get_node_types(0)
  
  -- Log all found node types
  log("\nFound node types in Tamarin/Spthy grammar:")
  local node_type_list = {}
  for node_type, _ in pairs(node_types) do
    table.insert(node_type_list, node_type)
  end
  
  -- Sort for better readability
  table.sort(node_type_list)
  for _, node_type in ipairs(node_type_list) do
    log("  - " .. node_type)
  end
  
  -- Validate highlights.scm
  local is_valid = M.validate_highlights_file()
  
  log("\nValidation result: " .. (is_valid and "PASS" or "FAIL"))
  log("Log file written to: " .. vim.fn.expand("~/.cache/nvim/tamarin_node_types.log"))
  
  log_file:close()
  return is_valid, node_types
end

return M 