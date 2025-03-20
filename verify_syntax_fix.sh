#!/bin/bash

# Verify Tamarin Syntax Highlighting Fix
# This script guides you through verifying that the syntax highlighting is working

echo -e "\033[1mTamarin Syntax Highlighting Verification\033[0m"
echo "================================================="
echo
echo "The syntax highlighting fix has been applied to your Neovim configuration."
echo "To verify that it's working correctly, follow these steps:"
echo
echo -e "\033[1mStep 1:\033[0m Open the test.spthy file with Neovim:"
echo "       nvim test.spthy"
echo
echo -e "\033[1mStep 2:\033[0m Check that the following elements are correctly highlighted:"
echo "       - Keywords: 'theory', 'begin', 'end', 'rule', 'lemma' (should be magenta/pink and bold)"
echo "       - Public variables: '$A' (should be deep green)"
echo "       - Fresh variables: '~id', '~ltk' (should be hot pink)"
echo "       - Persistent facts: '!User', '!Pk' (should be red and bold)"
echo "       - Builtin facts: 'Fr', 'Out' (should be blue with underline)"
echo "       - Comments: lines starting with '//' and blocks between '/*' and '*/'"
echo
echo -e "\033[1mStep 3:\033[0m If anything is not highlighted correctly, you can run the fix again:"
echo "       ./run_syntax_fixer.sh"
echo
echo -e "\033[1mHTML Visual Representation:\033[0m"
echo "For a visual representation of how the syntax highlighting should look,"
echo "open the following file in your web browser:"
echo "       /Users/dan/.config/nvim/highlight_visual_test.html"
echo
echo "Would you like to view the test file now? (Y/n): "
read -r answer

if [[ "$answer" != "n" && "$answer" != "N" ]]; then
    echo "Opening test.spthy in Neovim..."
    nvim test.spthy
fi 