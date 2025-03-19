#!/bin/bash

# Run verification for Tamarin syntax highlighting

# Go to the Neovim config directory
cd ~/.config/nvim

# Run the verification script with Neovim
nvim --headless -c "lua require('test.verification.verify_highlighting').run_verification()" -c "lua vim.cmd('qa!')"

# Check the log file if it exists
if [ -f ~/.cache/nvim/tamarin_verification.log ]; then
  echo "Verification completed. Log contents:"
  echo "-----------------------------------"
  cat ~/.cache/nvim/tamarin_verification.log
  echo "-----------------------------------"
else
  echo "Error: Verification log file not created."
  exit 1
fi

# Check for any failures in the log
if grep -q "FAIL" ~/.cache/nvim/tamarin_verification.log; then
  echo "Verification FAILED. See log for details."
  exit 1
else
  echo "Verification PASSED!"
  exit 0
fi 