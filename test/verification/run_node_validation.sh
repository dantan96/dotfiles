#!/bin/bash

# Run node type validation for Tamarin syntax highlighting

# Go to the Neovim config directory
cd ~/.config/nvim

# Run the validation script with Neovim
nvim --headless -c "lua require('test.verification.validate_node_types').run_validation()" -c "lua vim.cmd('qa!')"

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
if grep -q "ERROR\|FAIL" ~/.cache/nvim/tamarin_node_types.log; then
  echo "Validation FAILED. See log for details."
  exit 1
else
  echo "Validation PASSED!"
  exit 0
fi 