-- Fix Tamarin Syntax Script
-- This script applies the necessary changes to make Tamarin syntax highlighting work

-- Configuration
local ftplugin_file = "/Users/dan/.config/nvim/ftplugin/spthy.vim"
local colors_file = "/Users/dan/.config/nvim/lua/config/spthy-colorscheme.lua"
local test_file = "/Users/dan/.config/nvim/test.spthy"

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

-- Check if files exist
local function check_files()
  print("Checking required files...")
  
  local file_errors = {}
  
  -- Check ftplugin file
  if not vim.fn.filereadable(ftplugin_file) then
    table.insert(file_errors, "ftplugin file not found: " .. ftplugin_file)
  end
  
  -- Check colors file
  if not vim.fn.filereadable(colors_file) then
    table.insert(file_errors, "colors file not found: " .. colors_file)
  end
  
  return #file_errors == 0, file_errors
end

-- Update the ftplugin file to properly load syntax highlighting
local function update_ftplugin()
  print("Updating ftplugin file...")
  
  -- Read current file
  local content = read_file(ftplugin_file)
  if not content then
    return false, "Failed to read ftplugin file"
  end
  
  -- Create backup
  local ok, err = write_file(ftplugin_file .. ".bak", content)
  if not ok then
    return false, "Failed to create backup: " .. err
  end
  
  -- New content with direct syntax highlighting
  local new_content = [[
" ftplugin for Spthy files
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Set comment string for Spthy files
setlocal commentstring=/*%s*/
setlocal comments=s1:/*,mb:*,ex:*/

" Set formatting options
setlocal formatoptions+=ro
setlocal formatoptions-=t

" Enable folding by syntax
setlocal foldmethod=syntax
setlocal foldlevel=99

" -----------------------------------
" DIRECT SYNTAX HIGHLIGHTING SETUP
" -----------------------------------

" Step 1: Set filetype and enable syntax
setlocal filetype=spthy
syntax on
syntax enable

" Step 2: Force-load the tamarin color library
lua << EOF
-- Directly define the colors
TamarinColors = {
  -- Base colors (alphabetical by name)
  blueBold                = { fg = "#1E90FF", bold = true },            -- Dodger Blue - vibrant blue for linear facts
  blueBoldUnderlined      = { fg = "#1E90FF", bold = true, underline = true }, -- Same blue with underline for builtin facts
  brownNoStyle            = { fg = "#8B4513" },                         -- SaddleBrown - for numbers
  brownPlain              = { fg = "#8B4513", bold = false },           -- SaddleBrown - for number variables
  deepGreen               = { fg = "#006400", bold = false },           -- Deep green for public variables, rich and forest-like
  goldBold                = { fg = "#FFD700", bold = true },            -- Gold - for rule/theory names with bold
  goldBoldUnderlined      = { fg = "#FFD700", bold = true, underline = true }, -- Gold with underline for builtins
  goldItalic              = { fg = "#FFD700", bold = false, italic = true }, -- Gold with italic for theory names
  grayItalic              = { fg = "#777777", italic = true },          -- Gray - for comments
  grayPlain               = { fg = "#888888", bold = false },           -- Gray - for logical operators
  hotPinkBold             = { fg = "#FF1493", bold = true },            -- Deep Pink - for public constants
  hotPinkPlain            = { fg = "#FF69B4", bold = false },           -- Hot Pink - for fresh variables (~k)
  lightPinkPlain          = { fg = "#FFB6C1", bold = false },           -- Light Pink - for action facts
  lilacBold               = { fg = "#D7A0FF", bold = true },            -- Lilac - for keyword quantifiers
  magentaBold             = { fg = "#FF00FF", bold = true },            -- Magenta - for keywords
  orangeNoStyle           = { fg = "#FF8C00" },                         -- Dark Orange - for regular variables
  orangePlain             = { fg = "#FF8C00", bold = false },           -- Dark Orange - for message variables
  orchidItalic            = { fg = "#DA70D6", italic = true },          -- Orchid - for string constants
  orchidPlain             = { fg = "#DA70D6" },                         -- Orchid - for constants
  pinkPlain               = { fg = "#FFC0CB", italic = false },         -- Pink - for type qualifiers
  purplePlain             = { fg = "#AA88FF" },                         -- Purple - for exponentiation
  redBold                 = { fg = "#FF3030", bold = true },            -- Firebrick Red - for persistent facts (!Ltk)
  redBoldUnderlined       = { fg = "#FF0000", bold = true, underline = true }, -- Red with underline - for errors
  royalBlue               = { fg = "#4169E1", italic = false },         -- Royal Blue - for rule conclusions
  skyBluePlain            = { fg = "#00BFFF", bold = false },           -- Deep Sky Blue - for temporal variables (#i)
  slateBlue               = { fg = "#6A5ACD", italic = false },         -- Slate Blue - for rule premises
  slateGrayBold           = { fg = "#708090", bold = true },            -- Slate Gray - for operators with bold
  slateGrayPlain          = { fg = "#708090" },                         -- Slate Gray - for punctuation
  tomatoItalic            = { fg = "#FF6347", italic = true, bold = false } -- Tomato - for functions with italic
}

-- Apply the colors directly
function ApplyDirectColors()
  -- Define direct highlight groups
  vim.cmd("highlight clear")
  
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

-- Call the function right away
ApplyDirectColors()
EOF

" Step 3: Define syntax patterns
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

" Mark that we're done
let b:current_syntax = "spthy"
let b:spthy_syntax_loaded = 1
]]

  -- Write new file
  ok, err = write_file(ftplugin_file, new_content)
  if not ok then
    return false, "Failed to write new ftplugin file: " .. err
  end
  
  return true
end

-- Create a test file if it doesn't exist
local function ensure_test_file()
  print("Ensuring test file exists...")
  
  if vim.fn.filereadable(test_file) == 1 then
    print("  Test file already exists")
    return true
  end
  
  local test_content = [[
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
]]

  local ok, err = write_file(test_file, test_content)
  if not ok then
    print("  Error creating test file: " .. err)
    return false
  end
  
  print("  Created test file: " .. test_file)
  return true
end

-- Main function
local function main()
  print("Starting Tamarin syntax fixing...")
  
  -- Check files
  local files_ok, file_errors = check_files()
  if not files_ok then
    print("File check errors:")
    for _, err in ipairs(file_errors) do
      print("  - " .. err)
    end
    return false
  end
  
  -- Ensure we have a test file
  if not ensure_test_file() then
    return false
  end
  
  -- Update ftplugin
  local ok, err = update_ftplugin()
  if not ok then
    print("Error updating ftplugin: " .. err)
    return false
  end
  
  print("Successfully updated ftplugin file.")
  print("To test the changes, open a .spthy file in Neovim.")
  
  return true
end

-- Run the main function
if main() then
  print("Tamarin syntax fixing completed successfully!")
else
  print("Tamarin syntax fixing failed!")
end 