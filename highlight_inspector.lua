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

-- Get RGB values from color name or hex
local function get_rgb_from_color(color_name)
  if not color_name or color_name == "" or color_name == "default" or color_name == "NONE" then
    return { r = nil, g = nil, b = nil, hex = "default" }
  end
  
  -- If it's already a hex value, convert it to RGB
  if color_name:match("^#%x%x%x%x%x%x$") then
    local r = tonumber(color_name:sub(2, 3), 16)
    local g = tonumber(color_name:sub(4, 5), 16)
    local b = tonumber(color_name:sub(6, 7), 16)
    return { r = r, g = g, b = b, hex = color_name }
  end
  
  -- Try to get RGB values for named colors using Neovim API
  -- First check if it's a built-in color
  local rgb = nil
  pcall(function()
    -- Try to get color using eval of :highlight
    local cmd = "silent! highlight " .. color_name
    vim.cmd(cmd)
    rgb = vim.api.nvim_get_color_by_name(color_name)
  end)
  
  if rgb and rgb > 0 then
    local r = bit.band(bit.rshift(rgb, 16), 0xFF)
    local g = bit.band(bit.rshift(rgb, 8), 0xFF)
    local b = bit.band(rgb, 0xFF)
    local hex = string.format("#%02x%02x%02x", r, g, b)
    return { r = r, g = g, b = b, hex = hex }
  end
  
  -- If we get here, we couldn't resolve the color
  return { r = nil, g = nil, b = nil, hex = color_name .. " (unresolved)" }
end

-- Get actual color value from highlight group
local function get_highlight_colors(group_name)
  if group_name == "" then
    return { fg = "default", bg = "default" }
  end
  
  -- Get highlight definition
  local output = vim.api.nvim_exec2("highlight " .. group_name, { output = true }).output
  
  -- Extract foreground and background colors
  local fg_name = output:match("guifg=([#%w]+)")
  local bg_name = output:match("guibg=([#%w]+)")
  
  -- Try to convert named colors to hex
  local fg_rgb = get_rgb_from_color(fg_name)
  local bg_rgb = get_rgb_from_color(bg_name)
  
  return { 
    fg_name = fg_name or "default",
    bg_name = bg_name or "default",
    fg_hex = fg_rgb.hex,
    bg_hex = bg_rgb.hex,
    def = output -- Store the full definition
  }
end

-- Check if TreeSitter is active for this buffer
local function is_treesitter_active(bufnr)
  -- Check if the TreeSitter highlighter is active for this buffer
  local active = false
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  if vim.treesitter and vim.treesitter.highlighter then
    active = vim.treesitter.highlighter.active[bufnr] ~= nil
  end
  
  -- If active, try to get the language
  local lang = nil
  if active then
    pcall(function()
      lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    end)
  end
  
  -- Check parser
  local parser_ok = false
  if lang then
    parser_ok = pcall(vim.treesitter.language.inspect, lang)
  end
  
  return {
    active = active,
    language = lang or vim.bo[bufnr].filetype,
    parser_ok = parser_ok
  }
end

-- Get highlight information for each match
local function get_highlight_info(matches)
  local results = {}
  local bufnr = vim.api.nvim_get_current_buf()
  local highlight_cache = {} -- Cache for highlight definitions
  
  -- Check TreeSitter status
  local ts_status = is_treesitter_active(bufnr)
  
  for _, match in ipairs(matches) do
    local line, col = match.line, match.col_start
    
    -- Get syntax highlight info
    local syntax_id = vim.fn.synID(line, col, true)
    local syntax_name = vim.fn.synIDattr(syntax_id, "name")
    local trans_id = vim.fn.synIDtrans(syntax_id)
    local trans_name = vim.fn.synIDattr(trans_id, "name")
    
    -- Get actual colors from highlight group
    local colors = nil
    if highlight_cache[trans_name] then
      colors = highlight_cache[trans_name]
    else
      colors = get_highlight_colors(trans_name)
      highlight_cache[trans_name] = colors
    end
    
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
        fg_name = colors.fg_name,
        bg_name = colors.bg_name,
        fg_hex = colors.fg_hex,
        bg_hex = colors.bg_hex,
        definition = colors.def
      },
      captures = capture_names,
      ts_status = ts_status
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
  
  -- Show TreeSitter status if available
  if #results > 0 and results[1].ts_status then
    local status = results[1].ts_status
    output = output .. "## TreeSitter Status\n\n"
    output = output .. "- TreeSitter active: " .. tostring(status.active) .. "\n"
    output = output .. "- Language: " .. status.language .. "\n"
    output = output .. "- Parser OK: " .. tostring(status.parser_ok) .. "\n\n"
  end
  
  output = output .. "## Found " .. #results .. " matches\n\n"
  output = output .. "| Line:Col | Text | Highlight Group | Foreground | Background | TreeSitter Captures |\n"
  output = output .. "|----------|------|----------------|------------|------------|---------------------|\n"
  
  for _, result in ipairs(results) do
    local match = result.match
    local syntax = result.syntax
    local capture_list = table.concat(result.captures, ", ")
    if capture_list == "" then capture_list = "None" end
    
    -- Format foreground and background as "Name (Hex)"
    local fg_display = syntax.fg_name
    if syntax.fg_hex ~= syntax.fg_name then
      fg_display = syntax.fg_name .. " (" .. syntax.fg_hex .. ")"
    end
    
    local bg_display = syntax.bg_name
    if syntax.bg_hex ~= syntax.bg_name then
      bg_display = syntax.bg_name .. " (" .. syntax.bg_hex .. ")"
    end
    
    output = output .. string.format(
      "| %d:%d-%d | `%s` | %s | %s | %s | %s |\n", 
      match.line, 
      match.col_start, 
      match.col_end, 
      match.text:gsub("|", "\\|"), 
      syntax.trans_name ~= "" and syntax.trans_name or "None",
      fg_display,
      bg_display,
      capture_list
    )
  end
  
  -- Add section for highlight definitions
  output = output .. "\n## Highlight Group Definitions\n\n"
  
  -- Track unique highlight groups
  local seen_groups = {}
  
  for _, result in ipairs(results) do
    local group = result.syntax.trans_name
    if group ~= "" and not seen_groups[group] then
      seen_groups[group] = true
      output = output .. "### " .. group .. "\n\n"
      output = output .. "```\n" .. result.syntax.definition .. "\n```\n\n"
    end
  end
  
  -- Add note about traditional syntax vs TreeSitter
  output = output .. "## Notes\n\n"
  if #results > 0 and results[1].ts_status then
    local status = results[1].ts_status
    if status.active then
      output = output .. "* Highlighting is using TreeSitter.\n"
      if #results[1].captures == 0 then
        output = output .. "* No TreeSitter captures found for the matched text. This suggests the TreeSitter grammar doesn't specifically recognize these tokens.\n"
      end
    else
      output = output .. "* Highlighting is using traditional Vim syntax highlighting, not TreeSitter.\n"
      output = output .. "* Consider checking if the TreeSitter parser for this language is installed and properly configured.\n"
    end
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