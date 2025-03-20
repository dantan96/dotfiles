# Project Rainbow: A Glorious Colour Inspecting Script

## The Challenge

Debugging and testing syntax highlighting in Neovim is challenging because:

1. Highlight groups are applied to text at runtime
2. Matching is done through complex TreeSitter queries or regex patterns
3. Visualization requires seeing the text with actual colors applied
4. It's difficult to verify if specific tokens are getting the intended highlight groups

This document outlines a comprehensive approach to systematically test, debug, and improve syntax highlighting for Tamarin (.spthy) files, with tools that could work for any language.

## Proposed Solution: The Syntax Inspector

We'll create a script that can:
1. Find specific text patterns in .spthy files
2. Determine which highlight groups are applied to those matches
3. Generate a report comparing expected vs. actual highlighting
4. Visualize the results for easy verification

### Core Components

#### 1. Text Pattern Matcher

```lua
-- Find all occurrences of a pattern in a file
local function find_pattern_matches(file_path, pattern)
  local matches = {}
  local content = vim.fn.readfile(file_path)
  
  for line_num, line in ipairs(content) do
    local start_idx, end_idx = line:find(pattern)
    while start_idx do
      table.insert(matches, {
        line = line_num,
        col_start = start_idx,
        col_end = end_idx,
        text = line:sub(start_idx, end_idx)
      })
      start_idx, end_idx = line:find(pattern, end_idx + 1)
    end
  end
  
  return matches
end
```

#### 2. Highlight Group Extractor

```lua
-- Get highlight group at a specific position
local function get_highlight_at_pos(bufnr, line, col)
  -- Get treesitter captures at the position
  local ts_captures = vim.treesitter.get_captures_at_pos(bufnr, line-1, col-1)
  
  -- Get syntax stack (for traditional syntax highlighting)
  local syntax_id = vim.fn.synID(line, col, true)
  local syntax_name = vim.fn.synIDattr(syntax_id, "name")
  
  return {
    ts_captures = ts_captures,
    syntax_id = syntax_id,
    syntax_name = syntax_name,
    trans_id = vim.fn.synIDtrans(syntax_id),
    trans_name = vim.fn.synIDattr(vim.fn.synIDtrans(syntax_id), "name"),
    fg_color = vim.fn.synIDattr(vim.fn.synIDtrans(syntax_id), "fg#")
  }
end
```

#### 3. Results Reporter

```lua
-- Generate report comparing expected vs actual highlighting
local function generate_report(matches, highlights, expected)
  local report = {
    matches = #matches,
    correct = 0,
    incorrect = {},
    summary = {}
  }
  
  for i, match in ipairs(matches) do
    local highlight = highlights[i]
    local expected_group = expected[match.text] or expected._default
    
    if highlight.trans_name == expected_group then
      report.correct = report.correct + 1
    else
      table.insert(report.incorrect, {
        match = match,
        actual = highlight.trans_name,
        expected = expected_group
      })
    end
    
    -- Update summary stats
    report.summary[highlight.trans_name] = (report.summary[highlight.trans_name] or 0) + 1
  end
  
  return report
end
```

#### 4. Visualization Generator

```lua
-- Create HTML visualization of highlighting
local function generate_html_visualization(file_path, matches, highlights)
  local content = vim.fn.readfile(file_path)
  local html = {"<html><head><style>"}
  
  -- Add styles for different highlight groups
  for _, hl in ipairs(highlights) do
    local fg = hl.fg_color or "#ffffff"
    html[#html+1] = string.format(".%s { color: %s; }", 
                                 hl.trans_name:gsub("[^%w]", "_"), 
                                 fg)
  end
  
  html[#html+1] = "</style></head><body><pre>"
  
  -- Create a mapping of positions to highlight info
  local pos_to_hl = {}
  for i, match in ipairs(matches) do
    local key = match.line .. ":" .. match.col_start .. "-" .. match.col_end
    pos_to_hl[key] = highlights[i]
  end
  
  -- Generate highlighted HTML
  for line_num, line in ipairs(content) do
    local segments = {}
    local last_end = 0
    
    -- Find all highlights for this line
    local line_matches = {}
    for i, match in ipairs(matches) do
      if match.line == line_num then
        table.insert(line_matches, {
          start = match.col_start,
          end_col = match.col_end,
          hl = highlights[i]
        })
      end
    end
    
    -- Sort by start position
    table.sort(line_matches, function(a, b) return a.start < b.start end)
    
    -- Build line with spans for highlighted sections
    for _, m in ipairs(line_matches) do
      if m.start > last_end + 1 then
        segments[#segments+1] = vim.fn.htmlspecialchars(line:sub(last_end + 1, m.start - 1))
      end
      
      segments[#segments+1] = string.format(
        '<span class="%s" title="%s">%s</span>',
        m.hl.trans_name:gsub("[^%w]", "_"),
        m.hl.trans_name,
        vim.fn.htmlspecialchars(line:sub(m.start, m.end_col))
      )
      
      last_end = m.end_col
    end
    
    -- Add any remaining text
    if last_end < #line then
      segments[#segments+1] = vim.fn.htmlspecialchars(line:sub(last_end + 1))
    end
    
    html[#html+1] = table.concat(segments) .. "\n"
  end
  
  html[#html+1] = "</pre></body></html>"
  return table.concat(html)
end
```

## Usage Example

