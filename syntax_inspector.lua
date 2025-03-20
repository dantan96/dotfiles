-- Syntax Inspector for Neovim
-- A tool to test and verify syntax highlighting

local M = {}

-- Find all occurrences of patterns in a file
function M.find_pattern_matches(file_path, patterns)
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

-- Get highlight information at each match position
function M.get_highlight_info(bufnr, matches)
  local highlights = {}
  
  for _, match in ipairs(matches) do
    local line, col = match.line, match.col_start
    
    -- Get treesitter captures at the position
    local ts_captures = vim.treesitter.get_captures_at_pos(bufnr, line-1, col-1)
    
    -- Get syntax stack (for traditional syntax highlighting)
    local syntax_id = vim.fn.synID(line, col, true)
    local syntax_name = vim.fn.synIDattr(syntax_id, "name")
    
    table.insert(highlights, {
      ts_captures = ts_captures,
      syntax_id = syntax_id,
      syntax_name = syntax_name,
      trans_id = vim.fn.synIDtrans(syntax_id),
      trans_name = vim.fn.synIDattr(vim.fn.synIDtrans(syntax_id), "name"),
      fg_color = vim.fn.synIDattr(vim.fn.synIDtrans(syntax_id), "fg#"),
      bg_color = vim.fn.synIDattr(vim.fn.synIDtrans(syntax_id), "bg#")
    })
  end
  
  return highlights
end

-- Generate report comparing expected vs actual highlighting
function M.generate_report(matches, highlights, expected)
  local report = {
    matches = matches,
    highlights = highlights,
    total_matches = #matches,
    correct = 0,
    incorrect = {},
    summary = {},
    by_pattern = {}
  }
  
  for i, match in ipairs(matches) do
    local highlight = highlights[i]
    local pattern_text = match.text
    
    -- Find the best expected highlight group for this text
    local expected_group = nil
    for text, group in pairs(expected) do
      if text ~= "_default" and pattern_text:match(text) then
        expected_group = group
        break
      end
    end
    
    -- Use default if no specific match
    expected_group = expected_group or expected._default
    
    -- Track pattern stats
    report.by_pattern[match.pattern] = report.by_pattern[match.pattern] or {
      total = 0,
      correct = 0,
      incorrect = 0
    }
    report.by_pattern[match.pattern].total = report.by_pattern[match.pattern].total + 1
    
    -- Check if highlight matches expected
    if highlight.trans_name == expected_group then
      report.correct = report.correct + 1
      report.by_pattern[match.pattern].correct = report.by_pattern[match.pattern].correct + 1
    else
      table.insert(report.incorrect, {
        match = match,
        actual = highlight.trans_name,
        expected = expected_group
      })
      report.by_pattern[match.pattern].incorrect = report.by_pattern[match.pattern].incorrect + 1
    end
    
    -- Update summary stats
    report.summary[highlight.trans_name] = (report.summary[highlight.trans_name] or 0) + 1
  end
  
  return report
end

