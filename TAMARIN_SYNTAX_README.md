# Tamarin Syntax Highlighting Solution

This repository contains a solution for fixing syntax highlighting issues in Tamarin Protocol Verification Language (`.spthy`) files in Neovim.

## The Problem

Tamarin syntax highlighting was configured in multiple places with conflicting settings:

1. TreeSitter highlighting via `/queries/spthy/highlights.scm`
2. Lua-based highlighting via `lua/config/tamarin-colors.lua`
3. Traditional Vim syntax highlighting via `syntax/spthy.vim`

This caused unpredictable behavior where:
- Sometimes no colors were applied at all
- Elements were highlighted inconsistently
- The actual colors didn't match those defined in the `spthy-colorscheme.lua` file

## The Solution

Our solution simplifies and consolidates the syntax highlighting by:

1. **Embedding all color definitions directly** in the ftplugin
2. **Using direct Vim syntax commands** that work reliably in headless mode
3. **Eliminating dependency conflicts** between different highlighting systems
4. **Preventing conflicts** between TreeSitter and traditional syntax highlighting

## Files in this Solution

- **`fix_tamarin_syntax.lua`**: The main script that updates the ftplugin to fix the syntax highlighting
- **`run_syntax_fixer.sh`**: Shell script to run the fixer headlessly
- **Diagnostics & Testing**:
  - `standalone_syntax_test.lua`: Direct syntax testing script
  - `run_standalone_test.sh`: Script to run the standalone test
  - `validate_syntax_colors.lua`: Validator for syntax colors
  - `validate_highlighting.sh`: Script to run the validator

## Usage

1. To fix the syntax highlighting:
   ```bash
   ./run_syntax_fixer.sh
   ```

2. To test if the fixed syntax highlighting works:
   ```bash
   nvim test.spthy
   ```

## How It Works

The solution works by:

1. **Direct Color Application**: We directly define highlight groups using Vim's built-in highlighting system
2. **Self-Contained Setup**: The entire setup is contained in a single file without relying on external dependencies
3. **Simple Syntax Patterns**: We use straightforward regex-based syntax patterns that are reliable
4. **Explicit Priority Control**: We ensure correct highlighting priority (e.g., variables inside action facts)

## Troubleshooting

If you encounter any issues:

1. Check if the ftplugin was properly updated:
   ```bash
   cat ftplugin/spthy.vim
   ```

2. Try restoring the backup:
   ```bash
   mv ftplugin/spthy.vim.bak ftplugin/spthy.vim
   ```

3. Re-run the fixer with verbose output:
   ```bash
   nvim --cmd 'set verbose=15' test.spthy
   ``` 