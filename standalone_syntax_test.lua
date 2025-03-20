-- Standalone Tamarin Syntax Test
-- This script includes the color definitions directly so it works in any environment

print("Starting standalone Tamarin syntax test...")

-- Direct color definitions
local colors = {
  -- Base colors with styles
  magentaBold = { fg = "#FF00FF", bold = true },
  deepGreen = { fg = "#006400", bold = false },
  hotPinkPlain = { fg = "#FF69B4", bold = false },
  skyBluePlain = { fg = "#00BFFF", bold = false },
  redBold = { fg = "#FF3030", bold = true },
  blueBoldUnderlined = { fg = "#1E90FF", bold = true, underline = true },
  blueBold = { fg = "#1E90FF", bold = true },
  lightPinkPlain = { fg = "#FFB6C1", bold = false },
  tomatoItalic = { fg = "#FF6347", italic = true, bold = false },
  slateGrayBold = { fg = "#708090", bold = true },
  slateGrayPlain = { fg = "#708090" },
  grayItalic = { fg = "#777777", italic = true },
  hotPinkBold = { fg = "#FF1493", bold = true }
}

-- Set timeout protection
local start_time = os.time()
local function check_timeout(max_seconds)
  if os.time() - start_time > max_seconds then
    print("ERROR: Script execution timed out after " .. max_seconds .. " seconds")
    os.exit(1)
  end
end

-- Test file path
local test_file = "/Users/dan/.config/nvim/test.spthy"

-- Disable any interactive prompts
vim.opt.shortmess:append("aoOstTWAIcCqfs")
vim.opt.more = false
vim.opt.confirm = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.api.nvim_set_keymap('n', 'q', '<Nop>', {noremap = true})
vim.api.nvim_set_keymap('n', 'Q', '<Nop>', {noremap = true})

-- Force syntax highlighting on
vim.cmd("syntax on")
vim.cmd("syntax enable")

-- Set filetype explicitly
vim.opt.filetype = "spthy"

-- Check initial state
print("Initial syntax state:")
print("  Filetype: " .. vim.bo.filetype)
print("  Syntax: " .. vim.bo.syntax)

-- Define direct syntax highlighting
print("\nApplying syntax highlighting...")

-- Apply highlight colors
local function apply_colors()
  -- Keywords
  vim.cmd("highlight spthyKeyword guifg=#FF00FF gui=bold")
  
  -- Variables
  vim.cmd("highlight spthyPublicVar guifg=#006400")
  vim.cmd("highlight spthyPublicVarPrefix guifg=#006400")
  vim.cmd("highlight spthyFreshVar guifg=#FF69B4")
  vim.cmd("highlight spthyFreshVarPrefix guifg=#FF69B4")
  vim.cmd("highlight spthyTemporalVar guifg=#00BFFF")
  vim.cmd("highlight spthyTemporalVarPrefix guifg=#00BFFF")
  
  -- Facts
  vim.cmd("highlight spthyPersistentFact guifg=#FF3030 gui=bold")
  vim.cmd("highlight spthyPersistentFactPrefix guifg=#FF3030 gui=bold")
  vim.cmd("highlight spthyBuiltinFact guifg=#1E90FF gui=bold,underline")
  vim.cmd("highlight spthyNormalFact guifg=#1E90FF gui=bold")
  vim.cmd("highlight spthyActionFact guifg=#FFB6C1")
  
  -- Functions
  vim.cmd("highlight spthyFunction guifg=#FF6347 gui=italic")
  vim.cmd("highlight spthyBuiltinFunction guifg=#1E90FF gui=bold,underline")
  
  -- Operators
  vim.cmd("highlight spthyRuleArrow guifg=#708090 gui=bold")
  vim.cmd("highlight spthyOperator guifg=#708090")
  vim.cmd("highlight spthyBracket guifg=#708090")
  
  -- Comments
  vim.cmd("highlight spthyComment guifg=#777777 gui=italic")
  
  -- Constants
  vim.cmd("highlight spthyConstant guifg=#FF1493 gui=bold")
end

