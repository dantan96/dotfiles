# Common Pitfalls in TreeSitter Integration

This document outlines common pitfalls and false leads that can occur when troubleshooting TreeSitter integration issues in Neovim, particularly based on our experience with the Tamarin parser.

## Parser Loading Pitfalls

### Pitfall 1: Assuming Parser Name Equals Filetype

**Description**: Assuming that the parser name should always match the filetype can lead to confusion.

**Reality**: TreeSitter parsers can have different names than the filetypes they support. For example, a parser might be named 'spthy' but support the 'tamarin' filetype.

**Solution**: Use `vim.treesitter.language.register()` to map between languages and filetypes explicitly.

### Pitfall 2: Ignoring Symbol Name Prefixes

**Description**: Overlooking the fact that compiled C symbols might have different naming conventions on different platforms.

**Reality**: On macOS and some other platforms, C compilers add a leading underscore to exported symbols. So `tree_sitter_language` becomes `_tree_sitter_language`.

**Solution**: Inspect actual exported symbols using tools like `nm` and adjust your loading strategy accordingly.

### Pitfall 3: Multiple Parser Locations

**Description**: Having parsers in multiple locations without being aware of which one is being loaded.

**Reality**: Neovim searches for parsers in all directories in the runtime path. If there are multiple parsers for the same language, the first one found will be used.

**Solution**: Use `vim.api.nvim_get_runtime_file('parser/{language}*', true)` to find all parsers and ensure only the correct one exists.

### Pitfall 4: Relying on nvim-treesitter for Custom Parsers

**Description**: Assuming that nvim-treesitter will handle custom parser loading automatically.

**Reality**: While nvim-treesitter provides convenient commands for installing and updating known parsers, custom parsers often require manual installation and configuration.

**Solution**: Implement custom parser loading logic for languages not supported by nvim-treesitter.

## Query File Issues

### Pitfall 5: Complex Regex Patterns

**Description**: Writing overly complex regex patterns in highlight queries.

**Reality**: Neovim's regex engine has limitations and can stack overflow with complex patterns, especially those with nested alternations, backreferences, and lookarounds.

**Solution**: Split complex patterns into multiple simpler ones, and avoid using advanced regex features when possible.

### Pitfall 6: Ignoring Query Syntax Errors

**Description**: Not checking for syntax errors in query files.

**Reality**: Syntax errors in TreeSitter queries might not produce obvious error messages, but they can cause highlighting to fail silently.

**Solution**: Validate query files incrementally, starting with minimal queries and gradually adding complexity.

### Pitfall 7: Query File Location Confusion

**Description**: Confusion about where query files should be placed.

**Reality**: Query files should be in `queries/{language}/` directories, but the language name must match the one used by the parser, not necessarily the filetype.

**Solution**: Ensure query files are in the correct location, or use symlinks to support multiple names.

## Debugging Pitfalls

### Pitfall 8: Insufficient Logging

**Description**: Not adding enough logging to diagnose complex issues.

**Reality**: TreeSitter integration involves multiple components that need to work together. Without detailed logging, it can be difficult to identify where the problem lies.

**Solution**: Implement comprehensive logging that tracks parser loading, language registration, and query parsing.

### Pitfall 9: Testing Too Much at Once

**Description**: Trying to fix all issues at once instead of isolating components.

**Reality**: TreeSitter issues can have multiple causes. Testing everything together makes it difficult to identify which component is causing the problem.

**Solution**: Test components in isolation - parser loading, language registration, and query parsing - before combining them.

### Pitfall 10: Overlooking Version Differences

**Description**: Not accounting for differences between Neovim versions.

**Reality**: TreeSitter APIs have evolved significantly across Neovim versions. Some APIs (like `vim.treesitter.language.register()`) are only available in newer versions.

**Solution**: Check Neovim version and implement version-specific workarounds as needed.

## Query Language Pitfalls

### Pitfall 11: Undefined Node Types

**Description**: Using node types in queries that don't exist in the grammar.

**Reality**: If a query refers to a node type that isn't produced by the parser, it won't work, and you might not get a clear error message.

**Solution**: Inspect the actual node types produced by the parser using tools like nvim-treesitter-playground and use only valid node types in queries.

### Pitfall 12: Regex Pattern Compatibility

**Description**: Using regex syntax that's valid in other environments but not in Neovim.

**Reality**: Neovim's regex syntax is different from PCRE, JavaScript, and other common regex flavors.

**Solution**: Test regex patterns in Neovim directly using commands like `:echo match("test", "pattern")` before using them in queries.

### Pitfall 13: Overusing Predicates

**Description**: Using too many predicates in TreeSitter queries, which can slow down highlighting.

**Reality**: While predicates like `#match?` and `#eq?` are powerful, they add processing overhead and can cause performance issues in large files.

**Solution**: Use predicates judiciously, and prefer direct node captures when possible.

## Environment-Specific Pitfalls

### Pitfall 14: Architecture Mismatches

**Description**: Using parsers compiled for the wrong architecture.

**Reality**: TreeSitter parsers are compiled binaries that must match the architecture of the Neovim binary (e.g., x86_64, arm64).

**Solution**: Ensure parsers are compiled for the correct architecture, or provide architecture-specific versions.

### Pitfall 15: File Permission Issues

**Description**: Overlooking file permission issues with parser binaries.

**Reality**: Parser binaries need to be executable. In some environments, file permissions might be incorrect after copying files.

**Solution**: Check and fix permissions with `chmod +x parser/{language}.so` if needed.

### Pitfall 16: Assuming Cross-Platform Compatibility

**Description**: Assuming that parsers will work identically across different operating systems.

**Reality**: Symbol naming conventions, library loading mechanisms, and other factors can vary between operating systems.

**Solution**: Test on each target platform and implement platform-specific workarounds as needed.

## Tree-sitter Grammar Pitfalls

### Pitfall 17: Grammar-Query Mismatches

**Description**: Not updating queries when the grammar changes.

**Reality**: If the grammar is updated to produce different node types or structure, existing queries might break.

**Solution**: Keep queries in sync with grammar changes, and test thoroughly after grammar updates.

### Pitfall 18: Missing External Scanner

**Description**: Forgetting to compile and include the external scanner when required.

**Reality**: Some TreeSitter grammars use external scanners for complex tokenization logic. Without the scanner, the parser might not work correctly.

**Solution**: Check if the grammar has an external scanner and ensure it's properly compiled and included. 