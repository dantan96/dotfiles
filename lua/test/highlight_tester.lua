-- highlight_tester.lua
-- Module for testing syntax highlighting in both traditional mode and TreeSitter

local M = {}

-- Configuration
local config = {
  debug = true,
  output_dir = vim.fn.expand("~/temp_files")
}

-- Set up logging
local function log(msg, level)
  level = level or vim.log.levels.INFO
  if config.debug then
    vim.notify("[HighlightTester] " .. msg, level)
  end
end

-- Check if TreeSitter is available for Tamarin
local function is_treesitter_available()
  -- Check if treesitter API is available
  if not vim.treesitter then
    log("TreeSitter API not available", vim.log.levels.WARN)
    return false
  end
  
  -- Check if parser is available
  local ok, parser_ok = pcall(function()
    return vim.treesitter.language.require_language("spthy", nil, true)
  end)
  
  if not ok or not parser_ok then
    log("Tamarin parser not available", vim.log.levels.WARN)
    return false
  end
  
  -- Check if query file exists
  local query_file = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
  if vim.fn.filereadable(query_file) ~= 1 then
    log("Query file not found: " .. query_file, vim.log.levels.WARN)
    return false
  end
  
  return true
end

-- Get syntax stack at position
local function get_syntax_stack(bufnr, row, col)
  bufnr = bufnr or 0
  local stack = vim.fn.synstack(row, col)
  local result = {}
  
  for i = 1, #stack do
    local id = stack[i]
    local name = vim.fn.synIDattr(id, "name")
    local trans_id = vim.fn.synIDtrans(id)
    local trans_name = vim.fn.synIDattr(trans_id, "name")
    
    table.insert(result, {
      id = id,
      name = name,
      trans_id = trans_id,
      trans_name = trans_name
    })
  end
  
  return result
end

-- Get treesitter captures at position
local function get_treesitter_captures(bufnr, row, col)
  bufnr = bufnr or 0
  
  -- Check if treesitter is available
  if not is_treesitter_available() then
    return {}
  end
  
  -- Get parser
  local parser = vim.treesitter.get_parser(bufnr, "spthy")
  if not parser then
    log("Failed to get parser", vim.log.levels.WARN)
    return {}
  end
  
  -- Get tree
  local tree = parser:parse()[1]
  if not tree then
    log("Failed to parse tree", vim.log.levels.WARN)
    return {}
  end
  
  -- Get root
  local root = tree:root()
  if not root then
    log("Failed to get root node", vim.log.levels.WARN)
    return {}
  end
  
  -- Get node at position
  local node = root:named_descendant_for_range(row, col, row, col + 1)
  if not node then
    log("No node at position " .. row .. ":" .. col, vim.log.levels.WARN)
    return {}
  end
  
  -- Get captures
  local captures = {}
  local query = vim.treesitter.query.get("spthy", "highlights")
  if not query then
    log("Failed to get query", vim.log.levels.WARN)
    return {}
  end
  
  for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
    local range = {node:range()}
    local start_row, start_col, end_row, end_col = unpack(range)
    
    if row >= start_row and row <= end_row and
       ((row == start_row and col >= start_col) or row > start_row) and
       ((row == end_row and col < end_col) or row < end_row) then
      local name = query.captures[id]
      table.insert(captures, { id = id, name = name, node = node })
    end
  end
  
  return captures
end

-- Collect highlights at cursor position
local function collect_highlights_at_position(bufnr, row, col)
  local result = {
    position = { row = row, col = col },
    syntax = get_syntax_stack(bufnr, row, col),
    treesitter = get_treesitter_captures(bufnr, row - 1, col - 1) -- TreeSitter is 0-indexed
  }
  
  return result
end

