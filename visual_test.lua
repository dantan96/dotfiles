-- Visual test for Tamarin syntax highlighting
-- This script outputs a human-readable representation of the syntax highlighting

local test_file = "/Users/dan/.config/nvim/test.spthy"
local output_file = "/Users/dan/.config/nvim/highlight_visual_test.html"

-- Initialize Neovim
vim.cmd("syntax on")
vim.cmd("syntax enable")

-- Ensure the file exists
if vim.fn.filereadable(test_file) ~= 1 then
  print("Error: Test file not found: " .. test_file)
  os.exit(1)
end

-- Open the file
vim.cmd("edit " .. test_file)
vim.bo.filetype = "spthy"

-- Wait for syntax highlighting to apply
vim.cmd("sleep 200m")

-- Get the file content
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

-- Generate HTML with syntax highlighting
local html_output = {}
table.insert(html_output, [[
<!DOCTYPE html>
<html>
<head>
  <title>Tamarin Syntax Highlighting Test</title>
  <style>
    body { font-family: monospace; background-color: #1e1e1e; color: #d4d4d4; padding: 20px; }
    .line { white-space: pre; line-height: 1.5; }
    .line-number { display: inline-block; width: 30px; text-align: right; margin-right: 10px; color: #858585; }
    .keyword { color: #ff00ff; font-weight: bold; }
    .publicVar { color: #006400; }
    .freshVar { color: #ff69b4; }
    .temporalVar { color: #00bfff; }
    .persistentFact { color: #ff3030; font-weight: bold; }
    .builtinFact { color: #1e90ff; font-weight: bold; text-decoration: underline; }
    .comment { color: #777777; font-style: italic; }
    .function { color: #ff6347; font-style: italic; }
    .bracket { color: #708090; }
    .default { color: #d4d4d4; }
  </style>
</head>
<body>
  <h1>Tamarin Syntax Highlighting Test</h1>
  <p>This shows how syntax highlighting appears in the test.spthy file</p>
  <div class="code-container">
]])

-- Process each line with syntax highlighting
for line_num, line in ipairs(lines) do
  table.insert(html_output, string.format('    <div class="line"><span class="line-number">%d</span>', line_num))
  
  if line == "" then
    table.insert(html_output, " ")
  else
    local col = 1
    while col <= #line do
      -- Get syntax ID at position
      local syntax_id = vim.fn.synID(line_num, col, true)
      local syntax_name = vim.fn.synIDattr(syntax_id, "name")
      local trans_id = vim.fn.synIDtrans(syntax_id)
      local color = vim.fn.synIDattr(trans_id, "fg#")
      
      -- Map syntax groups to CSS classes
      local css_class = "default"
      if syntax_name:match("spthyKeyword") then css_class = "keyword"
      elseif syntax_name:match("spthyPublicVar") then css_class = "publicVar"
      elseif syntax_name:match("spthyFreshVar") then css_class = "freshVar"
      elseif syntax_name:match("spthyTemporalVar") then css_class = "temporalVar"
      elseif syntax_name:match("spthyPersistentFact") then css_class = "persistentFact"
      elseif syntax_name:match("spthyBuiltinFact") then css_class = "builtinFact"
      elseif syntax_name:match("spthyComment") then css_class = "comment"
      elseif syntax_name:match("spthyFunction") then css_class = "function"
      elseif syntax_name:match("spthyBracket") or syntax_name:match("spthyOperator") then css_class = "bracket"
      end
      
      -- Find the end of this syntax group
      local end_col = col
      while end_col < #line and vim.fn.synID(line_num, end_col + 1, true) == syntax_id do
        end_col = end_col + 1
      end
      
      -- Add the text with the appropriate class
      local text = line:sub(col, end_col)
      text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
      table.insert(html_output, string.format('<span class="%s" title="%s">%s</span>', css_class, syntax_name, text))
      
      col = end_col + 1
    end
  end
  
  table.insert(html_output, "</div>")
end

-- Close the HTML
table.insert(html_output, [[
  </div>
  <div style="margin-top: 20px;">
    <p><strong>Legend:</strong></p>
    <ul>
      <li><span class="keyword">Keywords</span> - theory, begin, end, rule, lemma</li>
      <li><span class="publicVar">Public Variables</span> - $A, $B</li>
      <li><span class="freshVar">Fresh Variables</span> - ~id, ~ltk</li>
      <li><span class="temporalVar">Temporal Variables</span> - #i, #j</li>
      <li><span class="persistentFact">Persistent Facts</span> - !User, !Pk</li>
      <li><span class="builtinFact">Builtin Facts</span> - Fr, In, Out, K</li>
      <li><span class="function">Functions</span> - pk(), h()</li>
      <li><span class="comment">Comments</span> - // line comments and /* block comments */</li>
    </ul>
  </div>
</body>
</html>
]])

-- Save the HTML
local file = io.open(output_file, "w")
if file then
  file:write(table.concat(html_output, "\n"))
  file:close()
  print("Visual test saved to: " .. output_file)
else
  print("Error: Could not write to output file")
end

-- Generate a text representation of the highlighting
print("\nText representation of highlighting:\n")
for line_num, line in ipairs(lines) do
  if line ~= "" then
    print(string.format("Line %2d: %s", line_num, line))
    
    -- Print syntax info for the first relevant elements in each line
    local col = 1
    local reported = {}
    while col <= #line do
      local syntax_id = vim.fn.synID(line_num, col, true)
      local syntax_name = vim.fn.synIDattr(syntax_id, "name")
      local trans_id = vim.fn.synIDtrans(syntax_id)
      local color = vim.fn.synIDattr(trans_id, "fg#")
      
      if syntax_name ~= "" and syntax_name ~= "Normal" and not reported[syntax_name] then
        local text_start = col
        local text_end = col
        while text_end < #line and vim.fn.synID(line_num, text_end + 1, true) == syntax_id do
          text_end = text_end + 1
        end
        
        local text = line:sub(text_start, text_end)
        print(string.format("  - '%s' = %s (col %d-%d) color: %s", 
                          text, syntax_name, text_start, text_end, color or "none"))
        
        reported[syntax_name] = true
      end
      
      col = col + 1
    end
  end
end

print("\nTest completed. Visual output saved to: " .. output_file)

-- Exit
vim.cmd("qa!") 