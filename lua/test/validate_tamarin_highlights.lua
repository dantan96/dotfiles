-- validate_tamarin_highlights.lua
-- A specialized validator for the tamarin highlights.scm file that checks for common issues
-- and validates against the Tamarin grammar

-- Load the general validator module
local validator = require('test.treesitter_query_validator')

-- Tamarin-specific validation
local M = {}

-- List of valid node types in Tamarin grammar
local TAMARIN_VALID_NODE_TYPES = {
  "theory", "begin", "end", "rule", "lemma", "restriction", "functions",
  "builtins", "let", "in", "tactic", "heuristic", "process", "equations",
  "predicates", "options", "axiom", "configuration", "export",
  "multi_comment", "single_comment", "preprocessor", "ifdef", "define", "include",
  "macro_identifier", "pub_var", "fresh_var", "msg_var_or_nullary_fun",
  "temporal_var", "nat_var", "ident", "linear_fact", "persistent_fact", "action_fact",
  "nary_app", "pub_name", "literal_string", "built_ins", "built_in", "rule_name", 
  "tactic", "theory_name", "lemma_name"
}

-- String literals that should be used instead of node types
local STRING_LITERALS_TO_USE = {
  "macro", "macros", "all", "exists", "global"
}

-- Known problematic node types that have been fixed
local KNOWN_INVALID_NODE_TYPES = {
  "global", "all", "exists", "macro", "macros"  -- These were removed from the Tamarin grammar or never existed
}

-- Recommended fallback strategies
local FALLBACK_STRATEGIES = {
  macro = {
    recommended = "Use string literal pattern instead: [\"macro\" \"macros\"] @keyword",
    alternative = "Or use pattern matching with (#eq?) on identifiers"
  },
  all = {
    recommended = "Use in literal array [\"All\" \"all\"] @operator.logical",
    alternative = "Or match using (#eq?) predicate on identifiers"
  },
  exists = {
    recommended = "Use in literal array [\"exists\"] @operator.logical",
    alternative = "Or match using (#eq?) predicate on identifiers"
  }
}

