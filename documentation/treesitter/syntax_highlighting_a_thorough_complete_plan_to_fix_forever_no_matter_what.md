# Comprehensive Plan to Fix TreeSitter Syntax Highlighting

## Phase 1: Environment Analysis and Setup

### 1.1 Parser Location Audit
1. **Find All Parser Locations**
   ```lua
   local parser_files = vim.api.nvim_get_runtime_file("parser/*/*.so", true)
   ```
2. **Verify Parser Symbols**
   ```bash
   nm -gU parser/spthy/spthy.so | grep tree_sitter
   ```
3. **Clean Up Multiple Parsers**
   - Keep only one parser in a standardized location
   - Create necessary symlinks for compatibility

### 1.2 Query File Verification
1. **Locate Query Files**
   ```lua
   local query_files = vim.api.nvim_get_runtime_file("queries/*/*.scm", true)
   ```
2. **Validate Query Syntax**
   - Use `vim.treesitter.query.lint()`
   - Fix any syntax errors
   - Ensure node types match parser output

### 1.3 Directory Structure Setup
```
~/.config/nvim/
├── parser/
│   └── spthy/
│       └── spthy.so
├── queries/
│   └── spthy/
│       └── highlights.scm
└── lua/
    └── tamarin/
        ├── init.lua
        └── treesitter.lua
```

## Phase 2: Core Implementation

### 2.1 Enhanced Parser Loader
```lua
-- lua/tamarin/parser.lua
local M = {}

function M.ensure_parser_loaded()
  -- Find parser binary
  local parser_path = vim.fn.stdpath('config') .. "/parser/spthy/spthy.so"
  
  -- Verify parser exists
  if vim.fn.filereadable(parser_path) ~= 1 then
    return false, "Parser not found"
  end
  
  -- Register language
  if vim.treesitter.language and vim.treesitter.language.register then
    local ok = pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
    if not ok then
      return false, "Language registration failed"
    end
  end
  
  -- Add parser explicitly
  if vim.treesitter.language and vim.treesitter.language.add then
    local ok = pcall(vim.treesitter.language.add, 'spthy', {
      path = parser_path
    })
    if not ok then
      return false, "Parser addition failed"
    end
  end
  
  return true
end

return M
```

### 2.2 Highlighter Manager
```lua
-- lua/tamarin/highlighter.lua
local M = {}

function M.setup_buffer_highlighting(bufnr)
  bufnr = bufnr or 0
  
  -- Skip non-Tamarin buffers
  if vim.bo[bufnr].filetype ~= "tamarin" then
    return false
  end
  
  -- Get parser
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not ok or not parser then
    return false
  end
  
  -- Create highlighter
  if vim.treesitter.highlighter then
    local ok, highlighter = pcall(vim.treesitter.highlighter.new, parser)
    if ok and highlighter then
      -- Store in buffer-local variable
      vim.b[bufnr].tamarin_ts_highlighter = highlighter
      return true
    end
  end
  
  return false
end

return M
```

### 2.3 Progressive Query File
```scheme
;; queries/spthy/highlights.scm
;; Start with basic captures, no complex regex
(theory) @keyword
(lemma) @keyword
(rule) @keyword
(fact) @function
(variable) @variable

;; Add more complex patterns progressively after testing
```

## Phase 3: Integration and Testing

### 3.1 Main Module Integration
```lua
-- lua/tamarin/init.lua
local M = {}

function M.setup()
  -- Load parser
  local parser = require('tamarin.parser')
  local ok, err = parser.ensure_parser_loaded()
  if not ok then
    vim.notify("Tamarin parser loading failed: " .. err, vim.log.levels.WARN)
    return false
  end
  
  -- Set up autocommands
  vim.cmd([[
    augroup TamarinTreeSitter
      autocmd!
      autocmd FileType tamarin lua require('tamarin.highlighter').setup_buffer_highlighting(0)
    augroup END
  ]])
  
  return true
end

return M
```

### 3.2 Test Suite
```lua
-- test/test_tamarin_treesitter.lua
local function test_setup()
  -- Test parser loading
  local ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
  assert(ok and parser, "Parser loading failed")
  
  -- Test query loading
  local ok, query = pcall(vim.treesitter.query.get, 'spthy', 'highlights')
  assert(ok and query, "Query loading failed")
  
  -- Test highlighting
  local highlighter = vim.treesitter.highlighter.active[0]
  assert(highlighter, "Highlighter not active")
end
```

## Phase 4: Validation and Debugging

### 4.1 Diagnostic Tools
```lua
-- lua/tamarin/debug.lua
local M = {}

function M.diagnose_setup()
  local results = {
    parser_files = vim.api.nvim_get_runtime_file("parser/*/*.so", true),
    query_files = vim.api.nvim_get_runtime_file("queries/*/*.scm", true),
    treesitter_active = vim.treesitter ~= nil,
    highlighter_active = vim.treesitter.highlighter.active[0] ~= nil
  }
  
  return results
end

return M
```

### 4.2 Fallback Mechanism
```lua
-- lua/tamarin/fallback.lua
local M = {}

function M.ensure_highlighting(bufnr)
  -- Try TreeSitter first
  local ts_ok = require('tamarin.highlighter').setup_buffer_highlighting(bufnr)
  
  -- Fall back to regular syntax if TreeSitter fails
  if not ts_ok then
    vim.cmd('syntax enable')
    return false
  end
  
  return true
end

return M
```

## Phase 5: Documentation and Maintenance

### 5.1 User Documentation
- Installation instructions
- Configuration options
- Troubleshooting guide
- Known limitations

### 5.2 Developer Documentation
- Architecture overview
- Module dependencies
- Testing procedures
- Debugging tools

## Implementation Steps

1. **Clean Environment**
   - Remove old parser files
   - Clean up query files
   - Remove old configuration

2. **Install Components**
   - Place parser in correct location
   - Set up query files
   - Install Lua modules

3. **Configure Integration**
   - Add to init.lua
   - Set up autocommands
   - Configure fallback

4. **Test and Verify**
   - Run test suite
   - Check highlighting
   - Verify fallback
   - Test edge cases

5. **Monitor and Maintain**
   - Watch for issues
   - Update documentation
   - Handle bug reports

## Success Criteria

1. **Parser Loading**
   - Parser is found and loaded
   - Symbols are correctly mapped
   - Language is registered

2. **Syntax Highlighting**
   - TreeSitter highlighting works
   - All node types are highlighted
   - No regex stack errors

3. **Robustness**
   - Works in subdirectories
   - Handles errors gracefully
   - Falls back cleanly

4. **Performance**
   - Fast loading
   - Smooth scrolling
   - No lag on large files

## Fallback Strategy

1. **Detection**
   - Check TreeSitter availability
   - Verify parser loading
   - Monitor highlighting status

2. **Recovery**
   - Fall back to regular syntax
   - Log failure reason
   - Notify user appropriately

3. **Prevention**
   - Regular validation
   - Proactive monitoring
   - Update mechanisms

## Maintenance Plan

1. **Regular Checks**
   - Parser compatibility
   - Query file syntax
   - API compatibility

2. **Updates**
   - Parser updates
   - Query improvements
   - API adaptations

3. **Documentation**
   - Keep docs current
   - Update troubleshooting
   - Record changes 