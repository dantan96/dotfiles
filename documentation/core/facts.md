# Facts Log

## 2023-05-20 14:00

- Parser (tamarin.so) is correctly located in the parser directory
- Neovim version is 0.10.4
- The parser is loading successfully
- The TreeSitter module is available
- The highlights.scm file is found in queries/tamarin/
- When trying to load the query, we get: "No method to get query found"
- Current tests show that the `vim.treesitter.query.get_query` function can't be found
- The runtime path includes both the parser and queries directories

## 2023-05-20 14:15

- Found the official Tamarin TreeSitter grammar repository: https://github.com/aeyno/tree-sitter-tamarin
- The aeyno/tree-sitter-tamarin repo has a version 1.6.1 release (April 2021)
- The main Tamarin repository (tamarin-prover/tamarin-prover) doesn't include TreeSitter integration directly
- According to Neovim docs, TreeSitter support in 0.10+ is still marked as "experimental"
- Correct path for query files is: `queries/{language}/highlights.scm`
- TreeSitter queries should follow a lisp-like syntax
- The API function `vim.treesitter.query.get` should be available in Neovim 0.10
- Query validation is possible using `vim.treesitter.query.lint`

## 2023-05-20 14:20

- The official Tamarin prover repository has a TreeSitter grammar in the `tree-sitter/tree-sitter-spthy` directory
- The grammar.js file in the official repo is identical to our parser/tamarin/tamarin-grammar.js file
- The grammar uses the name 'spthy' for the language (not 'tamarin')
- Our parser binary is named tamarin.so and our queries directory is tamarin/
- The official repo doesn't include any highlights.scm or other query files
- Aeyno's unofficial repo (aeyno/tree-sitter-tamarin) does have a highlights.scm file
- Aeyno's highlights.scm is simpler than our current file but may provide useful insights
- There was a conflict issue in the TreeSitter grammar (Issue #685) that was fixed in January 2025
- This issue was related to term precedence, not to query or highlighting issues
- The official TreeSitter query file format uses node names for capture and assigns highlight groups
- Standard Neovim TreeSitter queries for languages like Lua and Vim follow a consistent pattern 

# Established Facts About TreeSitter Parser Integration

This document records facts that we've established with high confidence during our investigation of TreeSitter issues with Tamarin syntax highlighting.

## TreeSitter Parser Loading Process

1. **Parser Search Path**: Neovim searches for parser libraries in directories named `parser/` within the runtime path.

2. **File Naming Convention**: Parser files should be named as `parser/{language}.so` (on Unix-like systems) or `parser/{language}.dll` (on Windows).

3. **Symbol Loading**: Neovim attempts to dynamically load a symbol named `tree_sitter_{language}` from the parser library.

4. **Language-to-Filetype Mapping**: TreeSitter uses a mapping between language names (used for parsers) and filetypes (used by Neovim).

5. **Query File Location**: After loading a parser, Neovim looks for query files (like `highlights.scm`) in `queries/{language}/` directories.

6. **Parsing Process**: After loading the parser and query files, TreeSitter parses the buffer to create a syntax tree that is used for syntax highlighting and other features.

## Symbol Name Issues

1. **Symbol Name Format**: TreeSitter parsers must export a function named `tree_sitter_{language}()` that returns a `TSLanguage*` pointer.

2. **macOS Symbol Prefixing**: On macOS, the C compiler adds a leading underscore to exported symbols, turning `tree_sitter_language` into `_tree_sitter_language`.

3. **Symbol Name Mismatch**: Our Tamarin parser exports `_tree_sitter_spthy` instead of `tree_sitter_tamarin`, causing loading failures.

4. **Language Name Mismatch**: The parser is using 'spthy' as the language name but the filetype is 'tamarin', causing confusion.

5. **Verified Solution**: We've verified that direct language registration with `vim.treesitter.language.register('spthy', 'tamarin')` successfully resolves the language/filetype mismatch.

## TreeSitter API Facts

1. **Language Registration API**: Neovim 0.9+ provides `vim.treesitter.language.register(source_lang, target_filetype)` for mapping languages to filetypes.

2. **Parser Addition API**: Neovim's `vim.treesitter.language.add(lang, opts)` function can load a parser from a specific path.

3. **Query File Requirements**: A minimal working TreeSitter setup requires at least a `highlights.scm` file for syntax highlighting.

4. **API Compatibility**: Some TreeSitter APIs are only available in specific Neovim versions:
   - `vim.treesitter.language.register()`: Neovim 0.9+
   - `vim.treesitter.language.add()`: Neovim 0.8+

5. **Nested Functionality**: Even after registering a language with `vim.treesitter.language.register()`, you still need to add the parser with `vim.treesitter.language.add()` for it to work properly.

## Regex and Query Issues

1. **Regex Engine Limitations**: Neovim's NFA-based regex engine has stack limitations that can cause errors with complex patterns.

2. **Stack Overflow Triggers**: Complex regex patterns with certain combinations of features (recursion, backreferences, nested quantifiers) can trigger stack overflows.

3. **Error Message**: The error `couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!` indicates a regex pattern that exceeds the engine's capabilities.

4. **Regex in Queries**: TreeSitter query files (like `highlights.scm`) can contain regex patterns that are evaluated by Neovim's regex engine.

## Tamarin Parser Specifics

1. **Parser File Location**: We have confirmed parsers at `/Users/dan/.config/nvim/parser/spthy/spthy.so` and `/Users/dan/.config/nvim/parser/tamarin/tamarin.so`.

2. **Exported Symbols**: Both parser files export the symbol `_tree_sitter_spthy` but not `tree_sitter_tamarin` or `tree_sitter_spthy`.

3. **Query File Symlinks**: There are symbolic links between `queries/tamarin/highlights.scm` and `queries/spthy/highlights.scm`.

4. **Architecture Compatibility**: The parser files are compiled for x86_64 architecture, which matches the system architecture.

5. **Parser Loading Success**: We've confirmed that our updated code successfully loads the parser and registers the language, as verified by our test scripts.

6. **Parser Parsing Error**: While the parser loads successfully, our tests show it returns an ERROR node as the root when parsing Tamarin files, suggesting grammar issues.

## Effective Solutions

1. **Direct Language Registration**: Using `vim.treesitter.language.register('spthy', 'tamarin')` directly maps the language to the filetype.

2. **Symbolic Links**: Creating symlinks between parser files can work around naming mismatches.

3. **Symbol Inspection**: Inspecting parser symbols with `nm -gU parser/language/language.so | grep tree_sitter` helps diagnose symbol issues.

4. **Robust Parser Loading**: A custom parser loader that handles symbol discrepancies is the most comprehensive solution.

5. **Progressive Testing**: Testing highlights.scm files with progressively increasing complexity helps isolate problematic patterns.

6. **Minimal Query Files**: Starting with ultra-minimal query files and gradually adding complexity helps identify problematic patterns.

## Neovim TreeSitter Integration

1. **Plugin Relationship**: The official `nvim-treesitter` plugin extends Neovim's built-in TreeSitter support but isn't required for basic functionality.

2. **Health Check**: Running `:checkhealth nvim-treesitter` and `:checkhealth treesitter` provides diagnostic information about the TreeSitter setup.

3. **Parser Installation**: The `:TSInstall` command from `nvim-treesitter` can install parsers, but custom parsers need manual installation.

4. **Parser Updates**: The `:TSUpdate` command can update parsers to versions compatible with the installed `nvim-treesitter` plugin.

5. **Fallback Mechanism**: When TreeSitter highlighting fails, it's common to implement a fallback to traditional syntax highlighting.

## Testing and Debugging

1. **Headless Testing**: Using `nvim --headless` with custom Lua scripts is an effective way to test TreeSitter functionality without UI interaction.

2. **Logging Strategy**: Comprehensive logging at each step of the parser loading and initialization process helps diagnose issues.

3. **Symbol Examination**: The `nm` command with appropriate flags (e.g., `-gU` on macOS/Unix) is essential for diagnosing symbol name issues.

4. **Test File Simplification**: Testing with progressively simpler files helps isolate syntax constructs that cause parsing problems.

5. **Error Suppression**: Many TreeSitter-related errors can be suppressed in production code to avoid user-facing error messages. 