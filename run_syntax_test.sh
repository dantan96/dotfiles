#!/bin/bash

# Run Tamarin Syntax Test
# This script tests the Tamarin syntax initialization in headless mode

echo "Testing Tamarin syntax initialization..."
echo "========================================"

# Run Neovim headlessly with our test script
# Add timeout, disable swapfiles, and set options to prevent any prompts
timeout 10s nvim --headless --clean --cmd 'set noswapfile' --cmd 'set nomore t_ti= t_te= nobackup noerrorbells visualbell t_vb=' -u NONE -c "luafile test_syntax_init.lua" > syntax_test_output.txt 2>&1
TEST_EXIT=$?

# Display the output
cat syntax_test_output.txt

# Check if the test was successful
if [ $TEST_EXIT -eq 124 ]; then
    echo -e "\n\033[0;31mError: Test timed out after 10 seconds!\033[0m"
    echo "The script may be hanging or waiting for user input. Check for issues in test_syntax_init.lua"
    exit 1
elif [ $TEST_EXIT -ne 0 ]; then
    echo -e "\n\033[0;31mError: Test failed with exit code $TEST_EXIT\033[0m"
    exit 1
else
    echo -e "\nSyntax initialization test completed successfully."
    
    # Check if there were any 'none' colors in the output
    if grep -q "Color: none" syntax_test_output.txt; then
        echo -e "\n\033[0;33mWARNING: Some syntax elements have no color applied!\033[0m"
        grep -n "Color: none" syntax_test_output.txt
    else
        echo -e "\n\033[0;32mAll tested syntax elements have colors applied.\033[0m"
    fi
fi 