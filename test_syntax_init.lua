-- Test script for Tamarin syntax initialization
print("Starting syntax initialization test...")

-- Set timeout protection
local start_time = os.time()
local function check_timeout(max_seconds)
  if os.time() - start_time > max_seconds then
    print("ERROR: Script execution timed out after " .. max_seconds .. " seconds")
    os.exit(1)
  end
end

-- Test file path
local test_file = "/Users/dan/.config/nvim/lua/test/test_tamarin_file.spthy"

-- Disable any interactive prompts
vim.opt.shortmess:append("aoOstTWAIcCqfs")
vim.opt.more = false
vim.opt.confirm = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.api.nvim_set_keymap('n', 'q', '<Nop>', {noremap = true})
vim.api.nvim_set_keymap('n', 'Q', '<Nop>', {noremap = true})

-- Initialize
vim.cmd("syntax on")
vim.cmd("syntax enable")

-- Check file existence
if vim.fn.filereadable(test_file) == 0 then
  print("ERROR: Test file not found: " .. test_file)
  os.exit(1)
end

-- Open file
local ok, err = pcall(function()
  vim.cmd("edit " .. test_file)
end)

if not ok then
  print("ERROR opening file: " .. tostring(err))
  os.exit(1)
end

check_timeout(2)

-- Check initial state
print("Initial state:")
print("Filetype: " .. vim.bo.filetype)
print("Syntax: " .. vim.bo.syntax)
print("Current syntax: " .. tostring(vim.b.current_syntax))
print("spthy_syntax_loaded: " .. tostring(vim.b.spthy_syntax_loaded))

-- Run our initialization script with error handling
print("\nRunning initialization script...")
ok, err = pcall(function()
  dofile(vim.fn.stdpath('config') .. '/init_tamarin_syntax.lua')
end)

if not ok then
  print("ERROR in initialization script: " .. tostring(err))
  os.exit(1)
end

check_timeout(4)

-- Check state after initialization
print("\nState after initialization:")
print("Filetype: " .. vim.bo.filetype)
print("Syntax: " .. vim.bo.syntax)
print("Current syntax: " .. tostring(vim.b.current_syntax))
print("spthy_syntax_loaded: " .. tostring(vim.b.spthy_syntax_loaded))

-- Test if colors are applied
local keywords = {"theory", "begin", "rule", "lemma"}
local public_vars = {"$A", "$B", "$C"}
local fresh_vars = {"~id", "~ltk", "~sk"}
local temporal_vars = {"#i", "#j"}
local persistent_facts = {"!User", "!Pk", "!Session"}

-- Function to test highlight at a specific position
local function test_highlight(text, line)
  check_timeout(8) -- Prevent infinite loops
  
  local col
  
  -- Find the text in the line
  local file = io.open(test_file, "r")
  if not file then
    print("Couldn't open test file")
    return
  end
  
  local content = {}
  for l in file:lines() do
    table.insert(content, l)
  end
  file:close()
  
  -- Find the text in the specified line or scan all lines
  if line then
    col = content[line]:find(text)
    if col then
      print(string.format("Testing highlight for '%s' at line %d, col %d:", text, line, col))
      local syntax_id = vim.fn.synID(line, col, true)
      local syntax_name = vim.fn.synIDattr(syntax_id, "name")
      local trans_id = vim.fn.synIDtrans(syntax_id)
      local color = vim.fn.synIDattr(trans_id, "fg#")
      
      if color == "" then color = "none" end
      
      print(string.format("  Group: %s, Color: %s", syntax_name, color))
      return {group = syntax_name, color = color}
    end
  else
    -- Scan all lines - limit scan to first 100 lines
    local max_lines = math.min(100, #content)
    for l=1, max_lines do
      local line_text = content[l]
      col = line_text:find(text, 1, true)
      if col then
        print(string.format("Found '%s' at line %d, col %d:", text, l, col))
        local syntax_id = vim.fn.synID(l, col, true)
        local syntax_name = vim.fn.synIDattr(syntax_id, "name")
        local trans_id = vim.fn.synIDtrans(syntax_id)
        local color = vim.fn.synIDattr(trans_id, "fg#")
        
        if color == "" then color = "none" end
        
        print(string.format("  Group: %s, Color: %s", syntax_name, color))
        return {group = syntax_name, color = color}
      end
    end
  end
  
  print(string.format("Text '%s' not found in first 100 lines", text))
  return nil
end

-- Run the test in a protected call to catch any errors
ok, err = pcall(function()
  -- Test highlights for different syntax elements
  print("\nTesting highlight groups:")
  
  -- Test limited number of elements to avoid timeout
  for i, kw in ipairs(keywords) do
    if i <= 2 then  -- Only test the first 2 keywords
      test_highlight(kw)
      check_timeout(8)
    end
  end
  
  for i, var in ipairs(public_vars) do
    if i <= 2 then  -- Only test the first 2 variables
      test_highlight(var)
      check_timeout(8)
    end
  end
  
  for i, var in ipairs(fresh_vars) do
    if i <= 2 then
      test_highlight(var)
      check_timeout(8)
    end
  end
  
  for i, var in ipairs(temporal_vars) do
    if i <= 1 then
      test_highlight(var)
      check_timeout(8)
    end
  end
  
  for i, fact in ipairs(persistent_facts) do
    if i <= 1 then
      test_highlight(fact)
      check_timeout(8)
    end
  end
end)

if not ok then
  print("ERROR testing highlights: " .. tostring(err))
  os.exit(1)
end

print("\nTest completed.")

-- Force exit to avoid any hanging
vim.cmd("qa!") 