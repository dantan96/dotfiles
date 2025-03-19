-- print_syntax_tree.lua
-- A script to print the syntax tree of a file with node types and captures

local M = {}

-- Ensure parser is loaded
local function ensure_parser_loaded()
  -- Register language mapping
  if vim.treesitter.language and vim.treesitter.language.register then
    vim.treesitter.language.register('spthy', 'tamarin')
  end
  
  -- Find parser path
  local possible_paths = {
    vim.fn.stdpath('config') .. '/parser/spthy/spthy.so',
    vim.fn.stdpath('config') .. '/parser/tamarin/tamarin.so',
  }
  
  local parser_path = nil
  for _, path in ipairs(possible_paths) do
    if vim.fn.filereadable(path) == 1 then
      parser_path = path
      break
    end
  end
  
  if not parser_path then
    return false, "Parser not found in standard locations"
  end
  
  -- Load parser explicitly
  if vim.treesitter.language.add then
    local ok, err = pcall(vim.treesitter.language.add, 'spthy', { path = parser_path })
    if not ok then
      return false, "Failed to add language: " .. tostring(err)
    end
  end
  
  return true
end

-- Function to print the syntax tree recursively
local function build_tree_output(node, bufnr, indent, output)
  indent = indent or 0
  output = output or {}
  
  -- Print node information
  local indent_str = string.rep("  ", indent)
  local node_type = node:type()
  local start_row, start_col, end_row, end_col = node:range()
  local text = vim.treesitter.get_node_text(node, bufnr)
  
  -- Limit text length for display
  if text and #text > 50 then
    text = text:sub(1, 47) .. "..."
  end
  
  -- Clean up text for display (remove newlines, etc.)
  if text then
    text = text:gsub("\n", "\\n")
    text = '"' .. text .. '"'
  else
    text = ""
  end
  
  table.insert(output, indent_str .. "- " .. node_type .. " [" .. start_row .. ":" .. start_col .. 
        " to " .. end_row .. ":" .. end_col .. "] " .. text)
  
  -- Print child nodes
  for child, field_name in node:iter_children() do
    if field_name then
      table.insert(output, indent_str .. "  Field: " .. field_name)
    end
    build_tree_output(child, bufnr, indent + 1, output)
  end
  
  return output
end

-- Function to collect captures for a node
local function collect_captures(node, bufnr, query, output)
  output = output or {}
  local start_row, start_col, end_row, end_col = node:range()
  
  -- Iterate through all matches
  for id, node, metadata in query:iter_captures(node, bufnr, start_row, end_row + 1) do
    local name = query.captures[id]
    local node_type = node:type()
    local text = vim.treesitter.get_node_text(node, bufnr)
    
    -- Limit text length
    if text and #text > 30 then
      text = text:sub(1, 27) .. "..."
    end
    
    table.insert(output, string.format("CAPTURE: @%s on %s node %q", name, node_type, text or ""))
  end
  
  return output
end

-- Main function to analyze a file's syntax tree and write to a file
function M.analyze_to_file(file_path, output_path)
  output_path = output_path or (vim.fn.expand("~/temp_files") .. "/syntax_tree.txt")
  
  -- Ensure output directory exists
  local output_dir = vim.fn.fnamemodify(output_path, ":h")
  vim.fn.mkdir(output_dir, "p")
  
  -- Open output file
  local output_file = io.open(output_path, "w")
  if not output_file then
    vim.cmd("qa!")
    return
  end
  
  local function write_line(line)
    output_file:write(line .. "\n")
  end
  
  -- Ensure file exists
  if vim.fn.filereadable(file_path) ~= 1 then
    write_line("ERROR: File does not exist: " .. file_path)
    output_file:close()
    vim.cmd("qa!")
    return
  end
  
  -- Ensure parser is loaded
  local parser_ok, parser_err = ensure_parser_loaded()
  if not parser_ok then
    write_line("ERROR: " .. parser_err)
    output_file:close()
    vim.cmd("qa!")
    return
  end
  
  -- Create a buffer and load the file
  local bufnr = vim.api.nvim_create_buf(false, true)
  local content = vim.fn.readfile(file_path)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "tamarin")
  
  -- Parse the file with error handling
  local parser_success, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_success or not parser then
    write_line("ERROR: Failed to create parser: " .. tostring(parser))
    output_file:close()
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.cmd("qa!")
    return
  end
  
  local tree_success, tree = pcall(function() return parser:parse()[1] end)
  if not tree_success or not tree then
    write_line("ERROR: Failed to parse tree: " .. tostring(tree))
    output_file:close()
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.cmd("qa!")
    return
  end
  
  local root = tree:root()
  
  -- Write header
  write_line("=== SYNTAX TREE FOR " .. file_path .. " ===")
  
  -- Build and write the syntax tree
  local tree_output = build_tree_output(root, bufnr)
  for _, line in ipairs(tree_output) do
    write_line(line)
  end
  
  -- Try to load the highlights query
  write_line("\n=== CAPTURES FROM HIGHLIGHTS.SCM ===")
  
  local query_file = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
  local query_success, query_content = pcall(vim.fn.readfile, query_file)
  
  if not query_success then
    write_line("ERROR: Failed to read query file: " .. tostring(query_content))
    output_file:close()
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.cmd("qa!")
    return
  end
  
  local query_string = table.concat(query_content, "\n")
  local parse_success, query = pcall(vim.treesitter.query.parse, 'spthy', query_string)
  
  if not parse_success then
    write_line("ERROR: Failed to parse query: " .. tostring(query))
    output_file:close()
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.cmd("qa!")
    return
  end
  
  -- Collect and write captures
  local captures_output = collect_captures(root, bufnr, query)
  for _, line in ipairs(captures_output) do
    write_line(line)
  end
  
  -- Write footer and clean up
  write_line("\nDone!")
  output_file:close()
  vim.api.nvim_buf_delete(bufnr, { force = true })
  
  -- Exit Neovim
  vim.cmd("qa!")
end

-- Command interface for running in headless mode
function M.run_headless()
  local args = vim.v.argv
  local input_file = nil
  local output_file = nil
  
  -- Parse command line arguments
  for i = 1, #args do
    if args[i] == "--input" and i < #args then
      input_file = args[i+1]
    elseif args[i] == "--output" and i < #args then
      output_file = args[i+1]
    end
  end
  
  if not input_file then
    -- Default test file if none provided
    input_file = vim.fn.stdpath('config') .. '/test/tamarin/test.spthy'
  end
  
  -- Run the analysis
  M.analyze_to_file(input_file, output_file)
end

return M 