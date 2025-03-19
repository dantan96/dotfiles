#!/bin/bash

# Test opening and highlighting a Tamarin file in Neovim

# Create test directory and test file
TEST_DIR="$HOME/tamarin_test"
mkdir -p "$TEST_DIR"

# Create a simple Tamarin test file
cat > "$TEST_DIR/test.spthy" << 'EOF'
theory Test
begin

rule Test:
  [ ] --[ ]-> [ ]
  
lemma test:
  exists-trace
  "test"
  
end
EOF

# Error log file
ERROR_LOG="$TEST_DIR/neovim_errors.log"

echo "Running Neovim with Tamarin test file..."

# Custom vimrc that only loads our tamarin plugin code
cat > "$TEST_DIR/minimal_init.vim" << 'EOF'
" Minimal init.vim for testing Tamarin

" Register the language mapping
lua <<EOF
  vim.treesitter.language.register('spthy', 'tamarin')
  
  -- Find the parser in standard locations
  local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
  if vim.fn.filereadable(parser_path) == 1 then
    if vim.treesitter.language.add then
      vim.treesitter.language.add('spthy', {path = parser_path})
    end
  end
  
  -- Set up filetype detection
  vim.filetype.add({
    extension = {
      spthy = "tamarin"
    }
  })
EOF

" Enable TreeSitter highlighting
autocmd FileType tamarin TSEnable highlight
EOF

# Run Neovim with our test file
echo "nvim --clean -n -u $TEST_DIR/minimal_init.vim $TEST_DIR/test.spthy"
timeout 5 nvim --clean -n -u "$TEST_DIR/minimal_init.vim" "$TEST_DIR/test.spthy" 2> "$ERROR_LOG"

# Check for errors
if [ -s "$ERROR_LOG" ]; then
  echo "Errors detected when running Neovim:"
  cat "$ERROR_LOG"
  rm -rf "$TEST_DIR"
  exit 1
else
  echo "Success! No errors detected when opening and highlighting a Tamarin file."
  rm -rf "$TEST_DIR"
  exit 0
fi 