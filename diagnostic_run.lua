-- Direct script to check Tamarin syntax highlighting
local test_file = vim.fn.stdpath("cache") .. "/tamarin_test.spthy"
local output_file = vim.fn.stdpath("cache") .. "/tamarin_highlight_report.md"

-- Create a test file with all syntax elements
local test_content = [[
// TAMARIN SYNTAX TEST FILE
/* Multiline comment
   with multiple lines */

theory TestTheory
begin

builtins: diffie-hellman, signing, hashing

// FACTS: Persistent vs Linear vs Action
rule TestFactTypes:
  [ Fr(~k) ]
  --[ TestAction($A, ~k, #i), TestAction2(!LTK, 'constant') ]->
  [ !PersistentFact($A, ~k),
    LinearFact(~k),
    Out(<$A, ~k, #i>) ]

// VARIABLES: Public, Fresh, Temporal, Message
rule TestVariableTypes:
  [ In($PublicVar),
    Fr(~freshVar),
    LinearFact(x:msg) ]
  --[ At(#time) ]->
  [ Out(<$PublicVar, ~freshVar, #time>) ]

// FUNCTIONS: Normal and Builtin
rule TestFunctions:
  [ Fr(~k) ]
  -->
  [ Out(h(~k)), 
    Out(pk(~k)),
    Out(sign(~k, 'message')),
    Out(verify(sign(~k, 'message'), pk(~k), 'message')) ]

end
]]

-- Write the test file
vim.fn.writefile(vim.split(test_content, "\n"), test_file)

-- Set up the test environment
vim.cmd("syntax on")
vim.cmd("set filetype=spthy")

-- Load Tamarin colors
require("config.tamarin-colors").setup()

-- Wait for highlighting to apply
vim.cmd("sleep 500m")

-- Open the test file
vim.cmd("edit " .. vim.fn.fnameescape(test_file))
vim.cmd("redraw!")

print("Starting diagnostic...")

-- Test cases to check
local test_cases = {
  { name = "COMMENTS", patterns = {"//", "/*"} },
  { name = "KEYWORDS", patterns = {"theory", "begin", "end", "rule", "builtins"} },
  { name = "PUBLIC_VARIABLES", patterns = {"$A", "$PublicVar"} },
  { name = "FRESH_VARIABLES", patterns = {"~k", "~freshVar"} },
  { name = "TEMPORAL_VARIABLES", patterns = {"#i", "#time"} },
  { name = "PERSISTENT_FACTS", patterns = {"!PersistentFact", "!LTK"} },
  { name = "LINEAR_FACTS", patterns = {"LinearFact", "TestAction"} },
  { name = "BUILTIN_FACTS", patterns = {"Fr", "In", "Out"} },
  { name = "FUNCTIONS", patterns = {"h", "pk", "sign", "verify"} },
  { name = "ACTION_FACTS", patterns = {"--[", "]->"} }
}

-- Function to check text at a position
local function check_at_pos(line, col)
  local synid = vim.fn.synID(line, col, 1)
  local name = vim.fn.synIDattr(synid, "name")
  local trans_id = vim.fn.synIDtrans(synid)
  local trans_name = vim.fn.synIDattr(trans_id, "name")
  local fg_color = vim.fn.synIDattr(trans_id, "fg#")
  
  return {
    name = name,
    trans_name = trans_name,
    fg_color = fg_color
  }
end

-- Execute the diagnostic
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local results = {
  "# Tamarin Syntax Highlighting Diagnostic Report\n",
  "Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
}

-- Check each test case
for _, test in ipairs(test_cases) do
  table.insert(results, "## " .. test.name .. "\n\n")
  table.insert(results, "| Line | Col | Text | Highlight Group | Foreground Color |\n")
  table.insert(results, "|------|-----|------|----------------|------------------|\n")
  
  local found = false
  
  -- Find all matches in the file
  for line_num, line_text in ipairs(lines) do
    for _, pattern in ipairs(test.patterns) do
      local start_idx = line_text:find(pattern, 1, true) -- Plain text search
      
      if start_idx then
        found = true
        local hl = check_at_pos(line_num, start_idx)
        local matched_text = pattern
        
        local row = string.format(
          "| %d | %d | `%s` | %s | %s |\n",
          line_num,
          start_idx,
          matched_text:gsub("|", "\\|"),
          hl.trans_name,
          hl.fg_color or "default"
        )
        
        table.insert(results, row)
      end
    end
  end
  
  if not found then
    table.insert(results, "| - | - | No matches found | - | - |\n")
  end
  
  table.insert(results, "\n")
end

-- Write the results
vim.fn.writefile(results, output_file)

print("Diagnostic complete")
print("Results saved to: " .. output_file)

-- Display the report
vim.cmd("edit " .. output_file) 