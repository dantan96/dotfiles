-- Syntax Color Diagnostic for Tamarin/Spthy Files
-- This script identifies which syntax highlighting system is active and checks for color discrepancies

-- File to analyze
local test_file = "/Users/dan/.config/nvim/lua/test/test_tamarin_file.spthy"

-- Initialize variables
local start_time = os.time()
local function check_timeout(seconds)
  if os.time() - start_time > seconds then
    print("ERROR: Script execution timed out after " .. seconds .. " seconds!")
    os.exit(1)
  end
end

-- Get expected colors from spthy-colorscheme.lua
local function get_expected_colors()
  local ok, config = pcall(require, 'config.spthy-colorscheme')
  if not ok then
    print("Error loading color configuration: " .. tostring(config))
    return {}
  end
  
  -- Build a mapping of highlight groups to expected colors
  local expected = {}
  for name, color in pairs(config.colors) do
    if type(color) == "table" and color.fg then
      expected[name] = color.fg:lower()
    end
  end
  
  return expected
end

-- Map syntax names to expected color group
local function get_syntax_to_color_map()
  return {
    -- Vim syntax groups to color mapping
    ["spthyKeyword"] = "magentaBold",
    ["spthyPublicVar"] = "deepGreen", 
    ["spthyFreshVar"] = "hotPinkPlain",
    ["spthyTemporalVar"] = "skyBluePlain",
    ["spthyPersistentFact"] = "redBold",
    ["spthyBuiltinFact"] = "blueBoldUnderlined",
    ["spthyNormalFact"] = "blueBold",
    ["spthyFunction"] = "tomatoItalic",
    ["spthyRuleArrow"] = "slateGrayBold",
    ["spthyBracket"] = "slateGrayPlain",
    
    -- TreeSitter highlight groups to color mapping
    ["@keyword"] = "magentaBold",
    ["@variable.public"] = "deepGreen",
    ["@variable.fresh"] = "hotPinkPlain",
    ["@variable.temporal"] = "skyBluePlain",
    ["@variable.message"] = "orangePlain",
    ["@fact.persistent"] = "redBold",
    ["@fact.linear"] = "blueBold",
    ["@function.builtin"] = "blueBoldUnderlined",
    ["@fact.action"] = "lightPinkPlain",
    ["@function"] = "tomatoItalic",
    ["@function.rule"] = "goldBold",
    ["@operator"] = "slateGrayBold",
    ["@punctuation.bracket"] = "slateGrayPlain"
  }
end

-- Check which syntax highlighting system is active
local function check_active_syntax_system()
  print("\nChecking active syntax highlighting systems...")
  print("-------------------------------------------------")
  
  -- Check if traditional vim syntax is active
  local vim_syntax = vim.bo.syntax
  print("Vim syntax setting: " .. vim_syntax)
  
  -- Check if treesitter is active
  local ts_active = false
  local ts_lang = nil
  
  if vim.treesitter and vim.treesitter.highlighter then
    local current_buf = vim.api.nvim_get_current_buf()
    ts_active = vim.treesitter.highlighter.active[current_buf] ~= nil
    
    if ts_active then
      -- Try to get language
      pcall(function()
        ts_lang = vim.treesitter.language.get_lang(vim.bo.filetype)
      end)
    end
  end
  
  print("TreeSitter active: " .. tostring(ts_active))
  if ts_lang then
    print("TreeSitter language: " .. ts_lang)
  end
  
  -- Check loader flags
  local syntax_loaded = vim.b.spthy_syntax_loaded or false
  local current_syntax = vim.b.current_syntax or "none"
  
  print("spthy_syntax_loaded flag: " .. tostring(syntax_loaded))
  print("current_syntax: " .. current_syntax)
  
  return {
    vim_syntax = vim_syntax,
    ts_active = ts_active,
    ts_lang = ts_lang,
    syntax_loaded = syntax_loaded,
    current_syntax = current_syntax
  }
