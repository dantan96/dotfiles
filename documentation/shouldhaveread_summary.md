# Summary of TreeSitter Documentation

This document provides summaries of key documentation resources related to TreeSitter in Neovim, specifically focusing on aspects relevant to our Tamarin parser integration issues.

## Neovim TreeSitter Documentation

### [TreeSitter Query Documentation](https://neovim.io/doc/user/treesitter.html#lua-treesitter-query)
- Describes the query interface for TreeSitter in Lua
- Explains how to write and use queries to extract information from syntax trees
- Relevant to our issues: Query parsing errors may indicate problems with the query file syntax

### [FileType Query Plugin](https://neovim.io/doc/user/filetype.html#ft-query-plugin)
- Documents the `query` filetype plugin that provides syntax highlighting for TreeSitter query files
- Useful for editing highlights.scm files
- Not directly related to our parser loading issues

### [TreeSitter Query Linting](https://neovim.io/doc/user/treesitter.html#vim.treesitter.query.lint())
- Documents the `vim.treesitter.query.lint()` function that checks for errors in query files
- Could help identify issues in our highlights.scm files
- Important for diagnosing `couldn't parse regex` errors

### [TreeSitter Parsers](https://neovim.io/doc/user/treesitter.html#treesitter-parsers)
- Explains how TreeSitter parsers are loaded and used in Neovim
- Documents that parsers are loaded from `parser/{lang}.(so|dll)` files
- Critical for our issue: Neovim looks for a `tree_sitter_{lang}` symbol in the parser library

### [TreeSitter Query](https://neovim.io/doc/user/treesitter.html#treesitter-query)
- Details the query language used to extract information from syntax trees
- Relevant for writing proper highlights.scm files
- Important for understanding the relationship between the parser and highlighting

### [TreeSitter Predicates](https://neovim.io/doc/user/treesitter.html#treesitter-predicates)
- Describes predicate functions that can be used in TreeSitter queries
- Less relevant to our immediate parser loading issues
- May be useful for future refinements to the highlights.scm file

### [TreeSitter Directives](https://neovim.io/doc/user/treesitter.html#treesitter-directives)
- Explains how to use directives in TreeSitter queries
- Less relevant to our immediate parser loading issues
- Could be useful for enhancing highlights.scm in the future

### [TreeSitter Query Modeline](https://neovim.io/doc/user/treesitter.html#treesitter-query-modeline)
- Documents how to use modelines in query files
- Not directly related to our parser loading issues
- Could be useful for managing highlights.scm file compatibility

### [TreeSitter Syntax Highlighting](https://neovim.io/doc/user/treesitter.html#_treesitter-syntax-highlighting)
- Explains how TreeSitter-based syntax highlighting works
- Documents that it requires a parser and a highlights.scm query file
- Relevant to our issue: Both parser loading and query parsing must succeed for highlighting to work

### [TreeSitter Highlight Groups](https://neovim.io/doc/user/treesitter.html#treesitter-highlight-groups)
- Lists standard highlight groups used by TreeSitter
- Useful for creating compatible highlights.scm files
- Important for ensuring proper coloring once parser is loaded

### [TreeSitter Language API](https://neovim.io/doc/user/treesitter.html#treesitter-language)
- Documents the language-related functions in the TreeSitter API
- Includes functions to register and manage language parsers
- Critical for our solution: `vim.treesitter.language.register()` is key to mapping 'spthy' to 'tamarin'

### [TreeSitter Language Registration](https://neovim.io/doc/user/treesitter.html#vim.treesitter.language.register())
- Details how to map a TreeSitter language to a Vim filetype
- Exactly what we need for our solution: `vim.treesitter.language.register('spthy', 'tamarin')`
- Requires Neovim 0.9+ (which is what we're using)

### [Filetypes Documentation](https://neovim.io/doc/user/filetype.html#filetypes)
- Explains how Neovim determines and manages filetypes
- Relevant for understanding how the 'tamarin' filetype is detected
- Helps understand the relationship between files, filetypes, and TreeSitter languages

## TreeSitter Core Documentation

### [Using Parsers](https://tree-sitter.github.io/tree-sitter/using-parsers/?search=)
- Explains how to use TreeSitter parsers in various programming languages
- Documents the external API of TreeSitter parsers
- Relevant for understanding the `tree_sitter_{lang}` function that parsers must export

### [External Scanners](https://tree-sitter.github.io/tree-sitter/creating-parsers/4-external-scanners.html)
- Documents external scanners that can be used with TreeSitter parsers
- Explains why some symbols like `tree_sitter_{lang}_external_scanner_*` might exist
- Relevant to our parser: We're seeing these external scanner symbols in our .so files

### [Syntax Highlighting](https://tree-sitter.github.io/tree-sitter/3-syntax-highlighting.html)
- Explains how TreeSitter provides syntax highlighting
- Details the relationship between parsers, queries, and highlighting
- Helps understand the pipeline from parser to visual highlighting

### [The Runtime](https://tree-sitter.github.io/tree-sitter/5-implementation.html#the-runtime)
- Documents the runtime implementation of TreeSitter
- Explains how parsers are compiled and loaded
- Relevant to our symbol name mismatch issue: Different platforms may handle symbols differently

### [Static Node Types](https://tree-sitter.github.io/tree-sitter/using-parsers/6-static-node-types.html)
- Explains how node types are defined in TreeSitter parsers
- Less directly relevant to our parser loading issues
- Could be useful for diagnosing issues with the ERROR node we're seeing

## Additional Context from Web Searches

From our web searches, we've discovered:

1. **macOS Symbol Prefixing**: On macOS, the C compiler adds a leading underscore to exported symbols, turning `tree_sitter_language` into `_tree_sitter_language`.

2. **Symbol Loading in Neovim**: Neovim tries to load a symbol called `tree_sitter_{lang}` from a parser library, which on macOS would actually be called `_tree_sitter_{lang}`.

3. **Language Registration Approach**: For Neovim 0.9+, using `vim.treesitter.language.register(source_lang, target_filetype)` is the recommended approach for mapping a TreeSitter language to a different filetype.

4. **Symbol Name Mismatch Issues**: Other users have encountered similar issues where the parser exported a symbol with a name that didn't match what Neovim expected, particularly on macOS.

5. **Error Patterns**: The error pattern `Failed to load parser: dlsym(..., tree_sitter_{lang}): symbol not found` is common when there's a mismatch between the expected and actual symbol names.

## Summary of Findings

Our investigation of the documentation confirms our approach to solving the TreeSitter integration issues for Tamarin:

1. The core issue is a mismatch between the symbol name exported by the parser (`_tree_sitter_spthy`) and what Neovim is looking for (`tree_sitter_tamarin`).

2. A secondary issue is the mismatch between the language name ('spthy') and the filetype ('tamarin').

3. The solution is to use `vim.treesitter.language.register('spthy', 'tamarin')` to map the language to the filetype.

4. On macOS, Neovim handles the leading underscore automatically, so we don't need to worry about that aspect.

5. The parser loading needs to happen before query parsing, which explains why fixing the parser loading issue is a prerequisite for getting syntax highlighting working.

6. Our custom parser_loader.lua module was necessary for diagnosis but can be simplified now that we understand the core issues. 