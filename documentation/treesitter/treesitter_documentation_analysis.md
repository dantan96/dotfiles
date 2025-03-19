# TreeSitter Documentation Analysis

## Core Documentation Review

### 1. Neovim TreeSitter Integration

#### Parser Management
From [treesitter-parsers](https://neovim.io/doc/user/treesitter.html#treesitter-parsers):
- Parsers must be compiled for the specific architecture
- Parser discovery uses runtime path
- Symbol naming is critical for parser loading
- External scanners must be properly linked

Key Quote:
> "The parser shared libraries are searched for in the 'runtimepath' directories, under parser/{lang}.(so|dylib|dll)"

#### Language Registration
From [treesitter-language](https://neovim.io/doc/user/treesitter.html#treesitter-language):
- Language registration is separate from parser loading
- Multiple filetypes can use the same parser
- Registration must happen before highlighting

Critical API:
```lua
vim.treesitter.language.register(lang_name, lang_to_ft)
-- Example: vim.treesitter.language.register('spthy', 'tamarin')
```

#### Query System
From [lua-treesitter-query](https://neovim.io/doc/user/treesitter.html#lua-treesitter-query):
- Queries must match grammar node types
- Predicates can refine matches
- Query validation is available via API
- Captures define highlight groups

Important Note:
> "Queries are loaded from runtime files following the pattern: queries/{lang}/*.scm"

### 2. TreeSitter Core Concepts

#### Parser Lifecycle
From [Using Parsers](https://tree-sitter.github.io/tree-sitter/using-parsers):
- Parser initialization is separate from tree creation
- Each buffer needs its own syntax tree
- External scanner state must be managed
- Error recovery is built into the parser

Key Implementation Detail:
```c
TSParser *parser = ts_parser_new();
ts_parser_set_language(parser, tree_sitter_spthy());
```

#### Syntax Highlighting
From [Syntax Highlighting](https://tree-sitter.github.io/tree-sitter/3-syntax-highlighting.html):
- Highlighting based on tree structure
- Node types determine available captures
- Queries define highlighting rules
- Performance considerations for large files

Critical Quote:
> "Syntax highlighting queries consist of pattern-capture pairs, where patterns match specific nodes in the syntax tree"

### 3. Integration Points

#### Buffer Management
From [treesitter-highlight](https://neovim.io/doc/user/treesitter.html#treesitter-highlight):
- Each buffer needs a parser instance
- Highlighter must be created per buffer
- Buffer-local storage prevents GC
- Events trigger highlighting updates

Implementation Note:
```lua
vim.treesitter.highlighter.new(parser)
vim.b[bufnr].ts_highlighter = highlighter -- prevent GC
```

#### Error Handling
From [diagnostic-api](https://neovim.io/doc/user/diagnostic.html#diagnostic-api):
- Parser errors should be reported
- Fallback to regular syntax on failure
- Error messages should be user-friendly
- Diagnostic API for error display

Best Practice:
> "Use vim.notify() for user-facing messages and vim.log.levels for appropriate severity"

## Critical Findings

### 1. Parser Requirements
1. Symbol name must match language name
2. External scanner must be properly linked
3. Architecture must match Neovim binary
4. Parser must be in correct runtime path

### 2. Language Setup
1. Register language before highlighting
2. Map language to correct filetype
3. Handle multiple parser locations
4. Manage parser lifecycle properly

### 3. Query System
1. Query file must be in correct location
2. Node types must match grammar
3. Avoid complex regex patterns
4. Use proper capture groups

### 4. Buffer Handling
1. Create parser per buffer
2. Store highlighter to prevent GC
3. Handle initialization failures
4. Provide fallback mechanism

## Implementation Implications

### 1. Parser Setup
```lua
-- Must check architecture
-- Must verify symbol names
-- Must handle external scanner
-- Must be in runtime path
```

### 2. Language Registration
```lua
-- Must happen before highlighting
-- Must map spthy to tamarin
-- Must handle multiple locations
-- Must verify registration success
```

### 3. Query Management
```lua
-- Must validate syntax
-- Must match grammar nodes
-- Must avoid regex complexity
-- Must use correct capture groups
```

### 4. Buffer Management
```lua
-- Must create per-buffer parser
-- Must store highlighter
-- Must handle errors
-- Must provide fallback
```

## Documentation Gaps

1. **External Scanner Integration**
   - Limited documentation on scanner state management
   - Unclear error handling for scanner failures
   - Missing best practices for scanner initialization

2. **Multiple Parser Locations**
   - Ambiguous precedence rules
   - Limited guidance on symlink handling
   - Missing cleanup recommendations

3. **Error Recovery**
   - Incomplete documentation on parser recovery
   - Limited guidance on fallback strategies
   - Missing performance impact details

## Required Additional Research

1. **Scanner Management**
   - Review TreeSitter C API docs
   - Study external scanner examples
   - Test scanner state handling

2. **Parser Location Handling**
   - Test runtime path precedence
   - Verify symlink behavior
   - Document cleanup process

3. **Error Recovery**
   - Test parser recovery scenarios
   - Benchmark fallback performance
   - Document recovery patterns

## Documentation-Based Requirements

### 1. Minimum Implementation
```lua
-- Must have:
-- 1. Parser in correct location
-- 2. Language registration
-- 3. Valid query file
-- 4. Buffer initialization
```

### 2. Error Handling
```lua
-- Must handle:
-- 1. Parser loading failures
-- 2. Registration errors
-- 3. Query syntax errors
-- 4. Highlighting failures
```

### 3. Testing Requirements
```lua
-- Must verify:
-- 1. Parser loading
-- 2. Language registration
-- 3. Query validation
-- 4. Buffer handling
```

## Next Steps

1. **Verify Current Setup**
   - Check parser locations
   - Verify symbol names
   - Validate query files
   - Test buffer handling

2. **Document Gaps**
   - Test unclear behaviors
   - Document findings
   - Update implementation plan

3. **Implementation Plan**
   - Follow documentation guidelines
   - Address known issues
   - Include proper error handling
   - Provide comprehensive testing 