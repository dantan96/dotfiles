# Test: TreeSitter Predicates with Complex Regex Patterns (H15)

## Hypothesis
TreeSitter query predicates like `#match?` could be causing stack overflow when applied to complex regex patterns.

## Background
TreeSitter uses predicates in query files to filter matches based on various conditions. The `#match?` predicate, in particular, applies regex patterns to node text. According to the TreeSitter documentation, regex patterns are processed by the host language's regex engine (Vim's engine for Neovim). Complex regex patterns, especially those with nested quantifiers, alternations, and backreferences, could potentially cause stack overflow errors in Vim's regex engine.

## Test Plan

1. **Compare different predicate patterns**
   - Test simple predicates without complex regex
   - Test predicates with progressively more complex regex patterns
   - Identify patterns that cause stack overflow errors

2. **Evaluate alternative approaches**
   - Replace complex regex with multiple simpler predicates
   - Use other predicate types like `#eq?` where appropriate
   - Compare performance and stability

3. **Test handling of apostrophes**
   - Focus on patterns involving apostrophes (common in Tamarin)
   - Test different regex approaches for matching apostrophe variables
   - Measure impact on stack overflow errors

## Test Cases

### Simple Patterns (Baseline)
```scheme
;; Simple pattern - should work reliably
((identifier) @constant
 (#match? @constant "^[A-Z]+$"))
```

### Moderate Complexity
```scheme
;; Moderate complexity - may work but could be problematic
((identifier) @identifier
 (#match? @identifier "^[a-z][a-zA-Z0-9_]*$"))
```

### High Complexity
```scheme
;; High complexity - likely to cause issues
((identifier) @variable
 (#match? @variable "^[a-z][a-zA-Z0-9_]*(\'[a-zA-Z0-9_]*)?$"))
```

### Extreme Complexity
```scheme
;; Extreme complexity - almost certainly problematic
((identifier) @problematic
 (#match? @problematic "^([a-z][a-zA-Z0-9_]*)(\'([a-zA-Z0-9_]*))?$|^[A-Z][A-Z0-9_]*$"))
```

### Alternative Approach
```scheme
;; Multiple simple predicates instead of one complex regex
((identifier) @variable.apostrophe
 (#match? @variable.apostrophe "^[a-z]")
 (#match? @variable.apostrophe "\'$"))

((identifier) @variable.normal
 (#match? @variable.normal "^[a-z]")
 (#not-match? @variable.normal "\'"))

((identifier) @constant
 (#match? @constant "^[A-Z]"))
```

## Test Script

