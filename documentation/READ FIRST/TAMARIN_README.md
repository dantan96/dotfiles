# Tamarin Support for Neovim

This configuration provides support for Tamarin Security Protocol Theory (`.spthy`) files in Neovim, including:

1. Filetype detection for `.spthy` and `.sapic` files
2. Syntax highlighting
3. TreeSitter integration (when available)

## File Structure

The integration is set up with the following components:

- `ftdetect/tamarin.vim` - Detects `.spthy` and `.sapic` files and sets the filetype to "spthy"
- `syntax/spthy.vim` - Provides syntax highlighting rules for Tamarin files
- `ftplugin/spthy.vim` - Sets up editor behavior for Tamarin files
- `lua/config/tamarin_setup.lua` - Manages the overall integration

## Directory Structure

The correct Neovim directory structure for this integration is:

```
~/.config/nvim/
  ├── ftdetect/tamarin.vim      # Filetype detection
  ├── ftplugin/spthy.vim        # Filetype-specific settings
  ├── syntax/spthy.vim          # Syntax highlighting definitions
  ├── lua/config/tamarin_setup.lua  # Integration module
  └── init.lua                  # Main config loading the module
```

## How It Works

1. When a `.spthy` or `.sapic` file is opened, it's detected and the filetype is set to "spthy"
2. The system tries to use TreeSitter for syntax highlighting if available
3. If TreeSitter is not available or fails, it falls back to traditional Vim syntax highlighting

## Troubleshooting

If syntax highlighting is not working:

1. Check that the filetype is set to "spthy" with `:echo &filetype`
2. Ensure syntax highlighting is enabled with `:syntax enable`
3. If using TreeSitter, check if the spthy parser is installed with `:lua =vim.treesitter.language.inspect("spthy")`

## Known Issues

- The "tamarin" parser name is not supported directly, only "spthy"
- Some earlier attempts to use a renamed version of the parser caused segmentation faults
- The current approach uses the "spthy" parser directly instead of trying to rename it 