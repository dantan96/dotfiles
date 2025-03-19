# Tamarin TreeSitter Integration

This module provides TreeSitter-based syntax highlighting for Tamarin protocol verification files (*.spthy, *.sapic).

## Overview

The Tamarin TreeSitter integration enhances the editing experience for Tamarin protocol files by providing proper syntax highlighting through Neovim's TreeSitter framework. It addresses several issues that previously caused highlighting to fail, particularly for variables containing apostrophes.

## Features

- TreeSitter-based syntax highlighting for Tamarin files
- Robust parser loading and registration
- Automatic fallback to traditional syntax highlighting if TreeSitter fails
- Comprehensive diagnostics for troubleshooting
- Properly handles variables with apostrophes

## Installation

The module is included in the Neovim configuration and automatically loads when Neovim starts.

## Architecture

The integration consists of several modules:

- `lua/tamarin/init.lua`: Main entry point and API
- `lua/tamarin/parser.lua`: Parser loading and registration
- `lua/tamarin/highlighter.lua`: Syntax highlighting setup
- `lua/tamarin/diagnostics.lua`: Diagnostic utilities

TreeSitter queries are defined in:

- `queries/spthy/highlights.scm`: Syntax highlighting patterns

The TreeSitter parser is located at:

- `parser/spthy/spthy.so`: The compiled parser

## Usage

Opening a Tamarin file (*.spthy, *.sapic) should automatically trigger TreeSitter syntax highlighting. 

### API Functions

- `require('tamarin').setup()`: Initialize the Tamarin TreeSitter integration
- `require('tamarin').ensure_highlighting()`: Ensure highlighting for the current buffer
- `require('tamarin').diagnose()`: Run diagnostics
- `require('tamarin').test_query_files()`: Test the query files
- `require('tamarin').test_gc()`: Test garbage collection

### Troubleshooting

If syntax highlighting isn't working:

1. Run diagnostics: `:lua require('tamarin').diagnose()`
2. Check that the parser is found and registered
3. Verify that TreeSitter is available in your Neovim build
4. Ensure the buffer's filetype is set to "tamarin"

## Implementation Details

### Key Implementation Choices

1. **Language to Filetype Mapping**: The parser exports the language "spthy" but the filetype is "tamarin". We handle this mismatch by explicitly registering the language.

2. **Simplified Query Patterns**: We avoid complex regex patterns that previously caused stack overflows, focusing on simple patterns that reliably highlight key language elements.

3. **Robust Error Handling**: We include comprehensive error handling throughout the implementation, ensuring graceful degradation if TreeSitter is unavailable or the parser fails to load.

4. **Garbage Collection Protection**: We store the highlighter in a buffer-local variable to prevent it from being garbage collected.

### Testing

The implementation includes test files with variables containing apostrophes to verify that the solution properly handles the edge cases that previously caused problems.

- `test/apostrophe_test.spthy`: Test file with variables containing apostrophes
- `test/test_apostrophes.sh`: Bash script to run the headless test

## Credits

This implementation was developed to address specific TreeSitter integration issues for Tamarin files in Neovim.

## License

This implementation is part of the Neovim configuration and follows the same licensing terms. 