-- Generate a markdown report
function M.generate_markdown_report(report)
  local lines = {
    "# Syntax Highlighting Inspection Report",
    "",
    "## Summary",
    "",
    string.format("- Total matches: %d", report.total_matches),
    string.format("- Correctly highlighted: %d (%.1f%%)", 
                 report.correct, 
                 (report.correct / report.total_matches) * 100),
    string.format("- Incorrectly highlighted: %d (%.1f%%)",
                 #report.incorrect,
                 (#report.incorrect / report.total_matches) * 100),
    "",
    "## Highlight Groups Used",
    ""
  }
  
  -- List all highlight groups used
  for group, count in pairs(report.summary) do
    table.insert(lines, string.format("- `%s`: %d occurrences", group, count))
  end
  
  -- Report by pattern
  table.insert(lines, "")
  table.insert(lines, "## Results by Pattern")
  table.insert(lines, "")
  
  for pattern, stats in pairs(report.by_pattern) do
    local success_rate = (stats.correct / stats.total) * 100
    table.insert(lines, string.format("### Pattern: `%s`", pattern))
    table.insert(lines, string.format("- Total: %d", stats.total))
    table.insert(lines, string.format("- Correct: %d (%.1f%%)", stats.correct, success_rate))
    table.insert(lines, string.format("- Incorrect: %d (%.1f%%)", stats.incorrect, 100-success_rate))
    table.insert(lines, "")
  end
  
  -- List incorrect matches
  if #report.incorrect > 0 then
    table.insert(lines, "## Incorrect Highlights")
    table.insert(lines, "")
    table.insert(lines, "| Line | Column | Text | Expected | Actual |")
    table.insert(lines, "|------|--------|------|----------|--------|")
    
    for _, item in ipairs(report.incorrect) do
      table.insert(lines, string.format("| %d | %d-%d | `%s` | `%s` | `%s` |",
                                      item.match.line,
                                      item.match.col_start,
                                      item.match.col_end,
                                      item.match.text:gsub("|", "\\|"),
                                      item.expected,
                                      item.actual))
    end
  end
  
  return table.concat(lines, "\n")
end

-- Generate HTML visualization
function M.generate_html_visualization(file_path, matches, highlights)
  local content = vim.fn.readfile(file_path)
  local html = {[[
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Syntax Highlighting Visualization</title>
  <style>
    body { background: #1e1e1e; color: #d4d4d4; font-family: monospace; }
    pre { padding: 10px; }
    .line { display: block; }
    .line:hover { background: rgba(255,255,255,0.1); }
    .line-number { 
      display: inline-block; 
      width: 40px; 
      color: #888; 
      user-select: none; 
    }
    .highlight { border-bottom: 1px dotted rgba(255,255,255,0.3); }
    .highlight:hover { background: rgba(255,255,255,0.1); }
    .legend { 
      position: fixed; 
      top: 10px; 
      right: 10px; 
      background: rgba(0,0,0,0.8); 
      padding: 10px; 
      border: 1px solid #444; 
    }
    .legend-item {
      margin: 5px 0;
      padding: 2px 5px;
    }
  </style>
</head>
<body>
  <h1>Syntax Highlighting Visualization</h1>
  <div class="legend">
    <h3>Highlight Groups</h3>
]]}
  
  -- Build map of highlight groups and colors
  local groups = {}
  for _, hl in ipairs(highlights) do
    if not groups[hl.trans_name] then
      groups[hl.trans_name] = {
        name = hl.trans_name,
        fg = hl.fg_color or "#ffffff",
        bg = hl.bg_color or "transparent",
        count = 1
      }
    else
      groups[hl.trans_name].count = groups[hl.trans_name].count + 1
    end
  end
  
  -- Add legend entries
  for _, group in pairs(groups) do
    html[#html+1] = string.format([[
    <div class="legend-item %s" style="color: %s; background: %s;">
      %s (%d)
    </div>]], 
    group.name:gsub("[^%w]", "_"), 
    group.fg, 
    group.bg, 
    group.name,
    group.count)
  end
  
  html[#html+1] = [[
  </div>
  <pre>]]
  
  -- Create position to highlight mapping
  local pos_map = {}
  for i, match in ipairs(matches) do
    pos_map[match.line] = pos_map[match.line] or {}
    pos_map[match.line][match.col_start] = {
      match = match,
      highlight = highlights[i]
    }
  end
  
  -- Generate code with highlights
  for line_num, line in ipairs(content) do
    html[#html+1] = string.format('<span class="line"><span class="line-number">%d</span>', line_num)
    
    if pos_map[line_num] then
      local chars = {}
      for i = 1, #line do
        chars[i] = { char = line:sub(i, i), hl = nil }
      end
      
      -- Apply highlights
      for col, info in pairs(pos_map[line_num]) do
        local match, hl = info.match, info.highlight
        for i = match.col_start, match.col_end do
          chars[i].hl = hl
        end
      end
      
      -- Build the line with spans
      local i = 1
      while i <= #line do
        if chars[i].hl then
          local hl = chars[i].hl
          local start = i
          while i <= #line and chars[i].hl == hl do
            i = i + 1
          end
          
          local text = line:sub(start, i-1)
          text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
          
          html[#html+1] = string.format(
            '<span class="highlight %s" style="color: %s; background: %s;" title="%s">%s</span>',
            hl.trans_name:gsub("[^%w]", "_"),
            hl.fg_color or "inherit",
            hl.bg_color or "transparent",
            hl.trans_name,
            text
          )
        else
          local start = i
          while i <= #line and not chars[i].hl do
            i = i + 1
          end
          
          local text = line:sub(start, i-1)
          text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
          
          html[#html+1] = text
        end
      end
    else
      -- No highlights on this line
      html[#html+1] = line:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    end
    
    html[#html+1] = '</span>'
  end
  
  html[#html+1] = "</pre></body></html>"
  return table.concat(html, "\n")
end

-- Main function to inspect syntax highlighting
function M.inspect_syntax_highlighting(file_path, patterns, expected_highlights)
  -- Open the file in a new buffer
  local bufnr = vim.fn.bufadd(file_path)
  vim.fn.bufload(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  
  -- Ensure syntax is enabled
  vim.cmd("syntax on")
  if vim.fn.exists(":TSBufEnable") == 2 then
    vim.cmd("TSBufEnable highlight")
  end
  
  -- Wait a bit for highlighting to apply
  vim.cmd("sleep 100m")
  
  -- Find pattern matches
  local matches = M.find_pattern_matches(file_path, patterns)
  
  -- Get highlight information
  local highlights = M.get_highlight_info(bufnr, matches)
  
  -- Generate report
  local report = M.generate_report(matches, highlights, expected_highlights)
  
  return report
end

-- Command to run the inspector
function M.create_commands()
  vim.api.nvim_create_user_command("SyntaxInspect", function(opts)
    -- Load configuration from a file if provided
    local config_file = opts.args ~= "" and opts.args or "syntax_inspector_config.lua"
    
    local config, err = loadfile(config_file)
    if not config then
      print("Error loading config file: " .. (err or "unknown error"))
      return
    end
    
    local cfg = config()
    local results = M.inspect_syntax_highlighting(
      cfg.file_path, 
      cfg.patterns, 
      cfg.expected_highlights
    )
    
    -- Generate and save report
    local report = M.generate_markdown_report(results)
    vim.fn.writefile(vim.split(report, "\n"), cfg.output_report or "syntax_report.md")
    
    -- Generate and save visualization
    local html = M.generate_html_visualization(
      cfg.file_path, 
      results.matches, 
      results.highlights
    )
    vim.fn.writefile(vim.split(html, "\n"), cfg.output_html or "syntax_visualization.html")
    
    print("Syntax inspection complete!")
    print("Report saved to: " .. (cfg.output_report or "syntax_report.md"))
    print("Visualization saved to: " .. (cfg.output_html or "syntax_visualization.html"))
  end, {
    nargs = "?",
    desc = "Run syntax inspector with optional config file"
  })
end

return M 