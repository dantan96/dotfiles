# Tamarin TreeSitter Integration

This module provides robust TreeSitter syntax highlighting for Tamarin protocol files (`.spthy` and `.sapic`).

## Overview

The Tamarin TreeSitter integration addresses common issues with syntax highlighting in Tamarin files, particularly:

1. Parser registration and mapping issues
2. Stack overflow errors in the regex engine due to complex patterns
3. Garbage collection of highlighter objects
4. Handling of variables with apostrophes

## Components

The implementation consists of several modular components:

- **Parser Module** (`lua/tamarin/parser.lua`): Handles parser discovery, registration, and external scanner support
- **Highlighter Module** (`lua/tamarin/highlighter.lua`): Sets up buffer-specific highlighting with proper garbage collection prevention
- **Main Module** (`lua/tamarin/init.lua`): Coordinates all functionality and provides user-facing API
- **Query File** (`queries/spthy/highlights.scm`): Contains simplified syntax highlighting rules that avoid complex regex patterns
- **Diagnostics Module** (`lua/tamarin/diagnostics.lua`): Provides debugging tools

## Directory Structure

The code uses a standardized directory structure:

```
~/.config/nvim/
├── lua/tamarin/               # Lua modules
│   ├── init.lua               # Main entry point
│   ├── parser.lua             # Parser registration
│   ├── highlighter.lua        # Highlighting setup
│   └── diagnostics.lua        # Debugging tools
├── parser/spthy/              # Parser location
│   └── spthy.so               # TreeSitter parser
└── queries/spthy/             # Query files
    └── highlights.scm         # Syntax highlighting rules
```

## Installation

1. Ensure you have the TreeSitter parser for Tamarin/Spthy
2. Copy the Lua modules to your Neovim configuration
3. Ensure your init.lua initializes the module

```lua
-- In your init.lua or equivalent
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("tamarin").setup()
  end,
  once = true,
})
```

## Implementation Details

### Parser Registration

The module properly registers the parser and maps the language to the correct filetype:

```lua
vim.treesitter.language.register('spthy', 'tamarin')
```

If available, it also uses the explicit path registration method:

```lua
vim.treesitter.language.add('spthy', { path = parser_path })
```

### Safe Query Patterns

The query file uses simple patterns to avoid regex engine stack overflows:

```scheme
;; Simple predicates instead of complex regex
((ident) @constant
 (#match? @constant "^[A-Z]"))

((ident) @variable
 (#match? @variable "^[a-z]"))
```

### External Scanner Support

The implementation checks for and supports the external scanner functions in the parser, which are specially designed to handle tokens that are difficult to describe with regular expressions, such as variables with apostrophes.

### Garbage Collection Prevention

Highlighters are stored in buffer-local variables to prevent premature garbage collection:

```lua
vim.b[bufnr].tamarin_ts_highlighter = highlighter
```

## Troubleshooting

If you encounter issues, you can use the diagnostics tools:

```lua
require('tamarin').diagnose()
```

## Testing

A test script is provided to verify the implementation:

```lua
-- Run test script
:luafile test_tamarin.lua
```

## Background Research

This implementation is the result of extensive research into TreeSitter's architecture and limitations, particularly around regex patterns in query files and the interaction with Vim's NFA regex engine.

For more details, see the hypothesis and facts databases in this repository. 