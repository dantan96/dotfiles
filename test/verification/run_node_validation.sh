#!/bin/bash

# Run node type validation for Tamarin syntax highlighting with timeout

# Go to the Neovim config directory
cd ~/.config/nvim

# Run the validation script with Neovim with a 5-second timeout
timeout 5 nvim --headless -c "lua require('test.verification.validate_node_types').run_validation()" -c "qa!" || {
  echo "Validation timed out or failed. Forcing exit."
  # If we get here, it means the timeout was reached or the command failed
  exit 1
}

# Check the log file if it exists
if [ -f ~/.cache/nvim/tamarin_node_types.log ]; then
  echo "Node type validation completed. Log contents:"
  echo "-----------------------------------"
  cat ~/.cache/nvim/tamarin_node_types.log
  echo "-----------------------------------"
else
  echo "Error: Node type validation log file not created."
  exit 1
fi

# Check for any failures in the log
if grep -q "❌ Invalid Node Types" ~/.cache/nvim/tamarin_node_types.log; then
  echo "Validation FAILED. See log for details."
  exit 1
else
  echo "Validation SUCCEEDED. All node types are valid."
  exit 0
fi 