-- Tamarin TreeSitter Implementation Test
-- Tests the complete implementation of Tamarin TreeSitter syntax highlighting

local M = {}

-- Helper function for logging
local log_file = io.open(vim.fn.stdpath('data') .. '/tamarin_test.log', 'w')
local function log(message)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  log_file:write(timestamp .. ": " .. message .. "\n")
  log_file:flush()
  print(message)
end

-- Create test files
function M.create_test_files()
  log("Creating test files...")
  
  -- Basic test file
  local basic = io.open("test_basic.spthy", "w")
  basic:write([[
theory BasicTest
begin

builtins: symmetric-encryption, hashing

// Simple rule
rule Simple:
    [ ] --[ ]-> [ ]

// Rule with variables
rule WithVariables:
    let x = 'value'
    let y = 'another'
    in
    [ In(x) ] --[ Action(x, y) ]-> [ Out(y) ]

// Lemma
lemma secrecy:
    "∀ x #i. Secret(x) @ i ⟹ ¬(∃ #j. K(x) @ j)"

end
]])
  basic:close()
  
  -- Advanced test file with apostrophes
  local advanced = io.open("test_advanced.spthy", "w")
  advanced:write([[
theory AdvancedTest
begin

builtins: symmetric-encryption, signing, hashing

// Rule with apostrophe variables
rule Apostrophes:
    let x' = 'prime'
    let y' = 'also prime'
    in
    [ In(x') ] --[ Action(x', y') ]-> [ Out(y') ]

// Nested apostrophes
rule NestedApostrophes:
    let complex'name' = 'complex'
    in
    [ ] --[ ]-> [ Out(complex'name') ]

// Multiple rules
rule Rule1:
    [ ] --[ ]-> [ ]
    
rule Rule2:
    [ ] --[ ]-> [ ]

lemma authentication:
    "∀ x y #i #j. Send(x, y) @ i ∧ Recv(x, y) @ j ⟹ j > i"

end
]])
  advanced:close()
  
  log("Test files created successfully")
end

-- Set up parser registration
function M.setup_parser()
  log("Setting up parser...")
  
  -- Check if TreeSitter is available
  if not vim.treesitter then
    log("ERROR: TreeSitter not available")
    return false
  end
  
  -- Find the parser file
  local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  if vim.fn.filereadable(parser_path) ~= 1 then
    log("ERROR: Parser file not found: " .. parser_path)
    return false
  end
  
  -- Register language to filetype mapping
  local ok, result = pcall(function()
    vim.treesitter.language.register('spthy', 'tamarin')
    
    -- Add parser from path (Neovim 0.9+)
    if vim.treesitter.language.add then
      vim.treesitter.language.add('spthy', { path = parser_path })
    end
  end)
  
  if not ok then
    log("ERROR: Failed to register parser: " .. result)
    return false
  end
  
  log("Parser registered successfully")
  return true
end

