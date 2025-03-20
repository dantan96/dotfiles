-- Simple Tamarin Syntax Highlighting Diagnostic
-- Only uses built-in Neovim functions without custom classes

-- Create a test file in the user's home directory
local test_file = vim.fn.expand("~/tamarin_test.spthy")
local report_file = vim.fn.expand("~/tamarin_highlight_report.txt")

-- Create a simple test file
local content = [[
// Comment line
/* Block comment */

theory TestTheory
begin

builtins: diffie-hellman, signing, hashing

rule TestRule:
  [ Fr(~k) ]
  --[ Action($A, ~k, #i) ]->
  [ !PersistentFact($A, ~k), LinearFact(~k) ]

end
]]

vim.fn.writefile(vim.split(content, "\n"), test_file)

-- Function to get syntax information at a position
local function get_syntax_info(line, col)
  local synID = vim.fn.synID(line, col, true)
  if synID == 0 then return "No syntax ID" end
  
  local synName = vim.fn.synIDattr(synID, "name")
  local transID = vim.fn.synIDtrans(synID)
  local transName = vim.fn.synIDattr(transID, "name")
  local fg = vim.fn.synIDattr(transID, "fg#")
  
  return string.format(
    "ID: %d, Name: %s, Trans: %s, Color: %s",
    synID, synName, transName, fg or "default"
  )
end

-- Open the file and get its contents
vim.cmd("edit " .. test_file)
vim.cmd("set filetype=spthy")
vim.cmd("syntax on")
vim.cmd("redraw!")

-- Wait a moment for syntax to apply
vim.cmd("sleep 500m")

-- Define test locations
local test_points = {
  { line = 1, col = 3, desc = "Comment (//)"},
  { line = 2, col = 3, desc = "Block comment (/*)"}, 
  { line = 4, col = 1, desc = "Keyword (theory)"},
  { line = 5, col = 1, desc = "Keyword (begin)"},
  { line = 7, col = 10, desc = "Builtin (builtins)"},
  { line = 9, col = 1, desc = "Keyword (rule)"},
  { line = 10, col = 5, desc = "Builtin fact (Fr)"},
  { line = 10, col = 9, desc = "Fresh variable (~k)"},
  { line = 11, col = 4, desc = "Action start (--[)"},
  { line = 11, col = 12, desc = "Linear fact (Action)"},
  { line = 11, col = 19, desc = "Public variable ($A)"},
  { line = 11, col = 23, desc = "Fresh variable in action (~k)"},
  { line = 11, col = 27, desc = "Temporal variable (#i)"},
  { line = 11, col = 31, desc = "Action end (]->)"},
  { line = 12, col = 4, desc = "Persistent fact (!PersistentFact)"},
  { line = 12, col = 20, desc = "Public variable in fact ($A)"},
  { line = 12, col = 24, desc = "Fresh variable in fact (~k)"},
  { line = 12, col = 29, desc = "Linear fact (LinearFact)"},
  { line = 14, col = 1, desc = "Keyword (end)"}
}

-- Collect results
local results = {"# Tamarin Syntax Highlighting Report\n"}
table.insert(results, "File: " .. test_file .. "\n")
table.insert(results, "Generated: " .. os.date() .. "\n\n")

table.insert(results, "| Line | Col | Description | Syntax Information |\n")
table.insert(results, "|------|-----|-------------|-------------------|\n")

for _, point in ipairs(test_points) do
  local info = get_syntax_info(point.line, point.col)
  table.insert(results, string.format(
    "| %d | %d | %s | %s |\n",
    point.line, point.col, point.desc, info
  ))
end

-- Write results
vim.fn.writefile(results, report_file)

-- Inform user
print("Diagnostic complete")
print("Report saved to: " .. report_file)

-- Open the report
vim.cmd("edit " .. report_file) 