-- Apply syntax patterns
local function apply_syntax()
  vim.cmd([[
    " Clear any existing syntax
    syntax clear
    
    " Comments
    syntax match spthyComment /\/\/.*$/ contains=@Spell
    syntax region spthyComment start="/\*" end="\*/" fold contains=@Spell
    
    " Keywords
    syntax keyword spthyKeyword theory begin end
    syntax keyword spthyKeyword rule lemma axiom builtins
    syntax keyword spthyKeyword functions equations predicates
    syntax keyword spthyKeyword restrictions let in
    
    " Public variables with '$' prefix
    syntax match spthyPublicVarPrefix /\$/ contained
    syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ contains=spthyPublicVarPrefix containedin=ALL
    
    " Fresh variables with '~' prefix
    syntax match spthyFreshVarPrefix /\~/ contained
    syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ contains=spthyFreshVarPrefix containedin=ALL
    
    " Temporal variables with '#' prefix
    syntax match spthyTemporalVarPrefix /#/ contained
    syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/ contains=spthyTemporalVarPrefix containedin=ALL
    
    " Persistent facts with '!' prefix
    syntax match spthyPersistentFactPrefix /!/ contained
    syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ contains=spthyPersistentFactPrefix
    
    " Built-in facts
    syntax keyword spthyBuiltinFact Fr In Out K
    
    " Action facts
    syntax region spthyActionFact start=/--\[/ end=/\]->/ contains=spthyRuleArrow,spthyFreshVar,spthyPublicVar,spthyTemporalVar,spthyPersistentFact,spthyBuiltinFact,spthyNormalFact
    
    " Regular facts
    syntax match spthyNormalFact /\<[A-Z][A-Za-z0-9_]*\>/ contains=NONE
    
    " Function names
    syntax match spthyFunction /\<[a-z][A-Za-z0-9_]*\>(/he=e-1
    
    " Builtin function names
    syntax keyword spthyBuiltinFunction h pk sign verify senc sdec aenc adec mac verify
    
    " Rule arrows and symbols
    syntax match spthyRuleArrow /--\[\|\]->/ 
    
    " Equal sign in let statements
    syntax match spthyOperator /=/ 
    
    " Standard brackets and delimiters
    syntax match spthyBracket /(\|)\|\[\|\]\|{\|}\|,\|;\|:/
    
    " Constants in single quotes
    syntax region spthyConstant start=/'/ end=/'/ 
  ]])
end

-- Apply the colors and syntax
local ok, err = pcall(function()
  apply_syntax()
  apply_colors()
  
  -- Mark file as handled
  vim.b.spthy_syntax_loaded = true
  vim.b.current_syntax = "spthy"
end)

if not ok then
  print("Error applying syntax: " .. tostring(err))
  os.exit(1)
end

print("Syntax highlighting applied. Testing results...")

-- Check if the file exists and open it
if vim.fn.filereadable(test_file) ~= 1 then
  print("Test file not found, creating it...")
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
  else
    print("Could not create test file")
    os.exit(1)
  end
end

-- Open the test file
ok, err = pcall(function()
  vim.cmd("edit " .. test_file)
end)

if not ok then
  print("Error opening test file: " .. tostring(err))
  os.exit(1)
end

check_timeout(5)

-- Test specific tokens
local test_tokens = {
  { text = "theory", expected_group = "spthyKeyword", expected_color = "#FF00FF" },
  { text = "rule", expected_group = "spthyKeyword", expected_color = "#FF00FF" },
  { text = "$A", expected_group = "spthyPublicVar", expected_color = "#006400" },
  { text = "~id", expected_group = "spthyFreshVar", expected_color = "#FF69B4" },
  { text = "!User", expected_group = "spthyPersistentFact", expected_color = "#FF3030" },
  { text = "Fr", expected_group = "spthyBuiltinFact", expected_color = "#1E90FF" }
}

print("\nTesting token highlighting:")

-- Function to find the position of text
local function find_position(text)
  -- Get the buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  
  for line_num, line in ipairs(lines) do
    local col = line:find(text, 1, true)
    if col then
      return line_num, col
    end
  end
  
  return nil, nil
end

-- Test each token
local pass_count = 0
local fail_count = 0

for _, token in ipairs(test_tokens) do
  local line_num, col = find_position(token.text)
  
  if line_num and col then
    -- Convert to 0-based indices for API calls
    local buf_line = line_num - 1
    local buf_col = col - 1
    
    -- Get syntax ID at position
    local syntax_id = vim.fn.synID(line_num, col, true)
    local syntax_name = vim.fn.synIDattr(syntax_id, "name")
    local trans_id = vim.fn.synIDtrans(syntax_id)
    local color = vim.fn.synIDattr(trans_id, "fg#")
    
    if color == "" then color = "none" end
    
    print(string.format("Token '%s' (line %d, col %d):", token.text, line_num, col))
    print(string.format("  Group: %s (expected %s)", syntax_name, token.expected_group))
    print(string.format("  Color: %s (expected %s)", color, token.expected_color))
    
    if syntax_name == token.expected_group and color:lower() == token.expected_color:lower() then
      print("  ✓ PASS")
      pass_count = pass_count + 1
    else
      print("  ✗ FAIL")
      fail_count = fail_count + 1
    end
  else
    print(string.format("Token '%s' not found in file", token.text))
    fail_count = fail_count + 1
  end
end

-- Print summary
print("\nTest Summary:")
print(string.format("  Passed: %d", pass_count))
print(string.format("  Failed: %d", fail_count))

if fail_count > 0 then
  print("\nSome tests failed. The syntax highlighting is not correctly applied.")
else
  print("\nAll tests passed! Syntax highlighting is working correctly.")
end

-- Exit cleanly
vim.cmd("qa!") 