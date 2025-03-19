#!/bin/bash

# Script to detect all Neovim errors when loading a Tamarin file

# Create test directory and file
mkdir -p ~/test_tamarin
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

# Error log file
ERROR_LOG="/tmp/nvim_errors.log"

echo "Running Neovim with test file and capturing errors..."

# Run Neovim in headless mode and redirect stderr to our log file
nvim --headless -c "lua vim.treesitter.language.register('spthy', 'tamarin')" \
                -c "edit ~/test_tamarin/test.spthy" \
                -c "set filetype=tamarin" \
                -c "TSEnable highlight" \
                -c "sleep 1" \
                -c "lua vim.cmd('redir! > $ERROR_LOG'); vim.cmd('silent! messages'); vim.cmd('redir END')" \
                -c "qa!" 2>> $ERROR_LOG

# Check if error log contains any errors
if [ -s "$ERROR_LOG" ]; then
    echo "ERRORS DETECTED:"
    echo "------------------------------------------------------------"
    cat "$ERROR_LOG"
    echo "------------------------------------------------------------"
    
    # Look for specific TreeSitter errors
    if grep -q "Query error" "$ERROR_LOG"; then
        echo "TreeSitter query errors found! These need to be fixed in highlights.scm."
        grep -A 3 "Query error" "$ERROR_LOG"
    fi
    
    exit 1
else
    echo "No errors detected. Syntax highlighting appears to be working correctly."
    exit 0
fi

# Clean up
rm -rf ~/test_tamarin 