-- Create query files
function M.create_query_files()
  log("Creating query files...")
  
  -- Create queries directory if it doesn't exist
  local queries_dir = vim.fn.stdpath('config') .. '/queries/spthy'
  vim.fn.mkdir(queries_dir, "p")
  
  -- Minimal query file
  local minimal = io.open(queries_dir .. "/highlights.scm.minimal", "w")
  minimal:write([[
;; Ultra-Minimal Tamarin Syntax Highlighting
;; No regex patterns at all

;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "lemma"
] @keyword

;; Comments
(comment) @comment

;; Strings
(string) @string
]])
  minimal:close()
  
  -- Basic query file
  local basic = io.open(queries_dir .. "/highlights.scm.basic", "w")
  basic:write([[
;; Basic Tamarin Syntax Highlighting
;; Simple patterns only

;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "let"
  "in"
  "builtins"
  "lemma"
] @keyword

;; Comments
(comment) @comment

;; Strings
(string) @string

;; Simple types
(identifier) @variable
]])
  basic:close()
  
  -- Standard query file
  local standard = io.open(queries_dir .. "/highlights.scm.standard", "w")
  standard:write([[
;; Standard Tamarin Syntax Highlighting
;; Some regex patterns, but not complex ones

;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "let"
  "in"
  "builtins"
  "lemma"
] @keyword

;; Comments
(comment) @comment

;; Strings
(string) @string

;; Constants (all uppercase)
((identifier) @constant
 (#match? @constant "^[A-Z][A-Z0-9_]*$"))

;; Variables (all lowercase)
((identifier) @variable
 (#match? @variable "^[a-z][a-zA-Z0-9_]*$"))
]])
  standard:close()
  
  -- Complex query file
  local complex = io.open(queries_dir .. "/highlights.scm.complex", "w")
  complex:write([[
;; Complex Tamarin Syntax Highlighting
;; Includes complex regex patterns that might cause issues

;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "let"
  "in"
  "builtins"
  "lemma"
] @keyword

;; Comments
(comment) @comment

;; Strings
(string) @string

;; Constants (all uppercase)
((identifier) @constant
 (#match? @constant "^[A-Z][A-Z0-9_]*$"))

;; Variables with apostrophes (likely problematic)
((identifier) @variable.apostrophe
 (#match? @variable.apostrophe "^[a-z][a-zA-Z0-9_]*(\'[a-zA-Z0-9_]*)+$"))

;; Normal variables
((identifier) @variable.normal
 (#match? @variable.normal "^[a-z][a-zA-Z0-9_]*$")
 (#not-match? @variable.normal "\'"))

;; Complex pattern (almost certainly problematic)
((identifier) @problematic
 (#match? @problematic "^([a-z][a-zA-Z0-9_]*)(\'([a-zA-Z0-9_]*))?$|^[A-Z][A-Z0-9_]*$"))
]])
  complex:close()
  
  -- Safe alternative query file
  local alternative = io.open(queries_dir .. "/highlights.scm.alternative", "w")
  alternative:write([[
;; Safe Alternative Tamarin Syntax Highlighting
;; Uses multiple simple predicates instead of complex regex

;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "let"
  "in"
  "builtins"
  "lemma"
] @keyword

;; Comments
(comment) @comment

;; Strings
(string) @string

;; Constants (all uppercase)
((identifier) @constant
 (#match? @constant "^[A-Z]"))

;; Variables with apostrophes (using multiple simple predicates)
((identifier) @variable.apostrophe
 (#match? @variable.apostrophe "^[a-z]")
 (#match? @variable.apostrophe "\'"))

;; Normal variables
((identifier) @variable.normal
 (#match? @variable.normal "^[a-z]")
 (#not-match? @variable.normal "\'"))
]])
  alternative:close()
  
  -- Copy the selected query file to the active one
  local active = io.open(queries_dir .. "/highlights.scm", "w")
  active:write(io.open(queries_dir .. "/highlights.scm.minimal", "r"):read("*all"))
  active:close()
  
  log("Query files created successfully")
  return true
end

-- Set up highlighter for buffer
function M.setup_highlighting(bufnr, store_in_buffer)
  log("Setting up highlighting for buffer " .. bufnr .. " (store_in_buffer=" .. tostring(store_in_buffer) .. ")")
  
  -- Skip if not a Tamarin buffer
  if vim.bo[bufnr].filetype ~= "tamarin" then
    log("ERROR: Not a Tamarin buffer")
    return false
  end
  
  -- Check if TreeSitter is available
  if not vim.treesitter or not vim.treesitter.highlighter then
    log("ERROR: TreeSitter highlighter not available")
    return false
  end
  
  -- Get parser
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_ok or not parser then
    log("ERROR: Failed to get parser")
    return false
  end
  
  -- Create highlighter
  local highlighter_ok, highlighter = pcall(vim.treesitter.highlighter.new, parser)
  if not highlighter_ok or not highlighter then
    log("ERROR: Failed to create highlighter")
    return false
  end
  
  -- Store in buffer-local variable to prevent garbage collection (if requested)
  if store_in_buffer then
    vim.b[bufnr].tamarin_ts_highlighter = highlighter
    log("Highlighter stored in buffer-local variable")
  else
    log("Highlighter NOT stored in buffer-local variable (may be garbage collected)")
  end
  
  log("Highlighting set up successfully")
  return true
end

-- Test with different query files
function M.test_query_files()
  log("Testing different query files...")
  
  local queries_dir = vim.fn.stdpath('config') .. '/queries/spthy'
  local query_files = {
    minimal = queries_dir .. "/highlights.scm.minimal",
    basic = queries_dir .. "/highlights.scm.basic",
    standard = queries_dir .. "/highlights.scm.standard",
    complex = queries_dir .. "/highlights.scm.complex",
    alternative = queries_dir .. "/highlights.scm.alternative"
  }
  
  local results = {}
  
  for name, path in pairs(query_files) do
    log("Testing query file: " .. name)
    
    -- Copy the query file to the active one
    local active = io.open(queries_dir .. "/highlights.scm", "w")
    active:write(io.open(path, "r"):read("*all"))
    active:close()
    
    -- Open test file and set up highlighting
    vim.cmd("edit test_advanced.spthy")
    vim.cmd("set filetype=tamarin")
    
    -- Try to parse the query
    local query_content = io.open(path, "r"):read("*all")
    local query_ok, query_error = pcall(function()
      return vim.treesitter.query.parse('spthy', query_content)
    end)
    
    -- Try to set up highlighting
    local highlight_ok, highlight_error = pcall(function()
      return M.setup_highlighting(0, true)
    end)
    
    -- Force garbage collection to ensure stability
    collectgarbage("collect")
    
    -- Check if highlighting is still active
    local highlight_active = vim.treesitter.highlighter and 
                            vim.treesitter.highlighter.active and 
                            vim.treesitter.highlighter.active[0] ~= nil
    
    results[name] = {
      query_ok = query_ok,
      query_error = query_error,
      highlight_ok = highlight_ok,
      highlight_error = highlight_error,
      highlight_active = highlight_active
    }
    
    log("  Query parse: " .. (query_ok and "SUCCESS" or "FAILED"))
    if not query_ok then
      log("  Query error: " .. tostring(query_error))
    end
    
    log("  Highlighting setup: " .. (highlight_ok and "SUCCESS" or "FAILED"))
    if not highlight_ok then
      log("  Highlighting error: " .. tostring(highlight_error))
    end
    
    log("  Highlighting active after GC: " .. (highlight_active and "YES" or "NO"))
  end
  
  log("Query file tests completed")
  return results
end

-- Test garbage collection behavior
function M.test_garbage_collection()
  log("Testing garbage collection behavior...")
  
  local results = {
    with_gc_prevention = {},
    without_gc_prevention = {}
  }
  
  -- Test with GC prevention
  log("Testing with GC prevention...")
  vim.cmd("edit test_basic.spthy")
  vim.cmd("set filetype=tamarin")
  
  local with_gc_ok = M.setup_highlighting(0, true)
  
  -- Force garbage collection
  collectgarbage("collect")
  
  -- Check if highlighting is still active
  local with_gc_active = vim.treesitter.highlighter and 
                        vim.treesitter.highlighter.active and 
                        vim.treesitter.highlighter.active[0] ~= nil
  
  results.with_gc_prevention = {
    setup_ok = with_gc_ok,
    active_after_gc = with_gc_active
  }
  
  log("  Setup: " .. (with_gc_ok and "SUCCESS" or "FAILED"))
  log("  Active after GC: " .. (with_gc_active and "YES" or "NO"))
  
  -- Test without GC prevention
  log("Testing without GC prevention...")
  vim.cmd("edit test_advanced.spthy")
  vim.cmd("set filetype=tamarin")
  
  local without_gc_ok = M.setup_highlighting(0, false)
  
  -- Force garbage collection
  collectgarbage("collect")
  
  -- Check if highlighting is still active
  local without_gc_active = vim.treesitter.highlighter and 
                           vim.treesitter.highlighter.active and 
                           vim.treesitter.highlighter.active[0] ~= nil
  
  results.without_gc_prevention = {
    setup_ok = without_gc_ok,
    active_after_gc = without_gc_active
  }
  
  log("  Setup: " .. (without_gc_ok and "SUCCESS" or "FAILED"))
  log("  Active after GC: " .. (without_gc_active and "YES" or "NO"))
  
  log("Garbage collection tests completed")
  return results
end

-- Test buffer switching
function M.test_buffer_switching()
  log("Testing buffer switching behavior...")
  
  -- Set up first buffer
  vim.cmd("edit test_basic.spthy")
  vim.cmd("set filetype=tamarin")
  local setup1_ok = M.setup_highlighting(0, true)
  local bufnr1 = vim.api.nvim_get_current_buf()
  
  -- Set up second buffer
  vim.cmd("edit test_advanced.spthy")
  vim.cmd("set filetype=tamarin")
  local setup2_ok = M.setup_highlighting(0, true)
  local bufnr2 = vim.api.nvim_get_current_buf()
  
  -- Switch back to first buffer
  vim.cmd("buffer " .. bufnr1)
  
  -- Check if highlighting is still active for first buffer
  local active1 = vim.treesitter.highlighter and 
                 vim.treesitter.highlighter.active and 
                 vim.treesitter.highlighter.active[bufnr1] ~= nil
  
  -- Switch to second buffer
  vim.cmd("buffer " .. bufnr2)
  
  -- Check if highlighting is still active for second buffer
  local active2 = vim.treesitter.highlighter and 
                 vim.treesitter.highlighter.active and 
                 vim.treesitter.highlighter.active[bufnr2] ~= nil
  
  log("  Buffer 1 setup: " .. (setup1_ok and "SUCCESS" or "FAILED"))
  log("  Buffer 2 setup: " .. (setup2_ok and "SUCCESS" or "FAILED"))
  log("  Buffer 1 active after switching: " .. (active1 and "YES" or "NO"))
  log("  Buffer 2 active after switching: " .. (active2 and "YES" or "NO"))
  
  log("Buffer switching tests completed")
  return {
    buffer1 = {
      setup_ok = setup1_ok,
      active_after_switching = active1
    },
    buffer2 = {
      setup_ok = setup2_ok,
      active_after_switching = active2
    }
  }
end

-- Run all tests
function M.run_all_tests()
  log("Starting implementation tests...")
  
  local results = {}
  
  -- Create test files
  M.create_test_files()
  
  -- Set up parser
  results.parser_setup = M.setup_parser()
  
  if not results.parser_setup then
    log("ERROR: Parser setup failed, skipping remaining tests")
    return results
  end
  
  -- Create query files
  results.query_files_setup = M.create_query_files()
  
  -- Run tests
  results.query_files_test = M.test_query_files()
  results.garbage_collection_test = M.test_garbage_collection()
  results.buffer_switching_test = M.test_buffer_switching()
  
  log("All tests completed")
  log_file:close()
  
  return results
end

return M 