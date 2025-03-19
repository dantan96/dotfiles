#!/bin/bash

# Run the query validation script
nvim --headless -n -u NORC -c "luafile $(pwd)/hypothesis_testing/h19_invalid_node_types/validate_queries.lua"

# Display results
if [ -f "/tmp/query_results.txt" ]; then
  echo "=== QUERY VALIDATION RESULTS ==="
  cat /tmp/query_results.txt
  echo "================================"
else
  echo "Test failed: No results file generated"
  exit 1
fi 