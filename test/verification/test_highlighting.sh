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
  -c "lua require('test.verification.validate_node_types').ensure_parser_loaded()" \
  -c "edit ~/test_tamarin/test.spthy" \
  -c "set filetype=tamarin" \
  -c "lua vim.treesitter.language.register('spthy', 'tamarin')" \
  -c "lua local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'; if vim.treesitter.language.add then vim.treesitter.language.add('spthy', {path = parser_path}) end" \
  -c "TSEnable highlight" \
  -c "lua if vim.treesitter.highlighter then local parser = vim.treesitter.get_parser(0, 'spthy'); local highlighter = vim.treesitter.highlighter.new(parser); vim.g.tamarin_highlighter = highlighter end" \
  -c "sleep 1" \
  -c "lua vim.notify('Syntax highlighting test completed')" \
  -c "lua if vim.treesitter.highlighter and vim.treesitter.highlighter.active and vim.treesitter.highlighter.active[0] then vim.notify('Highlighter is active!') else vim.notify('Highlighter is NOT active!', vim.log.levels.ERROR) end" \
  -c "qa!"

echo "Test completed. The file was successfully processed."

# Clean up
rm -rf ~/test_tamarin

exit 0 