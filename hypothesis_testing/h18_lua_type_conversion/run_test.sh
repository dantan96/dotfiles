#!/bin/bash

# Script to run the h18_lua_type_conversion test

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="$SCRIPT_DIR/h18_lua_type_conversion_test.lua"
RESULTS_FILE="$SCRIPT_DIR/test_results.txt"

# Clean up previous results
rm -f "$RESULTS_FILE"

# Create a test Tamarin file
TEST_SPTHY_FILE="/tmp/test_h18.spthy"
cat > "$TEST_SPTHY_FILE" << 'EOF'
theory Test
begin

// Variables with apostrophes (previously problematic)
rule Apostrophes:
    let x' = 'foo'
    let y' = 'bar'
    in
    [ In(x') ] --[ Processed(x', y') ]-> [ Out(y') ]

end
EOF

# Run Neovim in headless mode with the test
nvim --headless -u NORC \
  -c "set rtp+=$(cd ~/.config/nvim && pwd)" \
  -c "lua package.path = '$(cd ~/.config/nvim && pwd)/lua/?.lua;' .. package.path" \
  -c "lua vim.opt.runtimepath:append('$(cd ~/.config/nvim && pwd)')" \
  -c "e $TEST_SPTHY_FILE" \
  -c "set filetype=tamarin" \
  -c "lua local results = dofile('$TEST_FILE'); vim.fn.writefile({string.format('Parser loaded: %s', results.parser_ok and 'YES' or 'NO'), string.format('Highlighter created: %s', results.highlighter_ok and 'YES' or 'NO'), string.format('Storage tests completed: %s', results.store_ok and 'YES' or 'NO'), string.format('Registry approach works: %s', results.registry_approach_works and 'YES' or 'NO'), '', 'ERRORS:', unpack(results.errors or {})}, '$RESULTS_FILE')" \
  -c "qa!"

# Display test results
if [ -f "$RESULTS_FILE" ]; then
  echo "=== TEST RESULTS ==="
  cat "$RESULTS_FILE"
  echo "===================="
else
  echo "Test failed: No results file generated"
  exit 1
fi

# Clean up
rm -f "$TEST_SPTHY_FILE" 