# Useful Neovim API Calls for TreeSitter Integration

This document contains a collection of useful Neovim API calls specifically for working with TreeSitter, along with examples of how to use them. These can be helpful for debugging, customizing, and extending TreeSitter functionality in Neovim.

## TreeSitter Language Management

### Check Available Languages

```lua
-- List all available TreeSitter languages
:lua print(vim.inspect(vim.treesitter.language.available()))

-- Example output:
-- { "bash", "c", "lua", "python", ... }
```

### Register a Language for a Filetype

```lua
-- Use the 'bash' parser for 'zsh' files
vim.treesitter.language.register('bash', 'zsh')

-- Register one parser for multiple filetypes
vim.treesitter.language.register('javascript', { 'javascript', 'javascriptreact', 'js' })
```

### Get Filetypes for a Language

```lua
-- Get all filetypes associated with a language
:lua print(vim.inspect(vim.treesitter.language.get_filetypes('python')))

-- Example output:
-- { "python" }
```

### Add a Parser Manually

```lua
-- Add a parser from a specific file path
local success = vim.treesitter.language.add('mylanguage', { path = '/path/to/parser.so' })
print(success)  -- true if successful, false if failed
```

## TreeSitter Parser Management

### Get Parser for Current Buffer

```lua
-- Get parser for current buffer
local parser = vim.treesitter.get_parser(0)
print(parser)  -- userdata: 0x...

-- Get parser for current buffer with a specific language
local parser = vim.treesitter.get_parser(0, 'lua')
```

### Get the Parsed Tree

```lua
-- Get the current syntax tree
local parser = vim.treesitter.get_parser(0)
local tree = parser:parse()[1]
local root = tree:root()
print(root:type())  -- e.g., "chunk" for lua files
```

### Navigate the Syntax Tree

```lua
-- Get children of the root node
local parser = vim.treesitter.get_parser(0)
local tree = parser:parse()[1]
local root = tree:root()

for child, _ in root:iter_children() do
  print(child:type())
end
```

## TreeSitter Query Operations

### Parse a Query

```lua
-- Parse a simple query
local query = vim.treesitter.query.parse('lua', '(function_call name: (identifier) @function)')

-- Parse a query from a string
local query_string = [[
  (function_declaration
    name: (identifier) @function.declaration)
]]
local query = vim.treesitter.query.parse('lua', query_string)
```

### Execute a Query

```lua
-- Execute a query on the syntax tree
local parser = vim.treesitter.get_parser(0)
local tree = parser:parse()[1]
local root = tree:root()

local query = vim.treesitter.query.parse('lua', '(function_call name: (identifier) @function)')
for id, node, metadata in query:iter_captures(root, 0) do
  local name = query.captures[id]  -- e.g., "function"
  local text = vim.treesitter.get_node_text(node, 0)
  print(name, text)
end
```

### Get Predefined Queries

```lua
-- Get the highlighting query for a language
local query = vim.treesitter.query.get('lua', 'highlights')

-- Get the indentation query for a language
local query = vim.treesitter.query.get('lua', 'indents')

-- Check if a query exists
if vim.treesitter.query.get('mylanguage', 'highlights') then
  print("Highlighting is available for mylanguage")
end
```

## TreeSitter Highlighting

### Start Highlighting for a Buffer

```lua
-- Start highlighting for the current buffer
vim.treesitter.start(0, 'lua')

-- Start highlighting with options
vim.treesitter.start(0, 'lua', {
  disable = false,
  silent = false
})
```

### Check Highlighting Status

```lua
-- Check if treesitter highlighting is active for a buffer
:lua print(vim.treesitter.highlighter.active[0] ~= nil)
```

## TreeSitter Runtime Files

### Find Parser Files

```lua
-- Find all parser files in the runtime path
local parser_files = vim.api.nvim_get_runtime_file('parser/*', true)
for _, file in ipairs(parser_files) do
  print(file)
end

-- Find a specific parser
local my_parser = vim.api.nvim_get_runtime_file('parser/mylanguage.so', false)
print(my_parser)
```

### Find Query Files

```lua
-- Find all highlight queries for a language
local highlight_queries = vim.api.nvim_get_runtime_file('queries/mylanguage/highlights.scm', true)
for _, file in ipairs(highlight_queries) do
  print(file)
end
```

## TreeSitter Diagnostics and Debugging

### Check TreeSitter Health

```lua
-- Run the TreeSitter healthcheck
:checkhealth nvim-treesitter
```

### Debug Parser Loading

```lua
-- Attempt to load a parser and inspect the result
local ok, result = pcall(function()
  return vim.treesitter.language.add('mylanguage', {path = '/path/to/parser.so'})
end)

if not ok then
  print("Error loading parser: " .. result)
else
  print("Parser loaded successfully")
end
```

