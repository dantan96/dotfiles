# Manually Adding a TreeSitter Parser to Neovim: A Comprehensive Guide

## Introduction

TreeSitter is a parsing library that builds concrete syntax trees for source files. Neovim (version 0.5+) integrates TreeSitter for improved syntax highlighting, code navigation, and other language-aware features. While many parsers can be easily installed through plugins like `nvim-treesitter`, some scenarios require manual installation, especially for:

- Custom languages
- Modified parsers
- Languages not supported by nvim-treesitter
- Debugging parser issues

This guide focuses particularly on handling symbol name mismatches, which is a common issue when integrating custom parsers.

## Prerequisites

- Neovim 0.5+ (0.10+ recommended)
- Basic understanding of Lua
- A C compiler (like gcc, clang)
- tree-sitter-cli (`npm install -g tree-sitter-cli`)

## Understanding TreeSitter Parser Basics

### Parser Components

A TreeSitter parser consists of:

1. Grammar definition (`grammar.js`)
2. Compiled shared library (`.so` on Unix, `.dll` on Windows)
3. Query files (e.g., `highlights.scm`) for features like syntax highlighting

### How Neovim Loads Parsers

Neovim searches for parser libraries in the `parser/` directory within the runtime path. It attempts to load a symbol named `tree_sitter_{language}` from a file named `parser/{language}.so`.

## The Symbol Name Mismatch Problem

### Identifying the Problem

A common issue occurs when the compiled parser exports a symbol named differently from what Neovim expects. For example:

- Neovim expects: `tree_sitter_mylanguage`
- Parser exports: `_tree_sitter_mylanguage` or `tree_sitter_othername`

This causes an error like:
```
Failed to load parser: dlsym(..., tree_sitter_mylanguage): symbol not found
```

### Diagnosing Symbol Name Issues

To check the symbols exported by your parser:

```bash
# On Unix-like systems
nm -gU parser/mylanguage/mylanguage.so | grep tree_sitter
```

This will show the actual symbol names, which might include an unexpected prefix like `_` or a completely different language name.

## Solutions for Symbol Name Mismatches

### 1. Symbolic Links (Quick Solution)

Create a symbolic link with a name that matches what Neovim expects:

```lua
local function create_parser_symlink(orig_parser_path, expected_name)
  local parser_dir = vim.fn.fnamemodify(orig_parser_path, ":h")
  local expected_path = parser_dir .. "/" .. expected_name .. ".so"
  
  -- Remove existing symlink if it exists
  if vim.fn.filereadable(expected_path) == 1 then
    os.remove(expected_path)
  end
  
  -- Create the symlink
  vim.fn.system("ln -sf " .. vim.fn.shellescape(orig_parser_path) .. " " .. vim.fn.shellescape(expected_path))
end

-- Example usage:
create_parser_symlink("~/.config/nvim/parser/mylanguage/mylanguage.so", "other_name")
```

### 2. Direct Language Registration (Neovim 0.9+)

For newer Neovim versions, you can directly register a language for a filetype:

```lua
vim.treesitter.language.register('existinglang', 'myfiletype')
```

This tells Neovim to use the parser for 'existinglang' when editing files with 'myfiletype'.

### 3. Recompile the Parser with Correct Symbol Name

Edit the parser source to rename the exported symbol:

1. Modify the `main` function in the parser's `src/parser.c` file:
   ```c
   // Change from
   TSLanguage *tree_sitter_mylanguage() {
   // To
   TSLanguage *tree_sitter_expected_name() {
   ```

2. Recompile the parser:
   ```bash
   tree-sitter generate
   gcc -o parser.so -shared src/parser.c -Os -fPIC
   ```

### 4. Write a Custom Parser Loader

Create a robust loader that handles symbol discrepancies:

```lua
local function add_language(lang, parser_path)
  -- Check if the path exists
  if vim.fn.filereadable(parser_path) ~= 1 then
    return false
  end
  
  -- Special handling for specific language
  if lang == "mylanguage" then
    -- Check for symbol name
    local cmd = string.format("nm -gU %s | grep tree_sitter", vim.fn.shellescape(parser_path))
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    
    if result:match("_tree_sitter_othername") then
      -- Use the other name instead
      return vim.treesitter.language.add("othername", {path = parser_path})
    end
  end
  
  -- Normal processing
  return vim.treesitter.language.add(lang, {path = parser_path})
end
```

## Comprehensive Implementation

For a complete solution, combine these approaches into a robust parser loader:

