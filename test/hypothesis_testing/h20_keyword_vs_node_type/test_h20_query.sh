#!/bin/bash

# Script to test the H20 query fix
# H20: Keyword vs Node Type Confusion

echo "=== H20: Testing fixed query file ==="
echo

# Create the fixed query file
echo "Creating fixed query file based on H20 hypothesis..."
nvim --headless -n -u NORC -c "luafile $(pwd)/hypothesis_testing/h20_keyword_vs_node_type/create_fixed_query.lua" -c "qa!" 2>&1

# Verify that the file was created
if [ ! -f "$(pwd)/queries/spthy/highlights.scm.h20" ]; then
  echo "ERROR: Failed to create fixed query file"
  exit 1
fi

echo "Fixed query file created successfully"
echo

# Test the original and fixed query files
echo "Testing both query files..."

# Use the validate_queries.lua script with modified paths
cp "$(pwd)/hypothesis_testing/h19_invalid_node_types/validate_queries.lua" "$(pwd)/hypothesis_testing/h20_keyword_vs_node_type/validate_h20.lua"

# Edit the script to point to our H20 query file
sed -i '' "s|local fixed_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm.fixed'|local fixed_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm.h20'|" "$(pwd)/hypothesis_testing/h20_keyword_vs_node_type/validate_h20.lua"

# Run the validation
nvim --headless -n -u NORC -c "luafile $(pwd)/hypothesis_testing/h20_keyword_vs_node_type/validate_h20.lua" 2>&1

# Display results
if [ -f "/tmp/query_results.txt" ]; then
  echo
  echo "=== QUERY VALIDATION RESULTS ==="
  cat /tmp/query_results.txt
  echo "================================"
else
  echo "Test failed: No results file generated"
  exit 1
fi

echo
echo "Test complete" 