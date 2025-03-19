# TreeSitter in Neovim: What You Need to Know

This document compiles essential information about TreeSitter integration in Neovim, with a focus on syntax highlighting and parser integration.

## Parser Integration

### Key Components

1. **Parser File (.so)**: Compiled binary containing the TreeSitter grammar
2. **Query Files (.scm)**: Scheme-like files that define patterns for syntax highlighting
3. **Language Registration**: Connects the parser to the appropriate file type

### Parser Naming and Symbol Exports

TreeSitter parsers export symbols following a specific convention:

```c
tree_sitter_<language>  // The main parser function
```

On macOS, symbols often have an underscore prefix:

```c
_tree_sitter_<language>  // macOS version
```

**Example**: A Tamarin/Spthy parser exports `_tree_sitter_spthy` on macOS.

### External Scanners

Some parsers include external scanners for handling special tokenization:

```c
tree_sitter_<language>_external_scanner_create
tree_sitter_<language>_external_scanner_destroy
tree_sitter_<language>_external_scanner_scan
tree_sitter_<language>_external_scanner_serialize
tree_sitter_<language>_external_scanner_deserialize
```

**Example**: The Tamarin parser's external scanner provides special handling for tokens like variables with apostrophes.

### Language-to-Filetype Mapping

When the language name (exported by the parser) differs from the filetype, explicit mapping is required:

```lua
-- Register 'spthy' language for 'tamarin' filetype
vim.treesitter.language.register('spthy', 'tamarin')
```

## Syntax Highlighting

### Query Files Structure

Neovim uses three main types of query files:

1. **highlights.scm**: Defines syntax highlighting patterns
2. **locals.scm**: Tracks local variables and scopes
3. **injections.scm**: Handles embedded languages

### Highlight Query Format

Highlight queries assign capture names to syntax nodes:

```scheme
;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
] @keyword

;; Identifiers 
(identifier) @variable

;; Functions
(function_call name: (identifier) @function)
```

These capture names (@keyword, @variable, etc.) map to theme colors.

### Predicates

Predicates filter matches with conditions:

```scheme
;; Match constants (uppercase identifiers)
((identifier) @constant
 (#match? @constant "^[A-Z][A-Z_]+$"))

;; Match specific values
((identifier) @variable.builtin
 (#eq? @variable.builtin "self"))
```

Common predicates:
- `#eq?`: Exact text match
- `#match?`: Regex pattern match
- `#any-of?`: Match against list of values
- `#is?`: Check for node properties

### Common Pitfalls

#### 1. Invalid Node Types

Query files must reference valid node types from the parser grammar:

```scheme
;; WRONG: If 'protocol' is not a valid node type
(protocol) @keyword

;; RIGHT: Use as string literal in a list
[
  "protocol"
] @keyword
```

**Error message**: `Query error: Invalid node type "protocol"`

#### 2. Complex Regex Patterns

Neovim's regex engine can overflow with complex patterns:

```scheme
;; PROBLEMATIC: Complex regex with nested quantifiers
((identifier) @variable
 (#match? @variable "^[a-z][a-zA-Z0-9_]*(\'*)$"))

;; BETTER: Simpler pattern
((identifier) @variable
 (#match? @variable "^[a-z]"))
```

**Error message**: `couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!`

#### 3. Buffer-Local Highlighter Storage

TreeSitter highlighters must be properly stored to prevent garbage collection:

```lua
-- PROBLEMATIC: Direct storage may cause type conversion errors
vim.b[bufnr].ts_highlighter = highlighter

-- BETTER: Use a global registry
if not _G._ts_highlighters then _G._ts_highlighters = {} end
_G._ts_highlighters[bufnr] = highlighter
vim.b[bufnr].ts_highlighter_ref = bufnr  -- Only store reference
```

**Error message**: `E5101: Cannot convert given lua type`

## Real-World Examples

### Language Registration

```lua
function setup_parser()
  -- Find parser
  local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  
  -- Register language to filetype mapping
  vim.treesitter.language.register('spthy', 'tamarin')
  
  -- Add parser with explicit path (Neovim 0.9+)
  if vim.treesitter.language.add then
    vim.treesitter.language.add('spthy', { path = parser_path })
  end
  
  return true
end
```

### Highlighter Setup

```lua
function setup_highlighting(bufnr)
  -- Get parser
  local parser = vim.treesitter.get_parser(bufnr, 'spthy')
  
  -- Create highlighter
  local highlighter = vim.treesitter.highlighter.new(parser)
  
  -- Store in global registry to prevent GC
  if not _G._ts_highlighters then _G._ts_highlighters = {} end
  _G._ts_highlighters[bufnr] = highlighter
  
  -- Add cleanup autocommand
  vim.cmd(string.format([[
    augroup TSHighlighter%d
      autocmd!
      autocmd BufDelete <buffer=%d> lua if _G._ts_highlighters then _G._ts_highlighters[%d] = nil end
    augroup END
  ]], bufnr, bufnr, bufnr))
  
  return true
end
```

## Best Practices

1. **Progressive Query Development**: Start with a minimal query file and gradually add complexity
2. **Validate Node Types**: Ensure all node types referenced in queries exist in the parser grammar
3. **Use Simple Predicates**: Prefer multiple simple predicates over complex regex patterns
4. **Prevent Garbage Collection**: Store highlighters in a way that prevents GC while avoiding type conversion errors
5. **Handle Language-Filetype Mapping**: Explicitly register language-to-filetype mapping when they differ
6. **Test Incrementally**: Test each change to the query file before proceeding

## Debugging Tools

### Query Validation

```lua
function validate_query(language, query_type)
  local query_path = vim.fn.stdpath('config') .. '/queries/' .. language .. '/' .. query_type .. '.scm'
  
  -- Read query file
  local file = io.open(query_path, 'r')
  if not file then return "Could not open query file" end
  local content = file:read("*all")
  file:close()
  
  -- Try to parse
  local ok, result = pcall(vim.treesitter.query.parse, language, content)
  
  return {
    success = ok,
    error = not ok and result or nil
  }
end
```

### Node Type Inspection

```lua
function inspect_node_types(bufnr, language)
  -- Get parser
  local parser = vim.treesitter.get_parser(bufnr, language)
  
  -- Parse current buffer
  local tree = parser:parse()[1]
  
  -- Get node types
  local node_types = {}
  local function collect_types(node)
    node_types[node:type()] = true
    for child in node:iter_children() do
      collect_types(child)
    end
  end
  
  collect_types(tree:root())
  
  -- Return sorted list
  local result = {}
  for type, _ in pairs(node_types) do
    table.insert(result, type)
  end
  table.sort(result)
  
  return result
end
```

## References

- [TreeSitter Documentation](https://tree-sitter.github.io/tree-sitter/)
- [Neovim TreeSitter Documentation](https://neovim.io/doc/user/treesitter.html)
- [TreeSitter Query Syntax](https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries) 