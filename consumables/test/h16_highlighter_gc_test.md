# Test: TreeSitter Highlighter Garbage Collection (H16)

## Hypothesis
Buffer-specific highlighter garbage collection issues might be causing the syntax highlighting to fail.

## Background
TreeSitter documentation indicates that highlighter objects need to be stored in buffer-local variables to prevent garbage collection. If the highlighter is garbage collected prematurely, syntax highlighting might stop working. This test aims to determine if garbage collection issues are contributing to the Tamarin syntax highlighting problems.

## Test Plan

1. **Implement highlighter with and without GC prevention**
   - Create a module that sets up highlighters without storing them in buffer-local variables
   - Create a module that properly stores highlighters in buffer-local variables
   - Compare the behavior of both implementations

2. **Observe highlighter persistence**
   - Monitor highlighter objects during buffer navigation and editing
   - Trigger manual garbage collection to see if highlighting fails
   - Check if buffer reloading affects highlighting

3. **Track highlighter creation and deletion**
   - Add logging to track when highlighters are created and destroyed
   - Identify patterns that might cause premature garbage collection
   - Correlate garbage collection with syntax highlighting failures

## Implementation Comparison

### Without GC Prevention:
```lua
function setup_highlighting(bufnr)
  bufnr = bufnr or 0
  
  -- Check if TreeSitter is available
  if not vim.treesitter or not vim.treesitter.highlighter then
    return false
  end
  
  -- Get parser
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_ok or not parser then
    return false
  end
  
  -- Create highlighter without storing it
  local highlighter_ok, _ = pcall(vim.treesitter.highlighter.new, parser)
  if not highlighter_ok then
    return false
  end
  
  return true
end
```

### With GC Prevention:
```lua
function setup_highlighting(bufnr)
  bufnr = bufnr or 0
  
  -- Check if TreeSitter is available
  if not vim.treesitter or not vim.treesitter.highlighter then
    return false
  end
  
  -- Get parser
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_ok or not parser then
    return false
  end
  
  -- Create highlighter and store it in a buffer-local variable
  local highlighter_ok, highlighter = pcall(vim.treesitter.highlighter.new, parser)
  if not highlighter_ok or not highlighter then
    return false
  end
  
  -- Store in buffer-local variable to prevent garbage collection
  vim.b[bufnr].tamarin_ts_highlighter = highlighter
  
  return true
end
```

## Test Script

```lua
-- File: gc_test.lua
local gc_issues = {}

-- Setup logging
local log_file = io.open(vim.fn.stdpath('data') .. '/gc_test.log', 'w')
local function log(message)
  log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. ": " .. message .. "\n")
  log_file:flush()
end

-- Set up highlighting without GC prevention
function gc_issues.test_without_gc_prevention()
  log("Setting up highlighter without GC prevention")
  
  local setup_result = gc_issues.setup_highlighting_without_gc(0)
  log("Setup result: " .. tostring(setup_result))
  
  -- Force garbage collection
  log("Forcing garbage collection")
  collectgarbage("collect")
  
  -- Check if highlighting still works
  log("Checking if highlighting still works")
  local highlight_active = vim.treesitter.highlighter and 
                          vim.treesitter.highlighter.active and 
                          vim.treesitter.highlighter.active[0] ~= nil
  log("Highlighting active: " .. tostring(highlight_active))
  
  return highlight_active
end

-- Set up highlighting with GC prevention
function gc_issues.test_with_gc_prevention()
  log("Setting up highlighter with GC prevention")
  
  local setup_result = gc_issues.setup_highlighting_with_gc(0)
  log("Setup result: " .. tostring(setup_result))
  
  -- Force garbage collection
  log("Forcing garbage collection")
  collectgarbage("collect")
  
  -- Check if highlighting still works
  log("Checking if highlighting still works")
  local highlight_active = vim.treesitter.highlighter and 
                          vim.treesitter.highlighter.active and 
                          vim.treesitter.highlighter.active[0] ~= nil
  log("Highlighting active: " .. tostring(highlight_active))
  local buffer_has_highlighter = vim.b[0].tamarin_ts_highlighter ~= nil
  log("Buffer has highlighter: " .. tostring(buffer_has_highlighter))
  
  return highlight_active and buffer_has_highlighter
end

-- Implementation details
function gc_issues.setup_highlighting_without_gc(bufnr)
  -- Implementation without GC prevention (as shown above)
end

function gc_issues.setup_highlighting_with_gc(bufnr)
  -- Implementation with GC prevention (as shown above)
end

-- Run both tests
function gc_issues.run_tests()
  log("Starting GC tests")
  
  local without_gc_result = gc_issues.test_without_gc_prevention()
  log("Test without GC prevention result: " .. tostring(without_gc_result))
  
  local with_gc_result = gc_issues.test_with_gc_prevention()
  log("Test with GC prevention result: " .. tostring(with_gc_result))
  
  log("Tests completed")
  log_file:close()
  
  return {
    without_gc = without_gc_result,
    with_gc = with_gc_result
  }
end

return gc_issues
```

## Test Procedure

1. **Setup:**
   ```bash
   # Create a test Tamarin file
   cat > test.spthy << 'EOF'
   theory Test
   begin
   
   rule With_Variable:
       let x = 'test'
       let y' = 'test with apostrophe'
       in
       [ ]
   
   end
   EOF
   ```

2. **Run the tests:**
   ```vim
   :luafile gc_test.lua
   :lua require('gc_test').run_tests()
   ```

3. **Analyze the results:**
   - Check the log file at `~/.local/share/nvim/gc_test.log`
   - Compare highlighting behavior with and without GC prevention
   - Verify if garbage collection affects highlighting

## Expected Results

If H16 is true:
- Highlighting will fail after garbage collection without proper buffer-local storage
- Highlighting will persist with proper buffer-local storage
- This will explain why highlighting sometimes works initially but fails later

If H16 is false:
- Garbage collection won't affect highlighting regardless of storage method
- Other issues might be responsible for the highlighting failures

## Additional Tests

1. **Buffer switching test:**
   - Set up highlighting in one buffer
   - Switch to another buffer and back
   - Check if highlighting is still active

2. **Long-term stability test:**
   - Set up highlighting with and without GC prevention
   - Perform editing operations for an extended period
   - Check if highlighting persists throughout the session 