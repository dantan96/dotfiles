# Tamarin TreeSitter Integration

This directory contains files for integrating the Tamarin Protocol Prover language with Neovim using TreeSitter.

## What's Included

1. **Filetype Detection**:
   - `lua/ftdetect/tamarin.lua`: Detects `.spthy` and `.sapic` files as Tamarin files

2. **TreeSitter Highlighting**:
   - `queries/spthy/highlights.scm`: TreeSitter query for syntax highlighting Tamarin files

3. **Parser Integration**:
   - `lua/config/spthy_parser_init.lua`: Creates a symlink from tamarin.so to spthy.so
   - `lua/config/treesitter_parser_map.lua`: Maps the Tamarin filetype to the Spthy parser

4. **Testing Tools**:
   - `lua/test/validate_tamarin_highlights.lua`: Validates syntax highlighting for Tamarin
   - `lua/test/treesitter_playground.lua`: Visualizes the TreeSitter parse tree for Tamarin files
   - `lua/test/run_tests.lua`: Runs tests for Tamarin syntax highlighting
   - `lua/test/setup_tests.lua`: Sets up the testing environment

5. **Fix Utilities**:
   - `fix_tamarin_parser.lua`: Standalone script that creates a symlink from tamarin.so to spthy.so
   - `tamarin_parser_rename.lua`: Uses objcopy to rename the exported symbol in the parser
   - `error_logger.lua`: Diagnostics tool to capture and log TreeSitter parser errors

## Installation

### Prerequisites
1. The Spthy TreeSitter parser installed as `~/.local/share/nvim/site/parser/spthy.so`
2. Neovim with TreeSitter support

### Fixing "Failed to load parser: symbol not found" Error

When Neovim tries to use TreeSitter with Tamarin files, it may show an error:

```
Failed to load parser: uv_dlsym: dlsym(..., tree_sitter_tamarin): symbol not found
```

This happens because:
1. Neovim sets filetype to "tamarin"
2. TreeSitter looks for a parser named "tamarin" with symbol "tree_sitter_tamarin"
3. But our parser is named "spthy" with symbol "tree_sitter_spthy"

There are two ways to fix this:

#### Option 1: Using the Symlink Method (Easier)
Run:
```
nvim --headless -l fix_tamarin_parser.lua
```
This creates a symlink from tamarin.so to spthy.so, but the symbol name mismatch remains.

#### Option 2: Using the Symbol Renaming Method (Better)
This requires GNU binutils (objcopy):

```bash
# On macOS:
brew install binutils

# Then run:
nvim --headless -l tamarin_parser_rename.lua
```

This copies spthy.so to tamarin.so and renames the exported symbol to match what Neovim expects.

## Verification

To verify the installation works:

```
nvim --headless -l verify_treesitter.lua
```

This will check:
1. If the Spthy parser is available
2. If highlight queries exist
3. If filetype detection works
4. If basic parsing works

## Credits

- TreeSitter grammar for Spthy is from the [Tamarin Prover](https://github.com/tamarin-prover/tamarin-prover) project
- VS Code extension inspiration from [vscode-tamarin](https://github.com/tamarin-prover/vscode-tamarin) 