Here's how you might use this script to test highlighting:

```lua
-- Load a test file and define expected highlight groups
local expected_highlights = {
  ["function"] = "Function",
  ["rule"] = "Keyword", 
  ["let"] = "Keyword",
  ["in"] = "Keyword",
  ["F"] = "SpthyFact",
  ["Fr"] = "SpthyFresh",
  ["Out"] = "SpthyMessage",
  ["~>"] = "SpthyOperator",
  ["=="] = "SpthyOperator",
  ["==>"] = "SpthyArrow",
  ["-->"] = "SpthyArrow",
  ["-->*"] = "SpthyArrow",
  ["'"] = "SpthyApostrophe",
  ["\""] = "String",
  ["//"] = "Comment",
  ["/*"] = "Comment",
  ["protocol"] = "SpthySection",
  ["builtins"] = "SpthySection",
  ["rule"] = "SpthyRule",
  ["lemma"] = "SpthyLemma",
  ["restriction"] = "SpthyRestriction",
  ["_default"] = "Normal"  -- Fallback for unspecified patterns
}

-- Configuration for inspection
local config = {
  file = "test.spthy",
  patterns = {
    "function%s+%w+", "rule%s+%w+", "lemma%s+%w+",
    "F%([^)]*%)", "Fr%([^)]*%)", "Out%([^)]*%)",
    "~>", "==", "==>", "-->", "-->%*",
    "'%w+'", "\"[^\"]*\"", "//[^\n]*", "/%*.*%*/",
    "protocol", "builtins", "rule", "lemma", "restriction"
  }
}

-- Run the inspection
local results = inspect_syntax_highlighting(config.file, config.patterns, expected_highlights)

-- Generate a report file
local report_path = "syntax_report.md"
local report_content = generate_markdown_report(results)
vim.fn.writefile(vim.split(report_content, "\n"), report_path)

-- Generate HTML visualization
local html_path = "syntax_visualization.html"
local html_content = generate_html_visualization(config.file, results.matches, results.highlights)
vim.fn.writefile(vim.split(html_content, "\n"), html_path)

print("Inspection complete! Report saved to " .. report_path)
print("Visualization saved to " .. html_path)
```

## Complete Implementation

Here's a complete implementation of the syntax inspector script that can be saved as `syntax_inspector.lua`:

```lua
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
```

## Example Configuration

Save this as `syntax_inspector_config.lua`:

```lua
return {
  -- File to analyze
  file_path = "test.spthy",
  
  -- Output paths
  output_report = "syntax_report.md",
  output_html = "syntax_visualization.html",
  
  -- Patterns to match
  patterns = {
    -- Keywords
    "function", "rule", "lemma", "let", "in", "protocol", "builtins", "restriction",
    
    -- Facts and terms
    "F%([^)]*%)", "Fr%([^)]*%)", "Out%([^)]*%)",
    
    -- Operators
    "~>", "==", "==>", "-->", "-->%*",
    
    -- Literals
    "'%w+'", "\"[^\"]*\"", 
    
    -- Comments
    "//[^\n]*", "/%*.*%*/"
  },
  
  -- Expected highlight groups
  expected_highlights = {
    -- Keywords
    ["function"] = "Function",
    ["rule"] = "Keyword", 
    ["let"] = "Keyword",
    ["in"] = "Keyword",
    
    -- Facts and terms
    ["F"] = "SpthyFact",
    ["Fr"] = "SpthyFresh",
    ["Out"] = "SpthyMessage",
    
    -- Operators
    ["~>"] = "SpthyOperator",
    ["=="] = "SpthyOperator",
    ["==>"] = "SpthyArrow",
    ["-->"] = "SpthyArrow",
    ["-->%*"] = "SpthyArrow",
    
    -- Literals
    ["'"] = "SpthyApostrophe",
    ["\""] = "String",
    
    -- Comments
    ["//"] = "Comment",
    ["/%*"] = "Comment",
    
    -- Sections
    ["protocol"] = "SpthySection",
    ["builtins"] = "SpthySection",
    
    -- Special keywords
    ["rule"] = "SpthyRule",
    ["lemma"] = "SpthyLemma",
    ["restriction"] = "SpthyRestriction",
    
    -- Default fallback
    ["_default"] = "Normal"
  }
}
```

## Usage

1. Save the scripts above to your Neovim configuration directory
2. Test your syntax highlighting with:

```vim
:lua require('syntax_inspector').create_commands()
:SyntaxInspect
```

## Benefits

This approach offers several advantages:

1. **Systematic Testing**: You can specify patterns and expected highlight groups to test specific syntax elements
2. **Visual Feedback**: The HTML visualization shows exactly how your syntax is highlighted
3. **Detailed Reports**: The generated markdown report provides statistics and identifies incorrect highlights
4. **Iterative Improvement**: Run the test after each modification to your highlight queries to see improvement
5. **Documentation**: The reports serve as documentation for your syntax highlighting design

## Future Enhancements

1. **Interactive Mode**: An in-editor UI to select text and see its highlighting information
2. **Batch Testing**: Test multiple files against the same highlighting expectations
3. **Auto-Fix Suggestions**: Suggest modifications to highlight queries based on incorrect matches
4. **Highlight Group Explorer**: Preview all available highlight groups in your current colorscheme

With these tools, you can systematically debug and improve your syntax highlighting for any language, making the process much more scientific and less based on trial and error. 