# Comprehensive Neovim TreeSitter Debugging Reference

This document provides a systematic approach to debugging TreeSitter integration issues in Neovim, with a special focus on parser loading and symbol name mismatch problems.

## Table of Contents

1. [Understanding the TreeSitter Parser Loading Process](#understanding-the-treesitter-parser-loading-process)
2. [Identifying Common TreeSitter Issues](#identifying-common-treesitter-issues)
3. [Debugging Symbol Name Mismatches](#debugging-symbol-name-mismatches)
4. [Parser File Location Issues](#parser-file-location-issues)
5. [Query File Problems](#query-file-problems)
6. [Runtime Path Configuration](#runtime-path-configuration)
7. [Diagnosing with Logging and Tracing](#diagnosing-with-logging-and-tracing)
8. [Advanced Parser Loading Solutions](#advanced-parser-loading-solutions)
9. [TreeSitter API Troubleshooting](#treesitter-api-troubleshooting)
10. [Compatibility Issues](#compatibility-issues)
11. [Example Debugging Workflows](#example-debugging-workflows)

## Understanding the TreeSitter Parser Loading Process

When Neovim attempts to use TreeSitter for a file, it follows this process:

1. **Filetype Detection**: Neovim determines the filetype of the buffer.
2. **Language Selection**: It maps the filetype to a TreeSitter language.
3. **Parser Search**: It searches for a parser in the runtime path:
   - Looks for `.so` files in `parser/{language}.so`
4. **Symbol Loading**: It tries to dynamically load the symbol `tree_sitter_{language}` from the parser library.
5. **Query Loading**: If parser loading succeeds, it looks for query files (e.g., `highlights.scm`) in the runtime path.
6. **TreeSitter Initialization**: It initializes the TreeSitter highlighter with the parser and queries.

Any failure in these steps will cause TreeSitter to fail silently or with an error.

## Identifying Common TreeSitter Issues

### Using checkhealth

The first step in diagnosing TreeSitter issues should always be running the health check:

```vim
:checkhealth nvim-treesitter
:checkhealth treesitter
```

Look for warnings and errors, particularly:
- Missing parsers
- Parser/query mismatches
- Runtime path issues

### Common Error Messages

| Error Message | Likely Cause | Solution Section |
|---------------|--------------|-----------------|
| `Failed to load parser: dlsym(..., tree_sitter_{language}): symbol not found` | Symbol name mismatch | [Debugging Symbol Name Mismatches](#debugging-symbol-name-mismatches) |
| `query error: invalid node type at position X` | Outdated parser or query | [Query File Problems](#query-file-problems) |
| `module 'vim.treesitter.query' not found` | Outdated Neovim | [Compatibility Issues](#compatibility-issues) |
| `Error detected while processing .../plugin/nvim-treesitter.vim` | Parser/query mismatch | [Parser File Location Issues](#parser-file-location-issues) |

## Debugging Symbol Name Mismatches

Symbol name mismatches are one of the most common TreeSitter integration issues. This happens when Neovim looks for `tree_sitter_{language}` but the parser actually exports a different symbol name.

### Inspecting Symbol Names

To inspect what symbols a parser library exports:

```bash
# On Unix-like systems
nm -gU ~/.config/nvim/parser/mylanguage/mylanguage.so | grep tree_sitter

# On macOS
nm -gU ~/.config/nvim/parser/mylanguage/mylanguage.so | grep tree_sitter

# On Windows with MinGW
nm -g ~/.config/nvim/parser/mylanguage/mylanguage.dll | grep tree_sitter
```

Common symbol variants:
- `_tree_sitter_{language}` (with leading underscore)
- `tree_sitter_{otherlanguage}` (different language name)

### Symbol Name Mismatch Scenarios

#### 1. Leading Underscore Issue

Some compilers (especially on macOS) add a leading underscore to symbol names:

```
00000000000013a0 T _tree_sitter_mylanguage
```

When Neovim looks for `tree_sitter_mylanguage`, it fails.

#### 2. Different Language Name

Sometimes parsers export a different language name than expected:

```
00000000000013a0 T tree_sitter_otherlanguage
```

When Neovim looks for `tree_sitter_mylanguage`, it fails.

### Symbol Name Mismatch Solutions

#### Solution 1: Symbolic Links

Create a symlink to make Neovim find the parser with the right name:

```lua
local function create_symlink(orig_path, target_name)
  local dir = vim.fn.fnamemodify(orig_path, ":h")
  local target_path = dir .. "/" .. target_name .. ".so"
  
  -- Remove existing file/symlink if it exists
  if vim.fn.filereadable(target_path) == 1 then
    os.remove(target_path)
  end
  
  -- Create the symlink
  local cmd = "ln -sf " .. vim.fn.shellescape(orig_path) .. " " .. vim.fn.shellescape(target_path)
  return vim.fn.system(cmd) == ""
end
```

#### Solution 2: Direct Language Registration (Neovim 0.9+)

For newer Neovim versions:

```lua
vim.treesitter.language.register('existinglanguage', 'targetfiletype')
```

#### Solution 3: Recompile with Correct Name

Edit `src/parser.c` to change:
```c
TSLanguage *tree_sitter_{wrongname}() {
```
to:
```c
TSLanguage *tree_sitter_{correctname}() {
```

Then recompile.

## Parser File Location Issues

Neovim searches for parsers in the `parser/` directory within the runtime path. Issues can arise if:

1. The parser is in the wrong location
2. Multiple parsers exist for the same language
3. The parser isn't in the runtime path

### Diagnosing Parser Location Issues

Check where Neovim is looking for parsers:

```lua
:lua print(vim.inspect(vim.api.nvim_get_runtime_file('parser', true)))
```

Find all parsers for a specific language:

```lua
:lua print(vim.inspect(vim.api.nvim_get_runtime_file('parser/mylanguage*', true)))
```

### Fixing Parser Location Issues

1. **Move the parser to the correct location**: 
   ```bash
   mkdir -p ~/.config/nvim/parser/mylanguage/
   cp /path/to/mylanguage.so ~/.config/nvim/parser/mylanguage/mylanguage.so
   ```

2. **Remove duplicate parsers**: If multiple parser files exist, keep only one.

3. **Add the parser location to the runtime path**:
   ```lua
   vim.opt.runtimepath:append("/path/to/custom/parser/dir")
   ```

## Query File Problems

After loading a parser, Neovim looks for query files like `highlights.scm` in `queries/{language}/`.

### Diagnosing Query File Issues

Find all highlight queries for a language:

```lua
:lua print(vim.inspect(vim.api.nvim_get_runtime_file('queries/mylanguage/highlights.scm', true)))
```

Test if a query can be parsed:

```lua
:lua local ok, err = pcall(function() return vim.treesitter.query.parse('mylanguage', '(node) @test') end); print(ok, err)
```

### Common Query Issues

1. **Missing query files**: Create the minimal required files:
   ```lua
   -- In ~/.config/nvim/queries/mylanguage/highlights.scm
   (comment) @comment
   (string) @string
   (identifier) @variable
   ```

2. **Syntax errors in queries**: Start with a minimal query and expand it gradually.

3. **Node type mismatches**: Ensure node types in queries match what the parser produces.

## Runtime Path Configuration

Neovim searches for TreeSitter files in the runtime path. Issues with the runtime path can prevent parser discovery.

### Checking the Runtime Path

```lua
:lua print(vim.inspect(vim.opt.runtimepath:get()))
```

### Fixing Runtime Path Issues

1. **Add custom directories**:
   ```lua
   vim.opt.runtimepath:append("/path/to/custom/treesitter/dir")
   ```

2. **Ensure plugin directories are included**:
   ```lua
   vim.cmd([[packadd nvim-treesitter]])
   ```

3. **Check for path truncation**: If the path is very long, it might be truncated. Use shorter paths.

## Diagnosing with Logging and Tracing

Adding logging is crucial for debugging complex TreeSitter issues.

### Create a Logger

```lua
-- In ~/.config/nvim/lua/treesitter_debug.lua
local M = {}

function M.setup()
  -- Create log directory
  local log_dir = "/tmp/nvim-treesitter-debug"
  vim.fn.mkdir(log_dir, "p")
  
  -- Open log file
  local log_file = log_dir .. "/treesitter.log"
  M.log_handle = io.open(log_file, "a")
  
  if not M.log_handle then
    vim.notify("Failed to open log file: " .. log_file, vim.log.levels.ERROR)
    return false
  end
  
  -- Log startup
  M.log("=== TreeSitter Debug Log Started ===")
  M.log("Neovim version: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)
  
  -- Wrap key functions
  M.wrap_treesitter_functions()
  
  return true
end

function M.log(msg)
  if not M.log_handle then return end
  
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  M.log_handle:write(timestamp .. " " .. msg .. "\n")
  M.log_handle:flush()
end

function M.wrap_treesitter_functions()
  -- Wrap language.add
  local orig_add = vim.treesitter.language.add
  vim.treesitter.language.add = function(lang, opts)
    M.log("Adding language: " .. lang .. " with options: " .. vim.inspect(opts))
    local ok, result = pcall(orig_add, lang, opts)
    if not ok then
      M.log("Failed to add language: " .. lang .. ", error: " .. result)
      return nil, result
    end
    M.log("Successfully added language: " .. lang)
    return result
  end
  
  -- Wrap query.get
  local orig_query_get = vim.treesitter.query.get
  vim.treesitter.query.get = function(lang, query_name)
    M.log("Getting query: " .. query_name .. " for language: " .. lang)
    local ok, result = pcall(orig_query_get, lang, query_name)
    if not ok or not result then
      M.log("Failed to get query: " .. query_name .. " for language: " .. lang)
      return nil
    end
    M.log("Successfully got query: " .. query_name .. " for language: " .. lang)
    return result
  end
end

function M.cleanup()
  if M.log_handle then
    M.log("=== TreeSitter Debug Log Ended ===")
    M.log_handle:close()
    M.log_handle = nil
  end
end

return M
```

### Using the Logger

```lua
-- In your init.lua
local ts_debug = require('treesitter_debug')
ts_debug.setup()

-- At the end of your session
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function() ts_debug.cleanup() end
})
```

## Advanced Parser Loading Solutions

For complex cases, a robust parser loading system is needed.

### Custom Parser Loader Implementation

```lua
-- In ~/.config/nvim/lua/treesitter_loader.lua
local M = {}

-- Debug mode
local DEBUG = true

-- Log helper
local function log(msg)
  if not DEBUG then return end
  
  local log_dir = "/tmp/treesitter-loader"
  vim.fn.mkdir(log_dir, "p")
  
  local log_file = log_dir .. "/loader.log"
  local file = io.open(log_file, "a")
  if file then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    file:write(timestamp .. " " .. msg .. "\n")
    file:close()
  end
end

-- Get all installed parsers
function M.get_installed_parsers()
  local parser_files = vim.api.nvim_get_runtime_file("parser/*/*.so", true)
  local parsers = {}
  
  for _, file in ipairs(parser_files) do
    local name = vim.fn.fnamemodify(file, ":h:t")
    parsers[name] = file
  end
  
  return parsers
end

-- Inspect symbols in a parser
function M.inspect_symbols(parser_path)
  local cmd = string.format("nm -gU %s | grep tree_sitter", vim.fn.shellescape(parser_path))
  local handle = io.popen(cmd)
  local symbols = {}
  
  if handle then
    for line in handle:lines() do
      local symbol = line:match("(%w+_tree_sitter_%w+)")
      if symbol then
        table.insert(symbols, symbol)
      end
    end
    handle:close()
  end
  
  return symbols
end

-- Find the proper parser name based on symbols
function M.get_actual_lang_name(parser_path)
  local symbols = M.inspect_symbols(parser_path)
  
  for _, symbol in ipairs(symbols) do
    -- Check for standard symbol pattern
    local lang = symbol:match("tree_sitter_(%w+)")
    if lang then
      return lang
    end
    
    -- Check for leading underscore pattern
    local lang_with_underscore = symbol:match("_tree_sitter_(%w+)")
    if lang_with_underscore then
      return lang_with_underscore
    end
  end
  
  return nil
end

-- Load a parser with proper handling of symbol name mismatches
function M.load_parser(lang, parser_path)
  log("Attempting to load parser: " .. lang .. " from " .. parser_path)
  
  -- Check if file exists
  if vim.fn.filereadable(parser_path) ~= 1 then
    log("Parser file not found: " .. parser_path)
    return false
  end
  
  -- Try direct loading first
  local success = pcall(function()
    return vim.treesitter.language.add(lang, {path = parser_path})
  end)
  
  if success then
    log("Successfully loaded parser for " .. lang)
    return true
  end
  
  -- If failed, check actual language name
  local actual_lang = M.get_actual_lang_name(parser_path)
  
  if actual_lang and actual_lang ~= lang then
    log("Symbol name mismatch. Actual language: " .. actual_lang)
    
    -- Try loading with actual name
    success = pcall(function()
      return vim.treesitter.language.add(actual_lang, {path = parser_path})
    end)
    
    if success then
      log("Successfully loaded parser as " .. actual_lang)
      
      -- Register language for the original filetype
      if vim.treesitter.language.register then
        log("Registering " .. actual_lang .. " for " .. lang)
        vim.treesitter.language.register(actual_lang, lang)
        return true
      end
    end
  end
  
  log("Failed to load parser for " .. lang)
  return false
end

-- Load all parsers with smart handling
function M.load_all_parsers()
  local parsers = M.get_installed_parsers()
  local results = {}
  
  for lang, path in pairs(parsers) do
    results[lang] = M.load_parser(lang, path)
  end
  
  return results
end

return M
```

### Using the Custom Loader

```lua
-- In your init.lua
local ts_loader = require('treesitter_loader')
ts_loader.load_all_parsers()
```

## TreeSitter API Troubleshooting

### Check if TreeSitter API is Available

```lua
:lua print(vim.treesitter ~= nil, vim.treesitter.language ~= nil, vim.treesitter.query ~= nil)
```

### Check Language Registry

```lua
:lua print(vim.inspect(vim.treesitter.language.available()))
```

### Check Filetype Mappings

```lua
:lua print(vim.inspect(vim.treesitter.language.get_filetypes()))
```

### Verify Parser for Current Buffer

```lua
:lua local parser = vim.treesitter.get_parser(0); print(parser and parser:lang() or "No parser")
```

## Compatibility Issues

TreeSitter integration in Neovim has evolved significantly. Compatibility issues can arise between:

1. Neovim versions
2. TreeSitter library versions
3. Language parser versions
4. Query file formats

### Neovim Version Compatibility

| Feature | Minimum Neovim Version |
|---------|------------------------|
| Basic TreeSitter support | 0.5.0 |
| `vim.treesitter.language.register()` | 0.9.0 |
| Improved error messages | 0.8.0 |
| WASM parser support | 0.10.0 |

### Fixing Compatibility Issues

1. **Update Neovim** to the latest stable version or nightly.

2. **Update parsers** with nvim-treesitter:
   ```vim
   :TSUpdate
   ```

3. **Check parser versions** with:
   ```lua
   :lua print(vim.treesitter.get_parser(0):parse()[1]._source)
   ```

## Example Debugging Workflows

### Workflow 1: Basic Parser Loading Issue

```
Problem: TreeSitter highlighting doesn't work for a language.
```

1. Check if parser exists:
   ```lua
   :lua print(vim.inspect(vim.api.nvim_get_runtime_file('parser/mylanguage*', true)))
   ```

2. Check for symbol name mismatches:
   ```bash
   nm -gU ~/.config/nvim/parser/mylanguage/mylanguage.so | grep tree_sitter
   ```

3. Try loading the parser manually:
   ```lua
   :lua print(pcall(function() return vim.treesitter.language.add('mylanguage', {path = '/path/to/mylanguage.so'}) end))
   ```

4. Create symlinks if needed:
   ```lua
   :lua vim.fn.system("ln -sf ~/.config/nvim/parser/mylanguage/mylanguage.so ~/.config/nvim/parser/mylanguage/othername.so")
   ```

5. Register the language for the filetype:
   ```lua
   :lua vim.treesitter.language.register('othername', 'mylanguage')
   ```

### Workflow 2: Query File Issues

```
Problem: Syntax highlighting is missing or incorrect.
```

1. Check if query files exist:
   ```lua
   :lua print(vim.inspect(vim.api.nvim_get_runtime_file('queries/mylanguage/highlights.scm', true)))
   ```

2. Verify query can be parsed:
   ```lua
   :lua local ok, err = pcall(function() return vim.treesitter.query.get('mylanguage', 'highlights') end); print(ok, err)
   ```

3. Create a minimal highlights query:
   ```lua
   :lua local file = io.open('/tmp/highlights.scm', 'w'); file:write('(comment) @comment\n(string) @string'); file:close()
   :lua vim.fn.system('mkdir -p ~/.config/nvim/queries/mylanguage && cp /tmp/highlights.scm ~/.config/nvim/queries/mylanguage/highlights.scm')
   ```

4. Test with the minimal query:
   ```vim
   :edit /tmp/test.mylanguage
   ```

### Workflow 3: Advanced Parser Debug with Logging

```
Problem: Complex parser loading issue with multiple potential causes.
```

1. Setup logging:
   ```lua
   local log_file = "/tmp/treesitter_debug.log"
   local log = io.open(log_file, "w")
   function debug_log(msg) log:write(msg.."\n"); log:flush() end
   ```

2. Trace parser loading:
   ```lua
   debug_log("Runtime paths: " .. vim.inspect(vim.opt.runtimepath:get()))
   debug_log("Parser files: " .. vim.inspect(vim.api.nvim_get_runtime_file('parser/*/*.so', true)))
   ```

3. Inspect symbols:
   ```lua
   local function get_symbols(path)
     local handle = io.popen(string.format("nm -gU %s | grep tree_sitter", vim.fn.shellescape(path)))
     local result = handle:read("*a")
     handle:close()
     return result
   end
   
   for _, parser in ipairs(vim.api.nvim_get_runtime_file('parser/*/*.so', true)) do
     debug_log("Parser: " .. parser)
     debug_log("Symbols: " .. get_symbols(parser))
   end
   ```

4. Test parser loading:
   ```lua
   for lang, _ in pairs(vim.treesitter.language.get_filetypes()) do
     local ok, err = pcall(function() 
       return vim.treesitter.language.add(lang, {
         path = vim.api.nvim_get_runtime_file('parser/'..lang..'/*.so', false)[1]
       })
     end)
     debug_log("Loading " .. lang .. ": " .. tostring(ok) .. " - " .. tostring(err or ""))
   end
   ```

5. Analyze the log and apply fixes based on findings.

## Conclusion

Debugging TreeSitter integration issues requires a systematic approach and understanding of how Neovim loads and uses parsers. By following the workflows and using the tools provided in this reference, you can identify and fix most TreeSitter issues, particularly those related to parser loading and symbol name mismatches.

When all else fails, remember these key strategies:
1. Start with minimal configurations
2. Add extensive logging
3. Test hypotheses systematically
4. Isolate components (parser, query, runtime path)
5. Use workarounds (symlinks, direct registration) when needed 