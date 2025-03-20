# The Tamarin/Spthy Symbol Problem: A Drama for the Ages

## The Problem

Tamarin Prover is a tool for the symbolic modeling and analysis of security protocols. In Neovim, proper syntax highlighting for Tamarin Security Protocol Theory (.spthy) files requires TreeSitter integration, but we encountered a persistent symbol resolution error:

```
Failed to load parser: uv_dlsym: dlsym(..., tree_sitter_tamarin): symbol not found
```

This error occurs because:

1. Neovim expects a TreeSitter parser symbol named `tree_sitter_tamarin` when a file with the 'tamarin' filetype is opened
2. The actual parser library contains a symbol named `tree_sitter_spthy`
3. Neovim's parser loading mechanism does not find the expected symbol

## Technical Background

### How TreeSitter Parser Loading Works

TreeSitter parsers in Neovim are dynamically loaded shared libraries (.so files) that must export specific C functions. When a file is opened, Neovim:

1. Determines the filetype (e.g., 'tamarin' for .spthy files)
2. Attempts to load a parser based on the filetype name
3. Looks for a library at `<NEOVIM_DATA_PATH>/site/parser/<filetype>.so`
4. Tries to dynamically load the symbol `tree_sitter_<filetype>` from this library

The key issue is that the symbol name in the shared library must match what Neovim expects. For Tamarin files, we have a mismatch:
- Neovim looks for: `tree_sitter_tamarin`
- Library exports: `tree_sitter_spthy`

### Symbol Export in Shared Libraries

The symbol names in shared libraries are determined during compilation and are not easily changed after creation. They represent exported C functions that provide the entry points to the parser's functionality. The mismatch creates a fundamental compatibility issue.

## Attempted Solutions

### Approach 1: Symbolic Links (Partially Successful)

Created a symbolic link from tamarin.so to spthy.so:

```bash
ln -s spthy.so tamarin.so
```

This allowed Neovim to find the parser file but didn't resolve the symbol name mismatch.

### Approach 2: Symbol Renaming with objcopy (Failed)

Attempted to use the `objcopy` tool to rename the symbol:

```bash
objcopy --redefine-sym tree_sitter_spthy=tree_sitter_tamarin spthy.so tamarin.so
```

This approach created a new shared library with the renamed symbol, but resulted in segmentation faults because:
1. The internal consistency of the library was broken
2. Other symbols and references still expected the original symbol name
3. The parser's internal data structures relied on the original naming convention

### Approach 3: Parser Mapping in Neovim (Successful)

Instead of modifying the library, we modified Neovim's parser resolution mechanism by:

1. Using filetype aliases: `vim.treesitter.language_add_aliases("spthy", { "tamarin" })`
2. Configuring Neovim to use the 'spthy' parser for 'tamarin' filetype
3. Creating a robust fallback to traditional syntax highlighting

This approach lets us use the existing parser without renaming symbols while maintaining compatibility with Neovim's expected behavior.

## Current Implementation

Our current solution uses a layered approach:

1. **Filetype Detection**: Both .spthy and .sapic files are set to use the 'spthy' filetype
2. **Parser Mapping**: The TreeSitter parser map associates this filetype with the spthy parser
3. **Error Suppression**: Common errors are caught and suppressed
4. **Fallback Mechanism**: Traditional syntax highlighting is used if TreeSitter fails

The key parts of the implementation are:
- `ftdetect/tamarin.vim`: Sets the filetype to 'spthy'
- `lua/config/treesitter_parser_map.lua`: Maps the filetype to the correct parser
- `lua/config/tamarin_setup.lua`: Handles setup and error suppression

## Future Remediation Options

### Option 1: Custom Parser Compilation

**Approach**: Compile a custom version of the parser with the correct symbol name.
- **Pros**: Most direct solution that addresses the root cause
- **Cons**: Requires maintaining a custom fork of the parser
- **How**:
  1. Modify the grammar.js to use tamarin instead of spthy
  2. Change all symbol references in the C code
  3. Compile and install the custom parser

### Option 2: Neovim Parser API Wrapper

**Approach**: Create a wrapper that intercepts TreeSitter parser requests.
- **Pros**: No need to modify parser binaries
- **Cons**: More complex logic in Neovim config
- **How**:
  1. Intercept all parser loading requests
  2. For tamarin filetype, redirect to spthy parser
  3. Map all parser function calls between the expected and actual names

### Option 3: Filetype Standardization

**Approach**: Standardize on 'spthy' as the filetype for all Tamarin files.
- **Pros**: Simplest solution with least maintenance overhead
- **Cons**: May conflict with existing workflows or plugins expecting 'tamarin'
- **How**:
  1. Update all filetype detection to consistently use 'spthy'
  2. Remove all 'tamarin' filetype references
  3. Update documentation to reflect the standard

### Option 4: Upstream Fix in tree-sitter-spthy

**Approach**: Request upstream changes to export both symbol names.
- **Pros**: Most maintainable long-term solution
- **Cons**: Depends on external maintainers
- **How**:
  1. Submit a PR to the tree-sitter-spthy repository
  2. Add an additional export for the tree_sitter_tamarin symbol
  3. Once accepted, update to the new version

## Recommendation

The recommended approach is a combination of Option 1 and Option 3:
1. Standardize on 'spthy' as the filetype (immediate solution)
2. Pursue an upstream fix to support both symbol names (long-term solution)

This provides a working solution now while working toward a more maintainable approach for the future.

## Technical Implementation Details

For future reference, here's the actual symbol resolution mechanism in Neovim:

1. In `vim/treesitter/language.lua`, Neovim tries to load the parser with:
   ```lua
   local symbol = "tree_sitter_" .. lang
   local parser = vim.treesitter.language._create_parser_from_path(path, lang, symbol)
   ```

2. The low-level loading happens through:
   ```lua
   local handle = vim.loop.dlopen(path, nil)
   if not handle then return nil end
   local symbol_ptr = vim.loop.dlsym(handle, symbol)
   ```

3. This is where our `symbol not found` error occurs, as it can't find `tree_sitter_tamarin` in the loaded library.

Our solution works by ensuring either:
1. The filetype is 'spthy' (matching the existing symbol)
2. We alias 'tamarin' to 'spthy' at the TreeSitter level

This ensures the right parser is used without needing to modify the shared library's exported symbols. 