-- Syntax Highlight Inspector for Neovim
-- Checks highlighting information for specified patterns in files

local M = {}

-- Find all occurrences of a pattern in a file
local function find_matches(file_path, patterns)
  local matches = {}
  local content = vim.fn.readfile(file_path)
  
  for _, pattern in ipairs(patterns) do
    for line_num, line in ipairs(content) do
      local start_idx, end_idx = line:find(pattern)
      while start_idx do
        table.insert(matches, {
          line = line_num,
          col_start = start_idx,
          col_end = end_idx,
          text = line:sub(start_idx, end_idx),
          pattern = pattern
        })
        start_idx, end_idx = line:find(pattern, end_idx + 1)
      end
    end
  end
  
  -- Sort matches by line and column
  table.sort(matches, function(a, b)
    if a.line == b.line then
      return a.col_start < b.col_start
    end
    return a.line < b.line
  end)
  
  return matches
end

-- Get highlight information for each match
local function get_highlight_info(matches)
  local results = {}
  local bufnr = vim.api.nvim_get_current_buf()
  
  for _, match in ipairs(matches) do
    local line, col = match.line, match.col_start
    
    -- Get syntax highlight info
    local syntax_id = vim.fn.synID(line, col, true)
    local syntax_name = vim.fn.synIDattr(syntax_id, "name")
    local trans_id = vim.fn.synIDtrans(syntax_id)
    local trans_name = vim.fn.synIDattr(trans_id, "name")
    local fg_color = vim.fn.synIDattr(trans_id, "fg#")
    local bg_color = vim.fn.synIDattr(trans_id, "bg#")
    
    -- Get TreeSitter captures
    local ts_captures = {}
    pcall(function()
      ts_captures = vim.treesitter.get_captures_at_pos(bufnr, line-1, col-1)
    end)
    
    -- Collect capture names
    local capture_names = {}
    for _, capture in ipairs(ts_captures or {}) do
      table.insert(capture_names, capture.capture)
    end
    
    -- Build result
    table.insert(results, {
      match = match,
      syntax = {
        name = syntax_name,
        trans_name = trans_name,
        fg_color = fg_color ~= "" and fg_color or "default",
        bg_color = bg_color ~= "" and bg_color or "default",
      },
      captures = capture_names
    })
  end
  
  return results
end

-- Format results as readable text
local function format_results(results)
  local output = "# Syntax Highlight Inspection Results\n\n"
  
  if #results == 0 then
    return output .. "No matches found.\n"
  end
  
  output = output .. "## Found " .. #results .. " matches\n\n"
  output = output .. "| Line:Col | Text | Highlight Group | Color | TreeSitter Captures |\n"
  output = output .. "|----------|------|----------------|-------|---------------------|\n"
  
  for _, result in ipairs(results) do
    local match = result.match
    local syntax = result.syntax
    local capture_list = table.concat(result.captures, ", ")
    if capture_list == "" then capture_list = "None" end
    
    output = output .. string.format(
      "| %d:%d-%d | `%s` | %s | %s | %s |\n", 
      match.line, 
      match.col_start, 
      match.col_end, 
      match.text:gsub("|", "\\|"), 
      syntax.trans_name ~= "" and syntax.trans_name or "None",
      syntax.fg_color ~= "" and syntax.fg_color or "default",
      capture_list
    )
  end
  
  return output
end

-- Main inspection function
function M.inspect(file_path, patterns)
  -- Open or switch to the file
  vim.cmd("edit " .. vim.fn.fnameescape(file_path))
  
  -- Make sure syntax is enabled
  vim.cmd("syntax on")
  if vim.fn.exists(":TSBufEnable") == 2 then
    vim.cmd("TSBufEnable highlight")
  end
  
  -- Give it a moment to load syntax
  vim.cmd("sleep 200m")
  
  -- Find matches
  local matches = find_matches(file_path, patterns)
  
  -- Get highlight info
  local results = get_highlight_info(matches)
  
  -- Format and return results
  return format_results(results)
end

-- Command to inspect highlights
function M.setup_command()
  vim.api.nvim_create_user_command("HighlightInspect", function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    if #args < 2 then
      vim.notify("Usage: HighlightInspect <file_path> <pattern1> [pattern2] [pattern3] ...", vim.log.levels.ERROR)
      return
    end
    
    local file_path = args[1]
    local patterns = {}
    for i = 2, #args do
      table.insert(patterns, args[i])
    end
    
    local results = M.inspect(file_path, patterns)
    
    -- Save results to a file
    local output_file = "highlight_inspection_results.md"
    local f = io.open(output_file, "w")
    if f then
      f:write(results)
      f:close()
      vim.notify("Results saved to " .. output_file, vim.log.levels.INFO)
    else
      vim.notify("Failed to write results to file", vim.log.levels.ERROR)
      -- Show in a split instead
      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(results, "\n"))
    end
  end, {
    nargs = "+",
    complete = "file",
    desc = "Inspect syntax highlighting for patterns in a file"
  })
end

-- Inspect command with API for scripting
function M.run_inspection(file_path, patterns)
  -- Convert patterns to array if a single string was passed
  if type(patterns) == "string" then
    patterns = {patterns}
  end
  
  local results = M.inspect(file_path, patterns)
  
  local output_file = "highlight_inspection_results.md"
  local f = io.open(output_file, "w")
  if f then
    f:write(results)
    f:close()
    print("Results saved to " .. output_file)
  else
    print("Failed to save results. Here they are:")
    print(results)
  end
  
  return results
end

return M 