end

-- Analyze text patterns and get their applied colors
local function analyze_patterns()
  -- Define patterns to test
  local patterns = {
    { pattern = "theory", type = "keyword", expected_color = "magentaBold" },
    { pattern = "begin", type = "keyword", expected_color = "magentaBold" },
    { pattern = "rule", type = "keyword", expected_color = "magentaBold" },
    { pattern = "lemma", type = "keyword", expected_color = "magentaBold" },
    { pattern = "$%w+", type = "public_var", expected_color = "deepGreen" },
    { pattern = "~%w+", type = "fresh_var", expected_color = "hotPinkPlain" },
    { pattern = "#%w+", type = "temporal_var", expected_color = "skyBluePlain" },
    { pattern = "!%w+", type = "persistent_fact", expected_color = "redBold" },
    { pattern = "Fr%(%w*%)", type = "builtin_fact", expected_color = "blueBoldUnderlined" },
    { pattern = "Out%(%w*%)", type = "builtin_fact", expected_color = "blueBoldUnderlined" },
    { pattern = "--%[", type = "operator", expected_color = "slateGrayBold" },
    { pattern = "%]->", type = "operator", expected_color = "slateGrayBold" }
  }
  
  -- Read the file content
  local content = {}
  local file = io.open(test_file, "r")
  if not file then
    print("Error: Could not open file " .. test_file)
    return {}
  end
  
  -- Read file content
  for line in file:lines() do
    table.insert(content, line)
  end
  file:close()
  
  -- Get expected colors
  local expected_colors = get_expected_colors()
  local syntax_to_color = get_syntax_to_color_map()
  
  -- Collect results
  local results = {}
  
  -- Find and analyze each pattern
  for _, pattern_info in ipairs(patterns) do
    for line_num, line in ipairs(content) do
      local start_idx, end_idx = line:find(pattern_info.pattern)
      while start_idx do
        -- Get the matched text
        local text = line:sub(start_idx, end_idx)
        
        -- Get syntax ID at this position
        local syntax_id = vim.fn.synID(line_num, start_idx, true)
        local syntax_name = vim.fn.synIDattr(syntax_id, "name")
        
        -- Get the actual color
        local trans_id = vim.fn.synIDtrans(syntax_id)
        local color = vim.fn.synIDattr(trans_id, "fg#")
        if color == "" then color = "none" end
        
        -- Get treesitter captures
        local captures = {}
        pcall(function()
          local ts_captures = vim.treesitter.get_captures_at_pos(0, line_num-1, start_idx-1)
          if ts_captures then
            for _, capture in ipairs(ts_captures) do
              table.insert(captures, capture.capture)
            end
          end
        end)
        
        -- Determine expected color
        local expected_color = nil
        local expected_color_name = pattern_info.expected_color
        
        if expected_colors[expected_color_name] then
          expected_color = expected_colors[expected_color_name]:lower()
        end
        
        -- Get color based on syntax name (if available)
        local syntax_expected_color = nil
        if syntax_name ~= "" and syntax_to_color[syntax_name] then
          local color_name = syntax_to_color[syntax_name]
          if expected_colors[color_name] then
            syntax_expected_color = expected_colors[color_name]:lower()
          end
        end
        
        -- Get color based on treesitter capture (if available)
        local capture_expected_color = nil
        for _, capture in ipairs(captures) do
          if syntax_to_color[capture] then
            local color_name = syntax_to_color[capture]
            if expected_colors[color_name] then
              capture_expected_color = expected_colors[color_name]:lower()
              break -- Use the first matching capture
            end
          end
        end
        
        -- Store result
        table.insert(results, {
          line = line_num,
          col = start_idx,
          text = text,
          pattern_type = pattern_info.type,
          syntax_name = syntax_name,
          actual_color = color:lower(),
          expected_color = expected_color,
          syntax_expected_color = syntax_expected_color,
          capture_expected_color = capture_expected_color,
          treesitter_captures = captures
        })
        
        -- Find next match
        start_idx, end_idx = line:find(pattern_info.pattern, end_idx + 1)
        
        -- Safety check
        check_timeout(10)
      end
    end
  end
  
  return results