```lua
local M = {}

-- Debug flag
local DEBUG = true

-- Log helper
local function log(msg)
  if DEBUG then
    vim.notify("[parser-loader] " .. msg, vim.log.levels.INFO)
  end
end

-- Create symlink to handle name mismatches
local function create_parser_symlink(orig_path, expected_name)
  local dir = vim.fn.fnamemodify(orig_path, ":h")
  local expected_path = dir .. "/" .. expected_name .. ".so"
  
  log("Creating symlink from " .. orig_path .. " to " .. expected_path)
  
  if vim.fn.filereadable(expected_path) == 1 then
    os.remove(expected_path)
    log("Removed existing file: " .. expected_path)
  end
  
  local success = vim.fn.system("ln -sf " .. vim.fn.shellescape(orig_path) .. " " .. vim.fn.shellescape(expected_path))
  return success == ""
end

-- Register language directly (Neovim 0.9+)
local function register_language_directly(source_lang, target_filetype)
  log("Attempting direct language registration: " .. source_lang .. " for " .. target_filetype)
  
  if vim.treesitter.language.register then
    local ok = pcall(function()
      vim.treesitter.language.register(source_lang, target_filetype)
      return true
    end)
    
    if ok then
      log("Successfully registered " .. source_lang .. " for " .. target_filetype)
      return true
    end
  end
  
  return false
end

-- Add language with symbol name workarounds
local function add_language(lang, parser_path)
  log("Adding language: " .. lang .. " with parser: " .. parser_path)
  
  -- Check symbols in the parser
  local cmd = string.format("nm -gU %s | grep tree_sitter", vim.fn.shellescape(parser_path))
  local handle = io.popen(cmd)
  local symbols = ""
  if handle then
    symbols = handle:read("*a")
    handle:close()
    log("Found symbols: " .. symbols)
  end
  
  -- Special handling based on symbol name patterns
  if lang == "mylanguage" and symbols:match("_tree_sitter_othername") then
    log("Symbol mismatch detected, trying alternative strategy")
    
    -- Try direct registration first
    if register_language_directly("othername", lang) then
      return true
    end
    
    -- Create symlink as fallback
    create_parser_symlink(parser_path, "othername")
    
    -- Try adding the language
    local ok = pcall(function() 
      return vim.treesitter.language.add("othername", {path = parser_path})
    end)
    
    if ok then
      log("Successfully added language with symbol workaround")
      return register_language_directly("othername", lang)
    end
  end
  
  -- Normal path
  local ok = pcall(function()
    return vim.treesitter.language.add(lang, {path = parser_path})
  end)
  
  return ok
end

-- Ensure parser is loaded
function M.ensure_parser_loaded(lang, parser_path)
  log("Ensuring parser is loaded for: " .. lang)
  
  if vim.fn.filereadable(parser_path) ~= 1 then
    log("Parser file not found: " .. parser_path)
    return false
  end
  
  -- Try to add the language
  local success = add_language(lang, parser_path)
  
  if success then
    log("Successfully loaded parser for: " .. lang)
  else
    log("Failed to load parser for: " .. lang)
  end
  
  return success
end

return M
```

## Creating Query Files

After loading the parser, you'll need query files for syntax highlighting:

1. Create a `queries/{language}/` directory in your Neovim configuration
2. Add a `highlights.scm` file with TreeSitter queries for syntax highlighting
3. Start simple and add complexity gradually to isolate issues:

```scheme
;; Ultra-minimal highlights.scm
(comment) @comment
(function_definition name: (identifier) @function)
(variable) @variable
```

## Debugging Tips

1. Verify parser loading with:
   ```lua
   :lua print(vim.inspect(vim.api.nvim_get_runtime_file('parser', true)))
   ```

2. Check if a language is available:
   ```lua
   :lua print(vim.inspect(vim.treesitter.language.available()))
   ```

3. Inspect filetype-to-language mappings:
   ```lua
   :lua print(vim.inspect(vim.treesitter.language.get_filetypes()))
   ```

4. Test query parsing:
   ```lua
   :lua print(pcall(function() return vim.treesitter.query.parse("mylanguage", "(node) @test") end))
   ```

## Common Pitfalls

1. **Multiple Parser Directories**: Having parsers in multiple locations can cause conflicts. Use `:echo nvim_get_runtime_file('parser', v:true)` to check.

2. **Outdated Neovim**: Some TreeSitter features require recent Neovim versions.

3. **Missing Dependencies**: Parsers might depend on other parsers (e.g., CSS within HTML).

4. **Query Syntax Errors**: Validate your `.scm` files incrementally.

5. **Symbol Name Mismatches**: As detailed throughout this guide, this requires special handling.

## Conclusion

Manually adding TreeSitter parsers to Neovim can be challenging, especially when dealing with symbol name mismatches. By understanding the loading process and implementing robust workarounds, you can successfully integrate custom parsers and take advantage of TreeSitter's powerful features.

Remember to start simple and incrementally build complexity to isolate and fix issues as they arise. The approaches outlined in this guide should handle the vast majority of parser integration challenges. 