#!/bin/bash

# Disable Syntax File
# This script disables the problematic syntax file by renaming it

echo "Disabling the problematic syntax/spthy.vim file..."

# Check if the file exists
if [ -f "./syntax/spthy.vim" ]; then
    # Create backup if it doesn't exist
    if [ ! -f "./syntax/spthy.vim.bak" ]; then
        cp "./syntax/spthy.vim" "./syntax/spthy.vim.bak"
        echo "Backup created: ./syntax/spthy.vim.bak"
    fi
    
    # Rename the file
    mv "./syntax/spthy.vim" "./syntax/spthy.vim.disabled"
    echo "File renamed to: ./syntax/spthy.vim.disabled"
    
    # Success message
    echo -e "\033[0;32mSuccess!\033[0m The syntax file has been disabled."
    echo "This should prevent errors when loading spthy files."
    echo "To restore the file, run: mv ./syntax/spthy.vim.disabled ./syntax/spthy.vim"
else
    echo -e "\033[0;31mError:\033[0m File ./syntax/spthy.vim not found."
    echo "Nothing to disable."
fi 