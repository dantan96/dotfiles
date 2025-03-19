# Highly Relevant Information for TreeSitter Integration

## Core TreeSitter Concepts

### Parser Loading Process
1. **Parser Search Path**: Neovim searches for parsers in `parser/` directories within runtime path
2. **File Naming**: Must be `parser/{language}.(so|dll)`
3. **Symbol Loading**: Neovim looks for `tree_sitter_{language}` symbol
4. **Language-to-Filetype Mapping**: TreeSitter languages must be mapped to Neovim filetypes
5. **Query Files**: Located in `queries/{language}/` directories

### Symbol Name Handling
1. **Symbol Format**: Must export `tree_sitter_{language}()` returning `TSLanguage*`
2. **macOS Specifics**: Adds leading underscore to symbols (`_tree_sitter_language`)
3. **Our Case**: Parser exports `_tree_sitter_spthy` instead of expected `tree_sitter_tamarin`

### Language Registration (Neovim 0.9+)
1. **API Function**: `vim.treesitter.language.register(source_lang, target_filetype)`
2. **Our Need**: Register 'spthy' language for 'tamarin' filetype
3. **Additional Step**: May need `vim.treesitter.language.add()` for parser path

## Syntax Highlighting Process

### Setup Requirements
1. **Parser Loading**: Must successfully load parser binary
2. **Language Registration**: Must map language to filetype
3. **Query Files**: Need valid `highlights.scm` in correct location
4. **Highlighter Creation**: Must create highlighter for each buffer

### Query File Handling
1. **Location**: Must be in `queries/{language}/highlights.scm`
2. **Validation**: Use `vim.treesitter.query.lint()` to check syntax
3. **Node Types**: Must match what parser produces
4. **Regex Limitations**: Neovim's NFA regex engine has stack limitations

### Buffer-Specific Setup
1. **Parser Instance**: Each buffer needs its own parser instance
2. **Highlighter Instance**: Must be created and stored per buffer
3. **Garbage Collection**: Need to store highlighter in buffer-local variable

## Common Pitfalls to Avoid

### Parser Issues
1. **Multiple Locations**: Having parsers in multiple locations causes confusion
2. **Symbol Mismatch**: Parser symbol names must match or be properly mapped
3. **Language/Filetype Confusion**: Must handle 'spthy' vs 'tamarin' properly

### Query File Issues
1. **Complex Regex**: Avoid patterns that could overflow NFA stack
2. **Node Type Mismatch**: Query must use node types parser produces
3. **Syntax Errors**: Must validate query file syntax

### Highlighting Issues
1. **Missing Registration**: Language must be registered before highlighting
2. **Buffer Management**: Each buffer needs proper initialization
3. **Fallback Handling**: Should gracefully fall back to regular syntax

## Implementation Requirements

### Minimum Working Setup
1. **Parser Binary**: Must be in correct location with correct symbols
2. **Language Registration**: Must map 'spthy' to 'tamarin'
3. **Query File**: Must have valid `highlights.scm`
4. **Buffer Setup**: Must initialize TreeSitter for each buffer

### Robust Error Handling
1. **Parser Loading**: Handle missing/invalid parser gracefully
2. **Language Registration**: Check for API availability
3. **Query Loading**: Validate query file syntax
4. **Buffer Setup**: Handle initialization failures

### Testing Requirements
1. **Parser Loading**: Verify parser is found and loaded
2. **Symbol Inspection**: Check exported symbols
3. **Query Validation**: Test query file syntax
4. **Buffer Handling**: Test with files in various locations

## Neovim Version Specifics

### Version 0.9+ (Our Target)
1. **Language Registration**: Use `vim.treesitter.language.register()`
2. **Parser Management**: Use `vim.treesitter.language.add()`
3. **Query Validation**: Use `vim.treesitter.query.lint()`
4. **Highlighter API**: Use `vim.treesitter.highlighter.new()`

### API Availability Checks
1. **Language API**: Check for `vim.treesitter.language`
2. **Registration**: Check for `.register` method
3. **Parser Addition**: Check for `.add` method
4. **Highlighter**: Check for `vim.treesitter.highlighter`

## Documentation References

### Official Neovim Docs
- [TreeSitter Query Documentation](https://neovim.io/doc/user/treesitter.html#lua-treesitter-query)
- [TreeSitter Parsers](https://neovim.io/doc/user/treesitter.html#treesitter-parsers)
- [TreeSitter Language API](https://neovim.io/doc/user/treesitter.html#treesitter-language)
- [TreeSitter Highlighting](https://neovim.io/doc/user/treesitter.html#_treesitter-syntax-highlighting)

### TreeSitter Core Docs
- [Using Parsers](https://tree-sitter.github.io/tree-sitter/using-parsers)
- [Syntax Highlighting](https://tree-sitter.github.io/tree-sitter/3-syntax-highlighting.html)
- [The Runtime](https://tree-sitter.github.io/tree-sitter/5-implementation.html#the-runtime) 