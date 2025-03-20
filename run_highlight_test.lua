-- Script to run the highlight inspector headlessly on test.spthy
-- This will help identify syntax highlighting discrepancies

-- Define patterns to test for syntax highlighting
local patterns_to_test = {
  -- Keywords
  "theory", "begin", "end", "rule", "lemma", "builtins",
  
  -- Variables with prefixes
  "$%w+", "~%w+", "#%w+",  -- Public, fresh, and temporal variables
  
  -- Facts
  "!%w+", -- Persistent facts
  "Out%(%w*%)", "In%(%w*%)", "Fr%(%w*%)", "K%(%w*%)", -- Built-in facts
  
  -- Action facts
  "--%[.*%]->",
  
  -- Functions
  "%w+%(.-%):",  -- Function declarations
  "pk%(.-%)","h%(.-%)","sign%(.-%)","verify%(.-%)","senc%(.-%)","sdec%(.-%)","aenc%(.-%)","adec%(.-%)","mac%(.-%)","verify%(.-%)e", -- Builtin functions
  
  -- Punctuation and operators
  "--%[", "%]->", "==>", "-->"
}

-- Load the highlight inspector
local inspector = require('highlight_inspector')

-- Set up expected color mapping based on tamarin-colors.lua
local expected_colors = {
  ["@keyword"] = "#FF00FF", -- magentaBold
  ["@variable.public"] = "#006400", -- deepGreen
  ["@variable.fresh"] = "#FF69B4", -- hotPinkPlain
  ["@variable.temporal"] = "#00BFFF", -- skyBluePlain
  ["@fact.persistent"] = "#FF3030", -- redBold
  ["@function.builtin"] = "#1E90FF", -- blueBoldUnderlined
  ["@function"] = "#FF6347", -- tomatoItalic
  ["@operator"] = "#708090", -- slateGrayBold
}

-- Run the inspection
local file_path = "test.spthy"

-- Setup function to initialize neovim properly
local function setup_neovim()
  -- Configure Neovim as needed
  vim.cmd("set runtimepath+=/Users/dan/.config/nvim")
  vim.cmd("filetype plugin on")
  vim.cmd("syntax enable")
  
  -- Load required configuration for spthy files
  vim.cmd("source /Users/dan/.config/nvim/init.lua")
  
  -- Open the test file
  vim.cmd("edit " .. file_path)
  
  -- Make sure we're in the right filetype
  vim.bo.filetype = "spthy"
  
  -- Let the buffer load and highlight
  vim.cmd("sleep 100m")
end

-- Function to run the inspection
local function run_inspection()
  -- Find matches for the patterns
  local matches = inspector.find_matches(file_path, patterns_to_test)
  
  -- Get highlight information for each match
  local highlights = inspector.get_highlight_info(matches)
  
  -- Format and save the results
  local output = inspector.format_results(highlights)
  local output_path = "highlight_inspection_results.md"
  local file = io.open(output_path, "w")
  
  if file then
    file:write(output)
    file:close()
    print("Inspection results saved to " .. output_path)
  else
    print("Failed to write inspection results to file")
  end
  
  -- Print a summary of highlights that don't match expected colors
  print("\nHighlight Discrepancies:")
  print("=======================")
  
  local discrepancies = 0
  
  for _, result in ipairs(highlights) do
    local match = result.match
    local syntax = result.syntax
    local ts_captures = result.captures
    
    for _, capture in ipairs(ts_captures) do
      if expected_colors[capture] then
        local expected = expected_colors[capture]
        local actual = syntax.fg_hex
        
        if expected ~= actual then
          discrepancies = discrepancies + 1
          print(string.format("Line %d: '%s' has color %s, expected %s (capture: %s)", 
            match.line, match.text, actual, expected, capture))
        end
      end
    end
  end
  
  if discrepancies == 0 then
    print("No discrepancies found!")
  else 
    print(string.format("%d discrepancies found", discrepancies))
  end
end

-- Main execution
setup_neovim()
run_inspection()

-- Exit when done
vim.cmd("qa!") 