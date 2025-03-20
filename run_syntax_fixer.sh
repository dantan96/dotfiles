#!/bin/bash

# Run Tamarin Syntax Fixer
# This script fixes the Tamarin syntax highlighting configuration

echo "Running Tamarin syntax fixer..."
echo "==============================="

# Run Neovim headlessly with the fixer script
nvim --headless -c "luafile fix_tamarin_syntax.lua" -c "qa!" > fix_output.txt 2>&1
FIX_EXIT=$?

# Display the output
cat fix_output.txt

# Check for errors
if [ $FIX_EXIT -ne 0 ]; then
    echo -e "\n\033[0;31mError: Fixer failed with exit code $FIX_EXIT\033[0m"
    exit 1
else
    echo -e "\n\033[0;32mSyntax fixing completed. Now open a .spthy file in Neovim to test the changes.\033[0m"
    
    # Suggest next steps
    echo -e "\nTo test the changes, run:"
    echo "  nvim test.spthy"
fi 