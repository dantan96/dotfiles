#!/bin/bash

# analyze_tamarin.sh - Run TreeSitter analysis on Tamarin files without requiring user intervention

# Default paths
INPUT_FILE="${1:-"$HOME/.config/nvim/test/tamarin/test.spthy"}"
OUTPUT_FILE="$HOME/temp_files/syntax_tree.txt"

# Ensure the output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "Analyzing Tamarin file: $INPUT_FILE"
echo "Output will be written to: $OUTPUT_FILE"

# Run the headless Neovim with our analyzer
nvim --headless --clean \
    -c "set rtp+=$HOME/.config/nvim" \
    -c "lua _G.input_file='$INPUT_FILE'; _G.output_file='$OUTPUT_FILE'; require('test.print_syntax_tree').analyze_to_file(_G.input_file, _G.output_file)"

# Check if the output file was created
if [ -f "$OUTPUT_FILE" ]; then
    echo "Analysis complete. Here's the output:"
    echo "=============================="
    cat "$OUTPUT_FILE"
    echo "=============================="
    echo "Output saved to: $OUTPUT_FILE"
    exit 0
else
    echo "ERROR: Analysis failed, no output file was created."
    exit 1
fi 