### Inspect Parser Symbol

```lua
-- Check what symbols are exported by a parser library
function inspect_parser_symbols(parser_path)
  local cmd = string.format("nm -gU %s | grep tree_sitter", vim.fn.shellescape(parser_path))
  local handle = io.popen(cmd)
  
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result
  end
  return ""
end

print(inspect_parser_symbols("/path/to/parser.so"))

-- Example output:
-- 0000000000012340 T _tree_sitter_mylanguage
-- 0000000000012350 T _tree_sitter_mylanguage_external_scanner_create
-- ...
```

## Working with Nodes

### Get Text from a Node

```lua
-- Get text from a node
local parser = vim.treesitter.get_parser(0)
local tree = parser:parse()[1]
local root = tree:root()

-- Get the first child node's text
local child = root:child(0)
if child then
  local text = vim.treesitter.get_node_text(child, 0)
  print(text)
end
```

### Get Node Range

```lua
-- Get the range of a node (start_row, start_col, end_row, end_col)
local parser = vim.treesitter.get_parser(0)
local tree = parser:parse()[1]
local root = tree:root()

local start_row, start_col, end_row, end_col = root:range()
print(string.format("Node spans from %d:%d to %d:%d", start_row, start_col, end_row, end_col))
```

### Find Nodes at Cursor

```lua
-- Get the node at cursor position
function get_node_at_cursor()
  local bufnr = 0
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()
  
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  
  local node = root:named_descendant_for_range(row, col, row, col)
  return node
end

local node = get_node_at_cursor()
print("Node type: " .. node:type())
print("Node text: " .. vim.treesitter.get_node_text(node, 0))
```

## TreeSitter Query Predicates

### Using Predicates in Queries

```lua
-- Query with predicates
local query_string = [[
  ((identifier) @variable
   (#match? @variable "^[A-Z]"))  ; Matches identifiers starting with uppercase

  ((string) @string.special
   (#eq? @string.special "\"special\""))  ; Matches the exact string "special"
]]

local query = vim.treesitter.query.parse('lua', query_string)
```

### Writing Custom Predicates

```lua
-- Register a custom predicate
vim.treesitter.query.add_predicate("custom-predicate?", function(match, pattern, bufnr, predicate)
  local node = match[predicate[2]]
  if not node then return false end
  
  local text = vim.treesitter.get_node_text(node, bufnr)
  -- Custom logic here
  return text:find("pattern") ~= nil
end)

-- Now you can use it in queries:
-- ((identifier) @id (#custom-predicate? @id))
```

## Creating Custom TreeSitter Modules

### Custom Highlighting Module

```lua
local M = {}

function M.custom_highlight(bufnr)
  bufnr = bufnr or 0
  
  -- Get the parser
  local parser = vim.treesitter.get_parser(bufnr)
  local tree = parser:parse()[1]
  local root = tree:root()
  
  -- Parse your custom query
  local query = vim.treesitter.query.parse('lua', '(function_call name: (identifier) @function.custom)')
  
  -- Apply highlights
  for id, node in query:iter_captures(root, bufnr) do
    local name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()
    
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,  -- use a new namespace ID
      "CustomHighlight",  -- highlight group
      start_row,
      start_col,
      end_col
    )
  end
end

return M
```

## TreeSitter Playground Integration

If you have the TreeSitter Playground plugin installed, these commands are helpful:

```lua
-- Inspect the node under cursor
:TSNodeUnderCursor

-- Open the TreeSitter playground
:TSPlaygroundToggle

-- Show the current node highlight group
:TSHighlightCapturesUnderCursor
```

## Useful Utility Functions

### Create Parser Symlink Helper

```lua
-- Create a symlink to handle parser name discrepancies
function create_parser_symlink(orig_path, expected_name)
  local dir = vim.fn.fnamemodify(orig_path, ":h")
  local expected_path = dir .. "/" .. expected_name .. ".so"
  
  print("Creating symlink from " .. orig_path .. " to " .. expected_path)
  
  if vim.fn.filereadable(expected_path) == 1 then
    os.remove(expected_path)
  end
  
  local cmd = "ln -sf " .. vim.fn.shellescape(orig_path) .. " " .. vim.fn.shellescape(expected_path)
  local success = vim.fn.system(cmd)
  return success == ""
end
```

### Safe Query Loading

```lua
-- Safely load a query file
function safe_get_query(lang, query_name)
  local ok, query = pcall(vim.treesitter.query.get, lang, query_name)
  if not ok or not query then
    print("Failed to load " .. query_name .. " query for " .. lang)
    return nil
  end
  return query
end
```

## Conclusion

These Neovim API calls and examples provide a solid foundation for working with TreeSitter in Neovim. Use them for debugging, customization, or building your own TreeSitter-based plugins and features. 