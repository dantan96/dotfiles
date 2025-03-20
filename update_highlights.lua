-- Update TreeSitter Highlights
-- This script analyzes syntax validation results and updates the highlights.scm file

-- Configuration
local highlights_scm_path = "/Users/dan/.config/nvim/queries/spthy/highlights.scm"
local validation_results = "syntax_validation_results.md"
local tamarin_colors_path = "/Users/dan/.config/nvim/lua/config/tamarin-colors.lua"

-- Utility functions
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil, "Could not open file: " .. path
  end
  
  local content = file:read("*all")
  file:close()
  return content
end

local function write_file(path, content)
  local file = io.open(path, "w")
  if not file then
    return false, "Could not open file for writing: " .. path
  end
  
  file:write(content)
  file:close()
  return true
end

-- Parse validation results to identify problems
local function parse_validation_results(content)
  if not content then
    return {}
  end
  
  local problems = {}
  
  -- Look for TreeSitter captures that aren't working correctly
  local capture_section = false
  
  for line in content:gmatch("[^\r\n]+") do
    -- Look for capture problems in markdown table
    if line:match("^|%s*Line:Col%s*|") then
      capture_section = true
    elseif capture_section and line:match("^|%s*%d+:%d+") then
      local text = line:match("|%s*%d+:%d+%-%d+%s*|%s*`([^`]+)`")
      local highlight = line:match("|%s*`[^`]+`%s*|%s*([^|]+)")
      local captures = line:match("|%s*[^|]+%s*$")
      
      -- If we have text and captures
      if text and captures then
        -- Process captures
        if captures:match("None") or captures:match("^%s*|%s*$") then
          -- This is a problem - text with no captures
          table.insert(problems, {
            type = "missing_capture",
            text = text,
            expected = "",
            current = "None"
          })
        end
      end
    end
  end
  
  return problems
end

-- Analyze the current TreeSitter highlights file
local function analyze_treesitter_highlights(content)
  if not content then 
    return {}
  end
  
  local captures = {}
  
  -- Extract current captures
  for line in content:gmatch("[^\r\n]+") do
    -- Look for capture directives like:  @keyword, @function.builtin, etc.
    local capture = line:match("@([%w%.]+)")
    if capture then
      -- Look for any predicates that might be applied (has-parent? etc.)
      local predicate = line:match("#([%w%-%?]+)")
      -- Look for any strings being matched
      local match_text = line:match("\"([^\"]+)\"")
      
      if capture then
        table.insert(captures, {
          capture = "@" .. capture,
          predicate = predicate,
          match_text = match_text,
          line = line
        })
      end
    end
  end
  
  return captures
end

-- Generate suggestions for improving the highlights.scm file
local function generate_suggestions(problems, current_captures)
  local suggestions = {}
  
  -- Group problems by type
  local missing_captures = {}
  
  for _, problem in ipairs(problems) do
    if problem.type == "missing_capture" then
      -- Try to infer what type of syntax it is
      local text = problem.text
      local category = "unknown"
      local capture = nil
      
      -- Infer type based on common patterns
      if text:match("^%$%w+") then
        category = "public variable"
        capture = "@variable.public"
      elseif text:match("^~%w+") then
        category = "fresh variable"
        capture = "@variable.fresh"
      elseif text:match("^#%w+") then
        category = "temporal variable"
        capture = "@variable.temporal"
      elseif text:match("^!%w+") then
        category = "persistent fact"
        capture = "@fact.persistent"
      elseif text:match("^%w+%(.-%)$") then
        category = "function call"
        capture = "@function"
      elseif text:match("In") or text:match("Out") or text:match("Fr") or text:match("K") then
        category = "builtin fact"
        capture = "@function.builtin"
      elseif text:match("rule") or text:match("lemma") or text:match("axiom") then
        category = "keyword"
        capture = "@keyword"
      end
      
      if capture then
        table.insert(missing_captures, {
          text = text,
          category = category,
          suggested_capture = capture
        })
      end
    end
  end
  
  -- Generate suggestions
  if #missing_captures > 0 then
    table.insert(suggestions, "## Missing Captures")
    table.insert(suggestions, "")
    table.insert(suggestions, "The following elements in your code have no TreeSitter captures:")
    table.insert(suggestions, "")
    
    for _, missing in ipairs(missing_captures) do
      table.insert(suggestions, string.format("- `%s` - Looks like a %s, should use capture: `%s`", 
        missing.text, missing.category, missing.suggested_capture))
    end
    
    table.insert(suggestions, "")
    table.insert(suggestions, "## Recommended Additions to highlights.scm")
    table.insert(suggestions, "")
    
    -- Group by capture type
    local by_capture = {}
    for _, missing in ipairs(missing_captures) do
      by_capture[missing.suggested_capture] = by_capture[missing.suggested_capture] or {}
      table.insert(by_capture[missing.suggested_capture], missing)
    end
    
    for capture, items in pairs(by_capture) do
      -- Create patterns for this capture
      local patterns = {}
      for _, item in ipairs(items) do
        -- Escape special characters for regex
        local pattern = item.text:gsub("([%(%)%.%[%]%*%+%-%?%$%^])", "%%%1")
        
        -- If it's a very specific item like "Fr", use exact match
        if #pattern < 5 then
          table.insert(patterns, "\"" .. item.text .. "\"")
        else
          -- For variables with prefix patterns
          if item.category == "public variable" then
            table.insert(patterns, "(ident) @variable.public (#match? @variable.public \"^\\$\")")
          elseif item.category == "fresh variable" then
            table.insert(patterns, "(ident) @variable.fresh (#match? @variable.fresh \"^~\")")
          elseif item.category == "temporal variable" then
            table.insert(patterns, "(ident) @variable.temporal (#match? @variable.temporal \"^#\")")
          end
        end
      end
      
      -- Only add unique patterns
      local unique_patterns = {}
      for _, pattern in ipairs(patterns) do
        unique_patterns[pattern] = true
      end
      
      if next(unique_patterns) then
        table.insert(suggestions, "```scm")
        table.insert(suggestions, ";; " .. items[1].category)
        for pattern, _ in pairs(unique_patterns) do
          table.insert(suggestions, pattern .. " " .. capture)
        end
        table.insert(suggestions, "```")
        table.insert(suggestions, "")
      end
    end
  end
  
  return table.concat(suggestions, "\n")
end

-- Main function
local function main()
  -- Read the validation results
  local validation_content, err = read_file(validation_results)
  if not validation_content then
    print("Error reading validation results: " .. (err or "unknown error"))
    return
  end
  
  -- Read the current highlights.scm
  local highlights_content, highlights_err = read_file(highlights_scm_path)
  if not highlights_content then
    print("Error reading highlights.scm: " .. (highlights_err or "unknown error"))
    return
  end
  
  -- Parse validation results
  local problems = parse_validation_results(validation_content)
  
  -- Analyze current TreeSitter captures
  local current_captures = analyze_treesitter_highlights(highlights_content)
  
  -- Generate suggestions
  local suggestions = generate_suggestions(problems, current_captures)
  
  -- Write suggestions to file
  local success, write_err = write_file("treesitter_suggestions.md", suggestions)
  if not success then
    print("Error writing suggestions: " .. (write_err or "unknown error"))
    return
  end
  
  print("Analysis complete! Found " .. #problems .. " potential issues.")
  print("Suggestions written to treesitter_suggestions.md")
  
  -- Create a backup of the current highlights.scm
  write_file(highlights_scm_path .. ".bak", highlights_content)
  print("Created backup of current highlights.scm to " .. highlights_scm_path .. ".bak")
end

-- Run the main function
main() 