end

-- Format and print a color diagnostics report
local function print_color_report(results, system_info)
  -- Group results
  local correct = {}
  local incorrect = {}
  
  for _, result in ipairs(results) do
    local actual = result.actual_color
    
    -- Try different sources for expected color in this order:
    -- 1. Color from treesitter capture (most specific)
    -- 2. Color from syntax highlight group
    -- 3. Color from pattern type
    local expected = result.capture_expected_color or 
                    result.syntax_expected_color or 
                    result.expected_color or 
                    "unknown"
    
    if actual ~= "none" and expected ~= "unknown" and actual == expected then
      table.insert(correct, result)
    else
      table.insert(incorrect, result)
    end
  end
  
  -- Print header
  print("\nColor Diagnostics Report")
  print("======================")
  print("Total elements checked: " .. #results)
  print("Correctly colored: " .. #correct)
  print("Incorrectly colored: " .. #incorrect)
  
  -- Print color source information
  if system_info.ts_active then
    if #correct > 0 and correct[1].capture_expected_color then
      print("\nTreeSitter appears to be providing colors")
    end
  elseif system_info.vim_syntax == "spthy" then
    if #correct > 0 and correct[1].syntax_expected_color then
      print("\nVim syntax highlighting appears to be providing colors")
    end
  else
    print("\nUnable to determine color source - both systems may be inactive")
  end
  
  -- Print incorrect colors
  if #incorrect > 0 then
    print("\nIncorrectly Colored Elements:")
    print("----------------------------")
    
    -- Group by pattern type
    local by_type = {}
    for _, result in ipairs(incorrect) do
      by_type[result.pattern_type] = by_type[result.pattern_type] or {}
      table.insert(by_type[result.pattern_type], result)
    end
    
    for type, items in pairs(by_type) do
      print("\n" .. type .. ":")
      
      -- Print up to 3 examples
      for i = 1, math.min(3, #items) do
        local item = items[i]
        
        local expected = item.capture_expected_color or 
                        item.syntax_expected_color or 
                        item.expected_color or 
                        "unknown"
        
        print(string.format("  Line %d: '%s' - Expected: %s, Actual: %s", 
              item.line, item.text, expected, item.actual_color))
        
        if #item.treesitter_captures > 0 then
          print(string.format("    TreeSitter captures: %s", table.concat(item.treesitter_captures, ", ")))
        end
        
        if item.syntax_name ~= "" then
          print(string.format("    Vim syntax group: %s", item.syntax_name))
        end
      end
      
      -- Safety check
      check_timeout(15)
    end
  end
  
  -- Print conclusion about what's wrong
  print("\nDiagnosis:")
  print("---------")
  
  if #incorrect == 0 then
    print("All elements are correctly colored. If you're still seeing issues, there might be specific patterns not covered by this test.")
  else
    if system_info.ts_active and system_info.vim_syntax == "spthy" then
      print("CONFLICT DETECTED: Both TreeSitter and Vim syntax highlighting are active, which may cause conflicts.")
      print("Fix: Edit ftplugin/spthy.vim to either disable TreeSitter or traditional syntax highlighting, but not both.")
    elseif not system_info.ts_active and system_info.vim_syntax ~= "spthy" then
      print("NO ACTIVE HIGHLIGHTING: Neither TreeSitter nor Vim syntax highlighting appears to be active.")
      print("Fix: Check that syntax is enabled and that the filetype is correctly detected as 'spthy'.")
    elseif system_info.ts_active then
      print("TreeSitter captures are working but colors aren't correct.")
      print("Fix: Check mappings in tamarin-colors.lua to ensure TreeSitter capture groups are mapped to the right colors.")
    else
      print("Vim syntax highlighting is active but colors aren't correct.")
      print("Fix: Check the color definitions in spthy-colorscheme.lua and their usage in syntax/spthy.vim.")
    end
  end
  
  -- Print suggested fix
  print("\nSuggested Fix:")
  print("-------------")
  print("1. Edit ftplugin/spthy.vim to add a clear choice of which system to use:")
  print([[
" Choose ONE syntax highlighting system:
" 1. Lua-based syntax highlighting (recommended, supports both .vim and treesitter)
let b:spthy_syntax_loaded = 1
lua require('config.tamarin-colors').setup()

" 2. OR traditional Vim syntax highlighting (disable this if using #1)
" set syntax=spthy
" let b:current_syntax = ""  " Unset to allow syntax/spthy.vim to load

" 3. OR pure TreeSitter highlighting (experimental, disable if using #1 or #2)
" lua pcall(function() vim.treesitter.start(0, 'spthy') end)
]])
  
  -- Write report to file
  local report_file = "color_diagnostic_report.md"
  local file = io.open(report_file, "w")
  if file then
    file:write("# Tamarin Syntax Color Diagnostic Report\n\n")
    file:write("## Highlighting System Status\n\n")
    file:write("- Vim syntax: " .. system_info.vim_syntax .. "\n")
    file:write("- TreeSitter active: " .. tostring(system_info.ts_active) .. "\n")
    file:write("- spthy_syntax_loaded flag: " .. tostring(system_info.syntax_loaded) .. "\n")
    file:write("- current_syntax: " .. system_info.current_syntax .. "\n\n")
    
    file:write("## Color Statistics\n\n")
    file:write("- Total elements checked: " .. #results .. "\n")
    file:write("- Correctly colored: " .. #correct .. "\n")
    file:write("- Incorrectly colored: " .. #incorrect .. "\n\n")
    
    if #incorrect > 0 then
      file:write("## Incorrectly Colored Elements\n\n")
      file:write("| Line | Text | Expected Color | Actual Color | Syntax Group | TreeSitter Captures |\n")
      file:write("|------|------|---------------|--------------|--------------|--------------------|\n")
      
      for _, item in ipairs(incorrect) do
        local expected = item.capture_expected_color or 
                        item.syntax_expected_color or 
                        item.expected_color or 
                        "unknown"
        
        file:write(string.format("| %d | `%s` | %s | %s | %s | %s |\n",
              item.line, 
              item.text:gsub("|", "\\|"), 
              expected,
              item.actual_color,
              item.syntax_name,
              table.concat(item.treesitter_captures, ", ")))
      end
    end
    
    file:close()
    print("\nDetailed report saved to " .. report_file)
  end
end

-- Initialize Neovim for diagnostics
local function init()
  -- Disable user interaction
  vim.opt.more = false
  vim.opt.confirm = false
  vim.opt.shortmess:append("amoOstTWAIcCqfs")
  
  -- Load the test file
  if vim.fn.filereadable(test_file) == 1 then
    vim.cmd("edit " .. test_file)
  else
    print("ERROR: Test file not found: " .. test_file)
    os.exit(1)
  end
  
  -- Set filetype
  vim.bo.filetype = "spthy"
  
  -- Let the buffer initialize
  vim.cmd("sleep 200m")
  
  check_timeout(5) -- Safety check
end

-- Main function
local function main()
  print("Running Tamarin syntax color diagnostics...")
  
  -- Set up Neovim
  init()
  
  -- Check which syntax system is active
  local system_info = check_active_syntax_system()
  
  -- Analyze patterns and colors
  local results = analyze_patterns()
  
  -- Print diagnostic report
  print_color_report(results, system_info)
  
  print("\nDiagnostics complete.")
end

-- Run with error handling
local ok, err = pcall(main)
if not ok then
  print("ERROR: " .. tostring(err))
  os.exit(1)
end

-- Exit cleanly
vim.cmd("qa!") 