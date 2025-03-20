-- Quick Tamarin Syntax Test
print("Starting quick Tamarin syntax test...")

-- Test file path (use a file we know exists)
local test_file = "test.spthy"

-- Set essential options
vim.opt.more = false
vim.opt.confirm = false
vim.opt.swapfile = false

-- Initialize syntax
vim.cmd("syntax on")
vim.cmd("syntax enable")

-- Set filetype
vim.opt.filetype = "spthy"

-- Define direct highlight groups with proper format
vim.cmd("highlight clear")
vim.cmd("highlight spthyKeyword guifg=#FF00FF gui=bold")
vim.cmd("highlight spthyPublicVar guifg=#006400")
vim.cmd("highlight spthyFreshVar guifg=#FF69B4")
vim.cmd("highlight spthyTemporalVar guifg=#00BFFF")
vim.cmd("highlight spthyPersistentFact guifg=#FF3030 gui=bold")
vim.cmd("highlight spthyBuiltinFact guifg=#1E90FF gui=bold,underline")
vim.cmd("highlight spthyFunction guifg=#FF6347 gui=italic")
vim.cmd("highlight spthyComment guifg=#777777 gui=italic")

-- Define syntax patterns
vim.cmd([[
syntax clear

" Comments
syntax match spthyComment /\/\/.*$/ 
syntax region spthyComment start="/\*" end="\*/"

" Keywords
syntax keyword spthyKeyword theory begin end rule lemma builtins

" Variables
syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ 
syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ 
syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/ 

" Facts
syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ 
syntax keyword spthyBuiltinFact Fr In Out K

" Function names
syntax match spthyFunction /\<[a-z][A-Za-z0-9_]*\>(/he=e-1
]])

-- Mark file as handled
vim.b.spthy_syntax_loaded = true
vim.b.current_syntax = "spthy"

print("Syntax highlighting defined. Opening test file...")

-- Check if file exists and create it if needed
if vim.fn.filereadable(test_file) ~= 1 then
  local file = io.open(test_file, "w")
  if file then
    file:write([[
theory TestSyntax
begin

builtins: diffie-hellman, hashing

/* This is a comment */
// This is a line comment

rule Register_User:
  [ Fr(~id), Fr(~ltk) ]
  --[ Create($A, ~id), LongTermKey($A, ~ltk) ]->
  [ !User($A, ~id, ~ltk), !Pk($A, pk(~ltk)), Out(pk(~ltk)) ]

lemma secrecy [reuse]:
  "All A x #i. Secret(x, A)@i ==> not(Ex #j. K(x)@j)"

end
]])
    file:close()
    print("Created test file: " .. test_file)
  end
end

-- Open test file
vim.cmd("edit " .. test_file)

-- Check syntax highlighting
print("\nChecking syntax highlighting for selected elements:")

-- Function to check highlighting at a position
local function check_highlight(line, col, desc)
  -- Get syntax ID at position
  local syntax_id = vim.fn.synID(line, col, true)
  local syntax_name = vim.fn.synIDattr(syntax_id, "name")
  local trans_id = vim.fn.synIDtrans(syntax_id)
  local color = vim.fn.synIDattr(trans_id, "fg#")
  
  if color == "" then color = "none" end
  
  print(string.format("- %s (line %d, col %d): Group=%s, Color=%s", 
                     desc, line, col, syntax_name, color))
end

-- Check specific positions (based on knowing our test file layout)
check_highlight(1, 1, "theory keyword")
check_highlight(9, 1, "rule keyword")
check_highlight(11, 14, "$A variable")
check_highlight(10, 8, "~id variable")
check_highlight(12, 5, "!User fact")
check_highlight(10, 5, "Fr fact")

print("\nTest completed. Check the results above to see if highlighting is working.")

-- Exit
vim.cmd("qa!") 