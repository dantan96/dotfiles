#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="/tmp/h19_test.spthy"
RESULTS_FILE="$SCRIPT_DIR/test_results.txt"

# Create a simple test file
cat > "$TEST_FILE" << 'EOF'
theory Test
begin

builtins: symmetric-encryption, hashing

rule Simple:
    [ ] --[ ]-> [ ]

rule WithVariables:
    let x' = 'foo'
    let y' = 'bar'
    in
    [ In(x') ] --[ Processed(x', y') ]-> [ Out(y') ]

lemma secrecy:
    "∀ x' #i. Secret(x') @ i ⟹ ¬(∃ #j. K(x') @ j)"

end
EOF

# Run Neovim in headless mode
nvim --headless -u NORC \
  -c "set rtp+=$(cd ~/.config/nvim && pwd)" \
  -c "lua package.path = '$(cd ~/.config/nvim && pwd)/lua/?.lua;' .. package.path" \
  -c "lua vim.opt.runtimepath:append('$(cd ~/.config/nvim && pwd)')" \
  -c "lua require('tamarin').setup()" \
  -c "e $TEST_FILE" \
  -c "lua local node_types = dofile('$SCRIPT_DIR/h19_node_types_test.lua'); local query_types = dofile('$SCRIPT_DIR/h19_query_analysis.lua'); vim.fn.writefile({string.format('SUPPORTED NODE TYPES:'), unpack(type(node_types) == 'table' and node_types or {tostring(node_types)}), '', string.format('NODE TYPES IN QUERY:'), unpack(type(query_types) == 'table' and query_types or {tostring(query_types)})}, '$RESULTS_FILE')" \
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
rm -f "$TEST_FILE" 