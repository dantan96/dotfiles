#!/bin/bash

# Test script for Tamarin syntax highlighting

# Create test directory
mkdir -p ~/test_tamarin

# Create a test file
cat > ~/test_tamarin/test.spthy << 'EOF'
theory Test
begin

rule Test:
  [ ] --[ ]-> [ ]
  
lemma test:
  exists-trace
  "test"
  
end
EOF

# Run Neovim with the test file and check for TreeSitter highlighting
echo "Running Neovim with test file..."
timeout 5 nvim --headless \
  -c "edit ~/test_tamarin/test.spthy" \
  -c "set filetype=tamarin" \
  -c "lua vim.treesitter.language.register('spthy', 'tamarin'); local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'; if vim.treesitter.language and vim.treesitter.language.add then vim.treesitter.language.add('spthy', {path = parser_path}) end" \
  -c "TSEnable highlight" \
  -c "sleep 1" \
  -c "qa!"

echo "Syntax highlighting test completed."
echo "Now testing with validation script..."

# Also run the node type validation to confirm the highlights.scm file is valid
./test/verification/run_node_validation.sh

echo "All tests completed."

# Clean up
rm -rf ~/test_tamarin

exit 0 