#!/bin/bash

# validate_highlighting.sh
# Script to run the syntax highlighting validator headlessly

echo "Running Tamarin syntax highlighting validation..."
echo "==============================================="

# Run the validator headlessly with a timeout to prevent hanging
# Use -n flag to avoid loading vimrc file which might pause for user input
# Add --cmd 'set t_ti= t_te= nomore' to prevent pauses for "Press ENTER" prompts
timeout 20s nvim --headless -n -u NONE --cmd 'set t_ti= t_te= nomore' -c "luafile validate_syntax_colors.lua" > validation_output.txt 2>&1
NVIM_EXIT=$?

# Check exit code - 124 indicates timeout
if [ $NVIM_EXIT -eq 124 ]; then
  echo "Error: Validation timed out after 20 seconds!"
  echo "This may indicate a hanging process or infinite loop in the validation script."
  exit 1
elif [ $NVIM_EXIT -ne 0 ]; then
  echo "Error running validation!"
  echo "Error details:"
  cat validation_output.txt
  exit 1
else
  echo "Validation complete. Results:"
  echo "----------------------------"
  cat validation_output.txt
  
  # Also display the full report if available
  if [ -f "syntax_validation_results.md" ]; then
    echo ""
    echo "Full detailed report saved to syntax_validation_results.md"
    # Consider this a success
    exit 0
  else
    echo "Warning: No validation results file was generated!"
    exit 1
  fi
fi 