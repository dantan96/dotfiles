# Tamarin Spthy Parser Solution

## Problem

When opening Neovim with Tamarin files, the following errors were occurring:

```
Setting up Tamarin Spthy parser integration
Tamarin parser symlink already exists
nvim-treesitter is not available, skipping parser mapping setup
Error detected while processing /Users/dan/.config/nvim/init.lua:
Failed to load parser for language 'tamarin': ... tried: '/Users/dan/.config/nvim/parser/tamarin.so' (no such file)
```

And when opening a `.spthy` file:

```
BufReadPost Autocommands for "*": Vim(append):Error executing lua callback: ...
Failed to load parser: uv_dlsym: dlsym(0x457d1130, tree_sitter_tamarin): symbol not found
```

## Solution

After extensive testing, we determined there were two viable approaches:

1. Create a renamed copy of the `spthy.so` parser with the symbol `tree_sitter_tamarin` 
2. Configure Neovim to use the `spthy` parser directly for `.spthy` files

We encountered segmentation faults with approach #1, so we implemented approach #2, which is working successfully.

### Working Solution: Direct Spthy Parser Approach

The solution uses the following components:

1. Configure filetype detection to map `.spthy` files to the `spthy` filetype
2. Use Neovim's TreeSitter API to activate the `spthy` parser for these files
3. Add appropriate ftplugin support

This approach avoids the need for symbol renaming or aliasing entirely, and allows for proper syntax highlighting and parsing of Tamarin Spthy files.

## Implementation Details

The solution consists of the following files:

- `ftdetect/tamarin.vim` - Maps `.spthy` and `.sapic` files to the `spthy` filetype
- `ftplugin/spthy.vim` - Configures TreeSitter for spthy files
- Configuration in `init.lua` to set up filetype detection and TreeSitter integration

## Testing

The solution has been verified with the `spthy_test.lua` script, which confirms:

1. The spthy parser loads successfully
2. The parser can parse spthy content correctly 
3. Filetype detection for `.spthy` files works properly
4. TreeSitter highlighting attaches to `.spthy` buffers

## Limitations

While this solution enables proper syntax highlighting and parsing for `.spthy` files, it does not enable loading a parser named `tamarin`. However, since we're using the `spthy` parser directly, this limitation doesn't affect functionality.

## Future Improvements

If a true `tamarin` parser is needed in the future, a C-based approach for symbol renaming might be required, as our attempts with `objcopy` resulted in segmentation faults.

## Cleanup Instructions

To adopt this solution:

1. Run the `modified_spthy_parser_approach.lua` script
2. Restart Neovim

The script will:
- Configure filetype detection
- Set up the ftplugin for spthy
- Update init.lua with the necessary configuration 