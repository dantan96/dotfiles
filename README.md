# Neovim Configuration for Tamarin Protocol Theory

This Neovim configuration provides support for Tamarin Security Protocol Theory (`.spthy`) files with TreeSitter-based syntax highlighting.

## Features

- Proper filetype detection for `.spthy` and `.sapic` files
- TreeSitter-based syntax highlighting with careful attention to detail
- Fallback to standard highlighting when TreeSitter isn't available
- Custom color definitions optimized for protocol specifications

## Setup

The configuration has been streamlined into a few key files:

1. `lua/config/spthy_setup.lua` - Main setup module that handles:
   - Filetype detection
   - TreeSitter integration
   - Parser registration
   - Highlighting setup

2. `lua/config/tamarin-colors.lua` - Defines all syntax highlighting colors
   - Contains comprehensive documentation of all highlighting groups
   - Optimized colors for different syntax elements (facts, variables, etc.)

3. `queries/spthy/highlights.scm` - TreeSitter query file
   - Maps node types to highlighting groups
   - Handles special cases for different syntax elements

## Testing

A test script `test_spthy_setup.lua` is provided to verify the setup:

```bash
nvim --headless -l test_spthy_setup.lua
```

This script checks:
- Parser availability
- Query file availability
- Runtime path configuration
- TreeSitter highlighting activation
- Defined highlight groups

## Additions and Modifications

If you wish to modify the syntax highlighting:

1. For color changes: Edit `lua/config/tamarin-colors.lua`
2. For highlighting rules: Edit `queries/spthy/highlights.scm`
3. For setup modifications: Edit `lua/config/spthy_setup.lua`

## Parser Installation

The TreeSitter parser for Spthy is required. You can install it using:

```lua
:TSInstall spthy
```

Or make sure the parser file is located at:
- `~/.local/share/nvim/site/parser/spthy.so`
- `~/.config/nvim/parser/spthy.so` 