-- Function to suggest content improvements
local function suggest_content_improvements(content)
  local suggestions = {}
  
  -- Check if the file is using parent-based matching (Strategy 2.2)
  if not content:match("%(macro_block") and not content:match("%(theory") then
    table.insert(suggestions, {
      type = "missing_parent_matching",
      message = "Consider using parent-based matching (Strategy 2.2 from ELABORATE_TREESITTER_STRATEGIES.md)",
      example = [[
;; Example of parent-based matching:
(theory
  (ident) @theory.name)
      ]]
    })
  end
  
  -- Check if using #eq? predicate for operators (Strategy 2.1)
  if not content:match("#eq%?") then
    table.insert(suggestions, {
      type = "missing_eq_predicate",
      message = "Consider using #eq? predicate for more specific matches (Strategy 2.1)",
      example = [[
;; Example of using #eq? predicate:
((ident) @keyword
 (#eq? @keyword "tactic"))
      ]]
    })
  end
  
  return suggestions
end

-- Function to validate the pattern approach used in the file
local function validate_pattern_approach(content)
  local results = {
    issues = {},
    recommendations = {}
  }
  
  -- 1. Check for invalid node types in parenthesized form
  for _, invalid_type in ipairs(KNOWN_INVALID_NODE_TYPES) do
    if content:match("%((" .. invalid_type .. ")%)") then
      table.insert(results.issues, {
        type = "invalid_node_type_parenthesized",
        node_type = invalid_type,
        message = string.format("Invalid node type found as pattern: (%s)", invalid_type),
        location = "Search for: (" .. invalid_type .. ")"
      })
      
      -- Add recommendation if available
      if FALLBACK_STRATEGIES[invalid_type] then
        table.insert(results.recommendations, {
          for_issue = "invalid_node_type_parenthesized",
          node_type = invalid_type,
          recommendation = FALLBACK_STRATEGIES[invalid_type].recommended,
          alternative = FALLBACK_STRATEGIES[invalid_type].alternative
        })
      end
    end
  end
  
  -- 2. Check for proper use of string literals
  for _, literal in ipairs(STRING_LITERALS_TO_USE) do
    if not content:match('"' .. literal .. '"') and 
       not content:match("%[.*\"" .. literal .. "\".*%]") then
      table.insert(results.issues, {
        type = "missing_string_literal",
        literal = literal,
        message = string.format('String literal "%s" should be used as a keyword pattern', literal),
        recommendation = string.format('Add "%s" to a string array like ["theory" "begin" ... "%s" ...]', 
                                       literal, literal)
      })
    end
  end
  
  return results
end

-- Function to validate and fix the highlights.scm file
function M.validate_and_fix_highlights(path, auto_fix)
  local path = path or vim.fn.stdpath('config') .. '/queries/tamarin/highlights.scm'
  local auto_fix = auto_fix or false

  -- Read the file content
  local file = io.open(path, "r")
  if not file then
    print("Error: Could not open " .. path)
    return false
  end

  local content = file:read("*all")
  file:close()

  print("\n" .. string.rep("=", 80))
  print("Validating Tamarin highlights.scm file: " .. path)
  print(string.rep("=", 80))

  -- First use the general validator
  local results = validator.validate_query("tamarin", "highlights", content)
  local valid = true

  -- Print general validation errors
  if #results.errors > 0 then
    print("\nErrors:")
    for _, err in ipairs(results.errors) do
      print("  - " .. err.message)
      valid = false
    end
  end

  if #results.warnings > 0 then
    print("\nWarnings:")
    for _, warn in ipairs(results.warnings) do
      print("  - " .. warn.message)
    end
  end

  -- Validate pattern approach
  local pattern_results = validate_pattern_approach(content)
  if #pattern_results.issues > 0 then
    print("\nPattern Issues:")
    for _, issue in ipairs(pattern_results.issues) do
      print("  - " .. issue.message)
      valid = false
    end
    
    print("\nRecommendations:")
    for _, rec in ipairs(pattern_results.recommendations) do
      print("  - For '" .. rec.node_type .. "': " .. rec.recommendation)
      if rec.alternative then
        print("    Alternative: " .. rec.alternative)
      end
    end
  end
  
  -- Check for content improvements
  local suggestions = suggest_content_improvements(content)
  if #suggestions > 0 then
    print("\nSuggestions for improvement:")
    for _, suggestion in ipairs(suggestions) do
      print("  - " .. suggestion.message)
      print("    Example:")
      print(suggestion.example)
    end
  end

  -- Specifically check for the known problematic node types
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  local fixed_content = {}
  local has_fixes = false
  local in_keyword_list = false
  local keyword_list_start = 0
  local keyword_list_end = 0

  -- Find keyword list
  for i, line in ipairs(lines) do
    if line:match("%[") and not in_keyword_list then
      in_keyword_list = true
      keyword_list_start = i
    elseif line:match("%]") and in_keyword_list then
      in_keyword_list = false
      keyword_list_end = i
    end

    table.insert(fixed_content, line)
  end

  -- Check for issues in captures by line
  for i, line in ipairs(lines) do
    local had_fix = false
    
    -- Check for parenthesized invalid node types
    for _, invalid_type in ipairs(KNOWN_INVALID_NODE_TYPES) do
      if line:match("%((" .. invalid_type .. ")%)") then
        print("\nFound invalid node type as pattern: (" .. invalid_type .. ") at line " .. i)
        
        -- Fix: Comment out the line with the invalid node type
        if auto_fix then
          -- Comment out the line
          fixed_content[i] = "; " .. line .. " -- Invalid node type pattern, commented out"
          has_fixes = true
          had_fix = true
          print("  → Auto-fixed: Commented out invalid node type pattern at line " .. i)
          break
        else
          print("  → Fix needed: Convert to string literal or comment out line " .. i)
          valid = false
        end
      end
    end
    
    -- Check for raw string literals outside arrays
    if not had_fix then
      for _, literal in ipairs(STRING_LITERALS_TO_USE) do
        if line:match('"' .. literal .. '"') and not line:match("%[") then
          print("\nFound string literal outside array: \"" .. literal .. "\" at line " .. i)
          
          if auto_fix then
            -- Try to convert to string array if possible
            if not in_keyword_list and keyword_list_start > 0 and i > keyword_list_end then
              -- Add to existing keyword list instead
              local keyword_line = string.gsub(line, '"' .. literal .. '"', "")
              keyword_line = string.gsub(keyword_line, "@[%w%.]+", "")
              keyword_line = string.gsub(keyword_line, ";.-$", "")
              
              -- Extract capture
              local capture = line:match("@[%w%.]+")
              
              -- Find the keyword list
              for j = keyword_list_start, keyword_list_end do
                if fixed_content[j]:match("%]%s+@keyword") then
                  -- Insert before closing bracket
                  fixed_content[j] = string.gsub(fixed_content[j], "%]", '  "' .. literal .. '"\n]')
                  fixed_content[i] = "; " .. line .. " -- Moved to keyword array"
                  has_fixes = true
                  had_fix = true
                  print("  → Auto-fixed: Moved \"" .. literal .. "\" to keyword array")
                  break
                end
              end
            end
          else
            print("  → Fix needed: Move \"" .. literal .. "\" to an array declaration")
            valid = false
          end
        end
      end
    end
  end

  -- Implement fixes if needed and authorized
  if has_fixes and auto_fix then
    local out_file = io.open(path, "w")
    if out_file then
      out_file:write(table.concat(fixed_content, "\n"))
      out_file:close()
      print("\n✅ Fixes applied successfully to " .. path)
    else
      print("\n❌ Could not write fixes to " .. path)
      valid = false
    end
  end

  -- Print validation summary
  print("\n" .. string.rep("-", 80))
  if valid then
    print("✅ Tamarin highlights.scm is valid")
    print("\nRecommendation: Refer to ELABORATE_TREESITTER_STRATEGIES.md for advanced techniques to improve your highlighting")
  else
    print("❌ Tamarin highlights.scm has issues that need to be fixed")
    if not auto_fix then
      print("   Run with --auto-fix to automatically apply fixes")
    end
    print("\nTip: Review ELABORATE_TREESITTER_STRATEGIES.md for fallback techniques:")
    print("  - Section 1.3: Matching \"String Literals\" for Tokens")
    print("  - Section 2.1: #eq? Predicate for matching identifiers")
    print("  - Section 2.2: Parent/Ancestor Relationships for context-specific highlighting")
  end

  return valid
end

-- Function to validate all TreeSitter query files specifically for Tamarin
function M.validate_all_tamarin_queries(auto_fix)
  local query_dir = vim.fn.stdpath('config') .. '/queries/tamarin'
  local files = vim.fn.glob(query_dir .. '/*.scm', false, true)
  
  local all_valid = true
  
  for _, file in ipairs(files) do
    local file_name = vim.fn.fnamemodify(file, ':t')
    
    if file_name == "highlights.scm" then
      local valid = M.validate_and_fix_highlights(file, auto_fix)
      all_valid = all_valid and valid
    else
      local results = validator.validate_query_file(file)
      local valid = #results.errors == 0
      
      print("\n" .. string.rep("=", 80))
      print("Validating Tamarin query file: " .. file)
      print(string.rep("=", 80))
      
      if #results.errors > 0 then
        print("\nErrors:")
        for _, err in ipairs(results.errors) do
          print("  - " .. err.message)
        end
        all_valid = false
      end
      
      if #results.warnings > 0 then
        print("\nWarnings:")
        for _, warn in ipairs(results.warnings) do
          print("  - " .. warn.message)
        end
      end
      
      if valid then
        print("\n✅ " .. file_name .. " is valid")
      else
        print("\n❌ " .. file_name .. " has issues that need to be fixed")
      end
    end
  end
  
  print("\n" .. string.rep("=", 80))
  if all_valid then
    print("✅ All Tamarin query files are valid")
  else
    print("❌ Some Tamarin query files have issues that need to be fixed")
    print("\nRecommendation: Refer to ELABORATE_TREESITTER_STRATEGIES.md for advanced techniques")
  end
  
  return all_valid
end

-- Debug helper
local function debug_print(msg)
  if vim.g.tamarin_test_debug then
    print("[VALIDATION DEBUG] " .. msg)
  end
end

-- Get syntax group at cursor position
local function get_syntax_group_at_cursor()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = pos[1] - 1
  local col = pos[2]
  
  -- Get TreeSitter capture if available
  local has_ts, ts_highlighter = pcall(function()
    return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]
  end)
  
  if has_ts and ts_highlighter then
    debug_print("TreeSitter highlighter is active")
    local captures = {}
    ts_highlighter.tree:for_each_tree(function(tree, lang_tree)
      if not (tree and lang_tree) then return end
      local query = vim.treesitter.query.get(lang_tree:lang(), "highlights")
      if not query then return end
      
      local iter = query:iter_captures(tree:root(), 0, line, line + 1)
      for id, node, _ in iter do
        local range = {node:range()}
        local start_row, start_col, end_row, end_col = unpack(range)
        
        if line == start_row and col >= start_col and col < end_col then
          local name = query.captures[id]
          if name then
            table.insert(captures, "@" .. name)
          end
        end
      end
    end)
    
    if #captures > 0 then
      return captures[#captures], captures
    end
  end
  
  -- Fallback to vim syntax ID
  local synID = vim.fn.synID(line + 1, col + 1, 0)
  if synID and synID > 0 then
    local name = vim.fn.synIDattr(synID, "name")
    local trans_name = vim.fn.synIDattr(vim.fn.synIDtrans(synID), "name")
    
    if name ~= trans_name then
      return name .. " -> " .. trans_name, {name, trans_name}
    else
      return name, {name}
    end
  end
  
  return "None", {}
end

-- Run test on current buffer
function M.run()
  debug_print("Running Tamarin highlight validation")
  
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  
  if ft ~= "tamarin" then
    vim.notify("Current buffer is not a Tamarin file", vim.log.levels.WARN)
    return false
  end
  
  -- Create a new floating window for results
  local width = math.min(120, vim.o.columns - 4)
  local height = math.min(30, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded"
  }
  
  local buf_result = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf_result, true, opts)
  
  -- Window title
  vim.api.nvim_buf_set_lines(buf_result, 0, -1, false, {
    "Tamarin Syntax Highlighting Validation",
    "=====================================",
    "",
    "Press q to close this window",
    "",
    "Highlighting Info:",
    "----------------",
    "TreeSitter Parser: " .. (vim.treesitter.language.inspect("spthy") and "Available" or "Not Available"),
    "Fallback Syntax: " .. (vim.g.tamarin_fallback_highlighting and "Enabled" or "Disabled"),
    "",
    "Cursor Position Info:",
    "-------------------"
  })
  
  -- Add help info for interactive mode
  vim.api.nvim_buf_set_lines(buf_result, -1, -1, false, {
    "Move cursor in Tamarin buffer to see highlighting information",
    "Close this window and press <Leader>tt again to update",
    "",
    "Current Highlight Groups:"
  })
  
  -- Show active highlight groups
  local synID = vim.fn.synID(1, 1, 1)
  local active_groups = {}
  if synID > 0 then
    local syntax_groups = vim.fn.getcompletion("", "highlight")
    for _, group in ipairs(syntax_groups) do
      if group:match("^Tamarin") or group:match("^@tamarin") or group:match("^@spthy") then
        table.insert(active_groups, "- " .. group)
      end
    end
  end
  
  if #active_groups > 0 then
    vim.api.nvim_buf_set_lines(buf_result, -1, -1, false, active_groups)
  else
    vim.api.nvim_buf_set_lines(buf_result, -1, -1, false, {"No Tamarin-specific highlight groups found"})
  end
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf_result, "modifiable", false)
  vim.api.nvim_buf_set_option(buf_result, "filetype", "markdown")
  
  -- Add keymapping to close the window
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf_result, noremap = true})
  
  return true
