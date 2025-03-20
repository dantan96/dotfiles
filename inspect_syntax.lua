-- Script to inspect syntax highlighting for one or more patterns
-- Usage: nvim --headless -l inspect_syntax.lua file_path pattern1 pattern2 ...

-- Get arguments from command line
local args = vim.v.argv
local script_idx = 0

-- Find the index of this script in the arguments
for i, arg in ipairs(args) do
  if arg:match("inspect_syntax.lua$") then
    script_idx = i
    break
  end
end

-- Check for required arguments
if #args <= script_idx or script_idx == 0 then
  print("Usage: nvim --headless -l inspect_syntax.lua file_path pattern1 pattern2 ...")
  vim.cmd('quit')
  return
end

-- Extract file path and patterns
local file_path = args[script_idx + 1]
local patterns = {}

for i = script_idx + 2, #args do
  table.insert(patterns, args[i])
end

-- Default pattern if none provided
if #patterns == 0 then
  print("No patterns provided. Will search for 'equations' as default.")
  patterns = {"equations"}
end

-- Print info about what we're doing
print("Inspecting syntax highlighting in file: " .. file_path)
print("Searching for patterns: " .. table.concat(patterns, ", "))

-- Load and run the highlight inspector
local inspector = require('highlight_inspector')
local results = inspector.run_inspection(file_path, patterns)

-- Print summary
print("Inspection completed. Results saved to highlight_inspection_results.md")

-- Exit Neovim
vim.cmd('quit') 