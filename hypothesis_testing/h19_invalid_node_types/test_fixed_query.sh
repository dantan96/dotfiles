#!/bin/bash

# Test script for validating the fixed query file

# Define paths
NVIM_CONFIG=$(cd ~/.config/nvim && pwd)
ORIGINAL_QUERY="$NVIM_CONFIG/queries/spthy/highlights.scm"
FIXED_QUERY="$NVIM_CONFIG/queries/spthy/highlights.scm.fixed"
RESULTS_FILE="/tmp/query_validation_results.txt"

# Run Neovim to validate both queries
nvim --headless -n -u NORC -c "
set rtp+=$NVIM_CONFIG
lua << EOF
  -- Test original query
  local original_ok, original_err = pcall(function()
    local file = io.open('$ORIGINAL_QUERY', 'r')
    local content = file:read('*all')
    file:close()
    vim.treesitter.query.parse('spthy', content)
  end)
  
  -- Test fixed query
  local fixed_ok, fixed_err = pcall(function()
    local file = io.open('$FIXED_QUERY', 'r')
    local content = file:read('*all')
    file:close()
    vim.treesitter.query.parse('spthy', content)
  end)
  
  -- Write results
  local results = {
    'ORIGINAL QUERY:',
    'Valid: ' .. (original_ok and 'YES' or 'NO'),
    original_ok and '' or ('Error: ' .. tostring(original_err)),
    '',
    'FIXED QUERY:',
    'Valid: ' .. (fixed_ok and 'YES' or 'NO'),
    fixed_ok and '' or ('Error: ' .. tostring(fixed_err))
  }
  
  local file = io.open('$RESULTS_FILE', 'w')
  file:write(table.concat(results, '\\n'))
  file:close()
EOF
" -c "qa!"

# Display test results
if [ -f "$RESULTS_FILE" ]; then
  echo "=== QUERY VALIDATION RESULTS ==="
  cat "$RESULTS_FILE"
  echo "================================"
  rm -f "$RESULTS_FILE"
else
  echo "Test failed: No results file generated"
  exit 1
fi 