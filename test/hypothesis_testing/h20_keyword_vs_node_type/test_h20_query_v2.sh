#!/bin/bash

# Script to test the H20 query fix (version 2)
# H20: Keyword vs Node Type Confusion

echo "=== H20: Testing fixed query file (version 2) ==="
echo

# Create the fixed query file
echo "Creating fixed query file based on H20 hypothesis (v2)..."
nvim --headless -n -u NORC -c "luafile $(pwd)/hypothesis_testing/h20_keyword_vs_node_type/create_fixed_query_v2.lua" -c "qa!" 2>&1

# Verify that the file was created
if [ ! -f "$(pwd)/queries/spthy/highlights.scm.h20v2" ]; then
  echo "ERROR: Failed to create fixed query file"
  exit 1
fi

echo "Fixed query file created successfully"
echo

# Test the original and fixed query files
echo "Testing both query files..."

# Use the validate_queries.lua script with modified paths
cp "$(pwd)/hypothesis_testing/h19_invalid_node_types/validate_queries.lua" "$(pwd)/hypothesis_testing/h20_keyword_vs_node_type/validate_h20v2.lua"

# Edit the script to point to our H20v2 query file
sed -i '' "s|local fixed_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm.fixed'|local fixed_query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm.h20v2'|" "$(pwd)/hypothesis_testing/h20_keyword_vs_node_type/validate_h20v2.lua"

# Run the validation
nvim --headless -n -u NORC -c "luafile $(pwd)/hypothesis_testing/h20_keyword_vs_node_type/validate_h20v2.lua" 2>&1

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