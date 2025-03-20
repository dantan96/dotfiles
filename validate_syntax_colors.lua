-- Validate Syntax Colors - Headless testing script
-- This script runs headlessly and validates the Tamarin syntax highlighting
-- against the expected color configuration

-- Configuration
local test_file = "test.spthy"
local output_file = "syntax_validation_results.md"

-- Load the highlight inspector
package.path = package.path .. ";/Users/dan/.config/nvim/?.lua"
local inspector = require('highlight_inspector')

-- Get colors from the spthy-colorscheme configuration
local function load_color_configuration()
  -- Safely require the color configuration
  local ok, config = pcall(require, 'config.spthy-colorscheme')
  if not ok then
    print("Error loading color configuration: " .. tostring(config))
    return {}
  end
  
  -- Get the colors table
  return config.colors or {}
end

-- Extract hex color from a color definition
local function get_hex_color(color_def)
  if type(color_def) ~= "table" then
    return nil
  end
  
  return color_def.fg
end

-- Map the highlight group names to expected colors from our configuration
local function build_expected_colors_map()
  local colors = load_color_configuration()
  
  -- Create mapping from highlight group name to hex color
  return {
    -- Keywords
    ["@keyword"] = get_hex_color(colors.magentaBold),
    ["@keyword.quantifier"] = get_hex_color(colors.lilacBold),
    
    -- Variables
    ["@variable.public"] = get_hex_color(colors.deepGreen),
    ["@variable.fresh"] = get_hex_color(colors.hotPinkPlain),
    ["@variable.temporal"] = get_hex_color(colors.skyBluePlain),
    ["@variable.message"] = get_hex_color(colors.orangePlain),
    
    -- Facts
    ["@fact.persistent"] = get_hex_color(colors.redBold),
    ["@fact.linear"] = get_hex_color(colors.blueBold),
    ["@function.builtin"] = get_hex_color(colors.blueBoldUnderlined),
    ["@fact.action"] = get_hex_color(colors.lightPinkPlain),
    
    -- Functions
    ["@function"] = get_hex_color(colors.tomatoItalic),
    ["@function.rule"] = get_hex_color(colors.goldBold),
    
    -- Structure
    ["@operator"] = get_hex_color(colors.slateGrayBold),
    ["@punctuation.bracket"] = get_hex_color(colors.slateGrayPlain),
    ["@structure"] = get_hex_color(colors.goldBold),
  }
end

-- Define patterns to test for syntax highlighting
local patterns_to_test = {
  -- Keywords
  "theory", "begin", "end", "rule", "lemma", "builtins", "restriction", "equations", "functions",
  
  -- Variables with prefixes
  "$%w+", "~%w+", "#%w+",  -- Public, fresh, and temporal variables
  
  -- Facts
  "!%w+", -- Persistent facts
  "Out%([^%)]*%)", "In%([^%)]*%)", "Fr%([^%)]*%)", "K%([^%)]*%)", -- Built-in facts
  
  -- Action facts
  "--%[.-%]->",
  
  -- Functions
  "%w+%(.-%):",  -- Function declarations
  "pk%(.-%)","h%(.-%)","sign%(.-%)","verify%(.-%)","senc%(.-%)","sdec%(.-%)","aenc%(.-%)","adec%(.-%)","mac%(.-%)","verify%(.-%)e", -- Builtin functions
  
  -- Punctuation and operators
  "--%[", "%]->", "==>", "-->",
  
  -- Comments
  "//.-$", "/\\*.-\\*/", 
  
  -- Numbers and strings
  "%d+", "'[^']*'", "\"[^\"]*\""
}

-- Initialize Neovim environment
local function init()
  -- Set runtime path
  vim.opt.runtimepath:append("/Users/dan/.config/nvim")
  
  -- Source init file
  vim.cmd("source /Users/dan/.config/nvim/init.lua")
  
  -- Load the test file
  vim.cmd("edit " .. test_file)
  
  -- Set filetype
  vim.bo.filetype = "spthy"
  
  -- Wait for syntax highlighting to apply
  vim.cmd("sleep 500m")
end

-- Run the actual inspection
local function run_inspection()
  -- Get expected colors
  local expected_colors = build_expected_colors_map()
  
  -- Run inspection
  local matches = inspector.find_matches(test_file, patterns_to_test)
  
  if #matches == 0 then
    print("No matches found. Check that the patterns are correct.")
    return
  end
  
  -- Get highlight information
  local highlights = inspector.get_highlight_info(matches)
  
  -- Format and save the detailed results
  local output = inspector.format_results(highlights)
  local file = io.open(output_file, "w")
  
  if file then
    file:write(output)
    file:close()
    print("Detailed inspection results saved to " .. output_file)
  else
    print("Failed to write inspection results to file")
  end
  
  -- Check for color discrepancies
  print("\nSyntax Highlighting Validation")
  print("=============================")
  
  local discrepancies = {}
  local total_tested = 0
  
  for _, result in ipairs(highlights) do
    local match = result.match
    local syntax = result.syntax
    local captures = result.captures
    
    for _, capture in ipairs(captures) do
      if expected_colors[capture] then
        total_tested = total_tested + 1
        local expected = expected_colors[capture]
        local actual = syntax.fg_hex
        
        if expected and actual and expected:lower() ~= actual:lower() then
          table.insert(discrepancies, {
            line = match.line,
            text = match.text,
            capture = capture,
            expected = expected,
            actual = actual
          })
        end
      end
    end
  end
  
  -- Report results
  print(string.format("Tested %d capture matches", total_tested))
  
  if #discrepancies == 0 then
    print("All tested syntax highlighting matches expected colors! ✓")
  else
    print(string.format("Found %d color discrepancies:", #discrepancies))
    
    -- Group discrepancies by capture
    local by_capture = {}
    for _, d in ipairs(discrepancies) do
      by_capture[d.capture] = by_capture[d.capture] or {}
      table.insert(by_capture[d.capture], d)
    end
    
    -- Print summary by capture
    for capture, items in pairs(by_capture) do
      print(string.format("\n%s: %d issues", capture, #items))
      print(string.format("  Expected: %s, Found: %s", items[1].expected, items[1].actual))
      print("  Examples:")
      
      -- Show up to 3 examples
      for i = 1, math.min(3, #items) do
        print(string.format("    Line %d: '%s'", items[i].line, items[i].text))
      end
    end
  end
end

-- Main execution
init()
run_inspection()

-- Exit
vim.cmd("qa!") 