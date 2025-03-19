#!/bin/bash

# Test script for validating TreeSitter syntax highlighting for Tamarin files
# Focuses on variables with apostrophes which previously caused regex stack overflows

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="$SCRIPT_DIR/apostrophe_test.spthy"

# Clean up any previous test data
rm -f "$SCRIPT_DIR/test_results.txt"

# Run Neovim in headless mode to test the Tamarin TreeSitter integration
nvim --headless -u NORC \
  -c "set rtp+=$(cd ~/.config/nvim && pwd)" \
  -c "lua package.path = '$(cd ~/.config/nvim && pwd)/lua/?.lua;' .. package.path" \
  -c "lua vim.opt.runtimepath:append('$(cd ~/.config/nvim && pwd)')" \
  -c "lua require('tamarin').setup()" \
  -c "e $TEST_FILE" \
  -c "lua local h = require('tamarin.highlighter'); local d = require('tamarin.diagnostics'); local success = h.ensure_highlighting(0); local diagnostics = d.run_diagnosis(); vim.fn.writefile({success and 'Highlighting setup: SUCCESS' or 'Highlighting setup: FAILED', string.format('Parser found: %s', diagnostics.parser_found and 'YES' or 'NO'), string.format('Query file valid: %s', diagnostics.query_valid and 'YES' or 'NO'), string.format('Apostrophe handling: %s', diagnostics.apostrophe_handling and 'WORKING' or 'BROKEN')}, '$SCRIPT_DIR/test_results.txt')" \
  -c "qa!"

# Display test results
if [ -f "$SCRIPT_DIR/test_results.txt" ]; then
  echo "=== TEST RESULTS ==="
  cat "$SCRIPT_DIR/test_results.txt"
  echo "===================="
else
  echo "Test failed: No results file generated"
  exit 1
fi 