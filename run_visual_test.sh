#!/bin/bash

# Run visual test for Tamarin syntax
# This script tests the visual representation of Tamarin syntax highlighting

echo "Running visual test for Tamarin syntax..."
echo "========================================="

# Run Neovim headlessly with the visual test script and a timeout
timeout 10s nvim --headless --clean --cmd 'set noswapfile' --cmd 'set nomore t_ti= t_te= nobackup noerrorbells' -c "luafile visual_test.lua" > visual_test_output.txt 2>&1
TEST_EXIT=$?

# Check for timeout
if [ $TEST_EXIT -eq 124 ]; then
    echo "Error: Test timed out after 10 seconds!"
    exit 1
fi

# Display the output
cat visual_test_output.txt

# Check if HTML was created
if [ -f "highlight_visual_test.html" ]; then
    echo -e "\nHTML visual representation created successfully!"
    echo "Open highlight_visual_test.html in a browser to view the syntax highlighting."
fi 