#!/bin/bash

# validate_highlighting.sh
# Script to run the syntax highlighting validator headlessly

echo "Running Tamarin syntax highlighting validation..."
echo "==============================================="

# Run the validator headlessly
nvim --headless -u NONE -c "luafile validate_syntax_colors.lua" > validation_output.txt 2>&1

# Check if the run was successful
if [ $? -eq 0 ]; then
  echo "Validation complete. Results:"
  echo "----------------------------"
  cat validation_output.txt
  
  # Also display the full report if available
  if [ -f "syntax_validation_results.md" ]; then
    echo ""
    echo "Full detailed report saved to syntax_validation_results.md"
  fi
else
  echo "Error running validation!"
  echo "Error details:"
  cat validation_output.txt
fi 