-- Scan a buffer for all highlighted elements
local function scan_buffer_highlights(bufnr, options)
  bufnr = bufnr or 0
  options = options or {}
  
  local results = {}
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  
  for row = 1, line_count do
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    
    for col = 1, #line do
      local char = line:sub(col, col)
      if char:match("%S") then -- Skip whitespace
        local highlights = collect_highlights_at_position(bufnr, row, col)
        
        if options.only_treesitter and #highlights.treesitter > 0 then
          table.insert(results, highlights)
        elseif options.only_syntax and #highlights.syntax > 0 then
          table.insert(results, highlights)
        elseif not options.only_treesitter and not options.only_syntax and 
               (#highlights.syntax > 0 or #highlights.treesitter > 0) then
          table.insert(results, highlights)
        end
        
        -- Skip ahead to avoid duplicate adjacent highlights
        col = col + 1
      end
    end
  end
  
  return results
end

-- Test traditional syntax highlighting
function M.test_traditional(file_path)
  log("Testing traditional highlighting on: " .. file_path)
  
  -- Open the file in a buffer
  local bufnr = vim.fn.bufadd(file_path)
  vim.fn.bufload(bufnr)
  
  -- Make sure TreeSitter is disabled temporarily
  local original_parsers
  
  if vim.treesitter and vim.treesitter.highlighter then
    original_parsers = vim.treesitter.highlighter.active
    vim.treesitter.highlighter.active = {}
  end
  
  -- Ensure traditional syntax is enabled
  vim.cmd("syntax on")
  vim.cmd("set syntax=tamarin")
  
  -- Scan for highlights
  local results = scan_buffer_highlights(bufnr, { only_syntax = true })
  
  -- Restore TreeSitter if it was active
  if original_parsers then
    vim.treesitter.highlighter.active = original_parsers
  end
  
  log("Found " .. #results .. " traditional highlight groups")
  return results
end

-- Test TreeSitter syntax highlighting
function M.test_treesitter(file_path)
  log("Testing TreeSitter highlighting on: " .. file_path)
  
  -- Check if TreeSitter is available
  if not is_treesitter_available() then
    log("TreeSitter not available for Tamarin", vim.log.levels.ERROR)
    return {}
  end
  
  -- Open the file in a buffer
  local bufnr = vim.fn.bufadd(file_path)
  vim.fn.bufload(bufnr)
  
  -- Ensure TreeSitter is enabled
  vim.treesitter.start(bufnr, "spthy")
  
  -- Scan for highlights
  local results = scan_buffer_highlights(bufnr, { only_treesitter = true })
  
  log("Found " .. #results .. " TreeSitter captures")
  return results
end

-- Compare TreeSitter and traditional highlighting
function M.compare_highlighting(file_path)
  log("Comparing highlighting methods on: " .. file_path)
  
  -- Get both types of highlights
  local traditional = M.test_traditional(file_path)
  local treesitter = M.test_treesitter(file_path)
  
  -- Organize by position for comparison
  local comparison = {}
  
  -- Add traditional highlights
  for _, highlight in ipairs(traditional) do
    local pos_key = highlight.position.row .. ":" .. highlight.position.col
    comparison[pos_key] = comparison[pos_key] or { position = highlight.position, traditional = {}, treesitter = {} }
    comparison[pos_key].traditional = highlight.syntax
  end
  
  -- Add TreeSitter highlights
  for _, highlight in ipairs(treesitter) do
    local pos_key = highlight.position.row .. ":" .. highlight.position.col
    comparison[pos_key] = comparison[pos_key] or { position = highlight.position, traditional = {}, treesitter = {} }
    comparison[pos_key].treesitter = highlight.treesitter
  end
  
  -- Convert back to list
  local results = {}
  for _, item in pairs(comparison) do
    table.insert(results, item)
  end
  
  -- Sort by position
  table.sort(results, function(a, b)
    if a.position.row == b.position.row then
      return a.position.col < b.position.col
    else
      return a.position.row < b.position.row
    end
  end)
  
  return results
end

-- Generate a comparison report
function M.generate_comparison_report(file_path, output_path)
  log("Generating comparison report for: " .. file_path)
  
  local comparison = M.compare_highlighting(file_path)
  output_path = output_path or (config.output_dir .. "/highlight_comparison.txt")
  
  -- Ensure output directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(output_path, ":h"), "p")
  
  -- Write to file
  local file = io.open(output_path, "w")
  if file then
    file:write("TAMARIN SYNTAX HIGHLIGHTING COMPARISON\n")
    file:write("=====================================\n\n")
    file:write("File: " .. file_path .. "\n")
    file:write("Date: " .. os.date() .. "\n\n")
    
    file:write("Found " .. #comparison .. " highlighting positions\n\n")
    
    for _, item in ipairs(comparison) do
      file:write("Position: " .. item.position.row .. ":" .. item.position.col .. "\n")
      
      file:write("  Traditional: ")
      if #item.traditional == 0 then
        file:write("None\n")
      else
        file:write("\n")
        for _, hl in ipairs(item.traditional) do
          file:write("    " .. hl.name .. " => " .. hl.trans_name .. "\n")
        end
      end
      
      file:write("  TreeSitter: ")
      if #item.treesitter == 0 then
        file:write("None\n")
      else
        file:write("\n")
        for _, capture in ipairs(item.treesitter) do
          file:write("    @" .. capture.name .. "\n")
        end
      end
      
      file:write("\n")
    end
    
    file:close()
    log("Report written to: " .. output_path)
    return true
  else
    log("Failed to write report", vim.log.levels.ERROR)
    return false
  end
end

-- Test specific query pattern
function M.run_query_test(query_pattern, file_path)
  log("Running query test on: " .. file_path)
  
  -- Check if TreeSitter is available
  if not is_treesitter_available() then
    log("TreeSitter not available for Tamarin", vim.log.levels.ERROR)
    return false, {}
  end
  
  -- Open the file in a buffer
  local bufnr = vim.fn.bufadd(file_path)
  vim.fn.bufload(bufnr)
  
  -- Get parser
  local parser = vim.treesitter.get_parser(bufnr, "spthy")
  if not parser then
    log("Failed to get parser", vim.log.levels.ERROR)
    return false, {}
  end
  
  -- Get tree
  local tree = parser:parse()[1]
  if not tree then
    log("Failed to parse tree", vim.log.levels.ERROR)
    return false, {}
  end
  
  -- Get root
  local root = tree:root()
  if not root then
    log("Failed to get root node", vim.log.levels.ERROR)
    return false, {}
  end
  
  -- Use provided query pattern or get highlights query
  local query
  if query_pattern then
    query = vim.treesitter.query.parse("spthy", query_pattern)
  else
    query = vim.treesitter.query.get("spthy", "highlights")
  end
  
  if not query then
    log("Failed to get query", vim.log.levels.ERROR)
    return false, {}
  end
  
  -- Get all captures
  local results = {}
  for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
    local range = {node:range()}
    local start_row, start_col, end_row, end_col = unpack(range)
    local name = query.captures[id]
    
    local text
    if start_row == end_row then
      local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
      text = line:sub(start_col + 1, end_col)
    else
      text = "<multiline>"
    end
    
    table.insert(results, {
      id = id,
      name = name,
      node_type = node:type(),
      range = { row = start_row + 1, col = start_col + 1, end_row = end_row + 1, end_col = end_col + 1 },
      text = text
    })
  end
  
  -- Write report
  local output_path = config.output_dir .. "/query_test_report.txt"
  local file = io.open(output_path, "w")
  
  if file then
    file:write("TAMARIN QUERY TEST REPORT\n")
    file:write("=======================\n\n")
    file:write("File: " .. file_path .. "\n")
    file:write("Date: " .. os.date() .. "\n\n")
    
    file:write("Found " .. #results .. " captures\n\n")
    
    for _, item in ipairs(results) do
      file:write(string.format("%s:%d:%d-%d:%d \"%s\" [%s]\n", 
        item.name,
        item.range.row, 
        item.range.col,
        item.range.end_row,
        item.range.end_col,
        item.text,
        item.node_type
      ))
    end
    
    file:close()
    log("Report written to: " .. output_path)
  else
    log("Failed to write report", vim.log.levels.ERROR)
  end
  
  return #results > 0, results
end

return M 