end

-- Run interactive test that shows highlights as cursor moves
function M.run_interactive()
  debug_print("Running interactive highlight test")
  
  -- Create output buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create a split window
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  
  -- Set up the buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# Tamarin Highlight Inspector",
    "",
    "Move cursor in Tamarin buffer to see highlight information",
    "Press q to close this window",
    "",
    "Waiting for cursor movement..."
  })
  
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  -- Set up autocmd to update on cursor move
  local augroup = vim.api.nvim_create_augroup("TamarinHighlightTest", { clear = true })
  
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    group = augroup,
    callback = function()
      local current_win = vim.api.nvim_get_current_win()
      if current_win ~= win then  -- Only update when cursor moves in Tamarin buffer
        local current_buf = vim.api.nvim_win_get_buf(current_win)
        local ft = vim.bo[current_buf].filetype
        
        if ft == "tamarin" then
          local pos = vim.api.nvim_win_get_cursor(current_win)
          local line = vim.api.nvim_buf_get_lines(current_buf, pos[1]-1, pos[1], false)[1]
          local col = pos[2]
          
          local char = line:sub(col+1, col+1)
          if char == "" then char = "<EOL>" end
          
          local syntax, groups = get_syntax_group_at_cursor()
          
          vim.api.nvim_buf_set_option(buf, "modifiable", true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "# Tamarin Highlight Inspector",
            "",
            "Position: Line " .. pos[1] .. ", Column " .. pos[2],
            "Character: '" .. char .. "'",
            "",
            "Highlight Group: " .. syntax,
            "",
            "All Groups:"
          })
          
          if #groups > 0 then
            for i, group in ipairs(groups) do
              vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"- " .. group})
            end
          else
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"None"})
          end
          
          vim.api.nvim_buf_set_option(buf, "modifiable", false)
        end
      end
    end
  })
  
  -- Add keymapping to close the window
  vim.keymap.set("n", "q", function()
    vim.api.nvim_create_augroup("TamarinHighlightTest", { clear = true })
    vim.cmd("close")
  end, {buffer = buf, noremap = true})
  
  return true
end

-- Parse command line arguments
local auto_fix = false
for i = 1, #arg do
  if arg[i] == "--auto-fix" then
    auto_fix = true
  end
end

-- Run validation if script is called directly
if not pcall(debug.getlocal, 4, 1) then
  local success = M.validate_all_tamarin_queries(auto_fix)
  os.exit(success and 0 or 1)
end

return M 