```lua
-- File: predicate_test.lua
local M = {}

-- Test files
local test_files = {
  simple = "test_simple.spthy",
  apostrophes = "test_apostrophes.spthy"
}

-- Query files
local query_files = {
  simple = "highlights_simple.scm",
  moderate = "highlights_moderate.scm",
  complex = "highlights_complex.scm",
  extreme = "highlights_extreme.scm",
  alternative = "highlights_alternative.scm"
}

-- Create test files
function M.create_test_files()
  -- Simple test file
  local simple = io.open(test_files.simple, "w")
  simple:write([[
theory SimpleTest
begin

// Constants
rule Constants:
    [ ] --[ ]-> [ Out(CONSTANT, VALUE, RESULT) ]

// Simple variables
rule Variables:
    let varName = 'test'
    let otherVar = 'value'
    in
    [ ] --[ ]-> [ Out(varName, otherVar) ]

end
]])
  simple:close()
  
  -- Apostrophes test file
  local apostrophes = io.open(test_files.apostrophes, "w")
  apostrophes:write([[
theory ApostropheTest
begin

// Variables with apostrophes
rule Apostrophes:
    let x' = 'test'
    let y' = 'value'
    let complex'name = 'complex'
    in
    [ ] --[ ]-> [ Out(x', y', complex'name) ]

// Mixed variables
rule Mixed:
    let normal = 'normal'
    let apostrophe' = 'apostrophe'
    in
    [ ] --[ ]-> [ Out(normal, apostrophe', CONSTANT) ]

end
]])
  apostrophes:close()
end

-- Create query files
function M.create_query_files()
  -- Simple query file
  local simple = io.open(query_files.simple, "w")
  simple:write([[
;; Simple patterns only
(theory) @keyword
(rule) @keyword

(identifier) @variable
(constant) @constant
(string) @string
]])
  simple:close()
  
  -- Moderate complexity
  local moderate = io.open(query_files.moderate, "w")
  moderate:write([[
;; Moderate complexity patterns
(theory) @keyword
(rule) @keyword

((identifier) @constant
 (#match? @constant "^[A-Z]+$"))

((identifier) @variable
 (#match? @variable "^[a-z][a-zA-Z0-9_]*$"))

(string) @string
]])
  moderate:close()
  
  -- High complexity
  local complex = io.open(query_files.complex, "w")
  complex:write([[
;; Higher complexity patterns
(theory) @keyword
(rule) @keyword

((identifier) @constant
 (#match? @constant "^[A-Z][A-Z0-9_]*$"))

((identifier) @variable.apostrophe
 (#match? @variable.apostrophe "^[a-z][a-zA-Z0-9_]*'[a-zA-Z0-9_]*$"))

((identifier) @variable.normal
 (#match? @variable.normal "^[a-z][a-zA-Z0-9_]*$")
 (#not-match? @variable.normal "'"))

(string) @string
]])
  complex:close()
  
  -- Extreme complexity
  local extreme = io.open(query_files.extreme, "w")
  extreme:write([[
;; Extreme complexity patterns
(theory) @keyword
(rule) @keyword

((identifier) @identifier
 (#match? @identifier "^([a-z][a-zA-Z0-9_]*)(\'([a-zA-Z0-9_]*))?$|^[A-Z][A-Z0-9_]*$"))

(string) @string
]])
  extreme:close()
  
  -- Alternative approach
  local alternative = io.open(query_files.alternative, "w")
  alternative:write([[
;; Alternative approach with multiple simple predicates
(theory) @keyword
(rule) @keyword

;; Constants (all uppercase)
((identifier) @constant
 (#match? @constant "^[A-Z]"))

;; Variables with apostrophes
((identifier) @variable.apostrophe
 (#match? @variable.apostrophe "^[a-z]")
 (#match? @variable.apostrophe "'"))

;; Normal variables
((identifier) @variable.normal
 (#match? @variable.normal "^[a-z]")
 (#not-match? @variable.normal "'"))

(string) @string
]])
  alternative:close()
end

-- Test function
function M.test_query(query_file, test_file)
  local result = {
    query_file = query_file,
    test_file = test_file,
    success = false,
    error = nil,
    parse_time = 0,
    query_parse_time = 0
  }
  
  -- Read query file
  local query_content = io.open(query_file, "r"):read("*all")
  
  -- Try to parse the query
  local query_parse_start = vim.loop.hrtime()
  local query_ok, query_result = pcall(function()
    return vim.treesitter.query.parse('spthy', query_content)
  end)
  result.query_parse_time = (vim.loop.hrtime() - query_parse_start) / 1000000 -- Convert to ms
  
  if not query_ok then
    result.error = "Query parse error: " .. query_result
    return result
  end
  
  -- Try to parse the test file
  local parse_start = vim.loop.hrtime()
  local ok, err = pcall(function()
    local parser = vim.treesitter.get_parser(0, 'spthy')
    parser:parse()
    local matches = vim.treesitter.query.matches(query_result, parser:parse()[1]:root(), 0, -1)
    return #matches > 0
  end)
  result.parse_time = (vim.loop.hrtime() - parse_start) / 1000000 -- Convert to ms
  
  result.success = ok
  if not ok then
    result.error = "Parse error: " .. err
  end
  
  return result
end

-- Run all tests
function M.run_tests()
  -- Create test files and query files
  M.create_test_files()
  M.create_query_files()
  
  -- Run tests for each combination
  local results = {}
  
  for query_name, query_file in pairs(query_files) do
    for test_name, test_file in pairs(test_files) do
      local test_id = query_name .. "_" .. test_name
      print("Running test: " .. test_id)
      
      -- Open the test file
      vim.cmd("edit " .. test_file)
      
      -- Run the test
      results[test_id] = M.test_query(query_file, test_file)
      
      -- Display result
      if results[test_id].success then
        print("  Success! Parse time: " .. results[test_id].parse_time .. "ms")
      else
        print("  Failed: " .. (results[test_id].error or "Unknown error"))
      end
    end
  end
  
  return results
end

return M
```

## Test Procedure

1. **Setup:**
   ```vim
   :luafile predicate_test.lua
   ```

2. **Run the tests:**
   ```vim
   :lua require('predicate_test').run_tests()
   ```

3. **Analyze the results:**
   - Compare the success/failure of each query file
   - Measure the parse time to identify performance issues
   - Look for specific error messages related to stack overflow

## Expected Results

If H15 is true:
- Queries with complex regex patterns will cause stack overflow errors
- The alternative approach with multiple simple predicates will work reliably
- Parse time will increase with regex complexity

If H15 is false:
- All query patterns will work without stack overflow errors
- Performance differences will be minimal
- The complexity of regex patterns won't significantly impact stability

## Additional Analysis

1. **Memory usage:**
   - Monitor memory usage during parsing with different query files
   - Look for memory spikes that might indicate inefficient regex handling

2. **Incremental complexity:**
   - Start with a very simple regex and gradually increase complexity
   - Identify the threshold at which stack overflow errors occur

3. **Predicate correlation:**
   - Determine if specific regex constructs (e.g., nested quantifiers, alternations) are more likely to cause issues
   - Look for patterns in the error messages that could provide insight into the root cause 