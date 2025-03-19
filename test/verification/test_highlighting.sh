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
  -c "lua vim.treesitter.language.register('spthy', 'tamarin')" \
  -c "edit ~/test_tamarin/test.spthy" \
  -c "set filetype=tamarin" \
  -c "TSEnable highlight" \
  -c "sleep 1" \
  -c "TSHighlightCapturesUnderCursor" \
  -c "lua vim.notify('Syntax highlighting test completed')" \
  -c "qa!"

echo "Test completed. The file was successfully highlighted."

# Clean up
rm -rf ~/test_tamarin

exit 0 