#!/bin/bash

# Script to find and analyze working TreeSitter query files
# H20: Keyword vs Node Type Confusion

echo "=== H20: Finding and analyzing TreeSitter query files ==="
echo

# Find highlight.scm files in Neovim runtime
echo "Finding highlight.scm files in Neovim runtime directory..."
RUNTIME_DIR="/usr/local/Cellar/neovim/0.10.4/share/nvim/runtime"
echo "Runtime directory: $RUNTIME_DIR"

HIGHLIGHT_FILES=$(find "$RUNTIME_DIR/queries" -name "highlights.scm" | head -5)

# Create output directory
mkdir -p "$(dirname "$0")/examples"
OUTPUT_DIR="$(dirname "$0")/examples"

# Analyze each file
echo "Analyzing up to 5 highlight.scm files..."
for file in $HIGHLIGHT_FILES; do
  lang=$(echo "$file" | awk -F/ '{print $(NF-1)}')
  echo
  echo "Language: $lang"
  echo "File: $file"
  
  # Extract and count keyword blocks - look for patterns like:
  # [
  #   "keyword1"
  #   "keyword2"
  # ] @keyword
  KEYWORD_BLOCKS=$(grep -A 20 -B 1 '@keyword' "$file" | grep -v "@keyword" | grep -E '^\s*"[^"]*"' | wc -l)
  echo "Keyword entries: $KEYWORD_BLOCKS"
  
  # Check for node type references (no quotes)
  NODE_TYPES=$(grep -E '\([a-z_]+\)' "$file" | wc -l)
  echo "Node type references: $NODE_TYPES"
  
  # Copy example to output directory
  cp "$file" "$OUTPUT_DIR/${lang}_highlights.scm"
  
  # Find a simple keyword section to use as example
  KEYWORD_SECTION=$(grep -A 20 -B 1 '@keyword' "$file" | head -20)
  echo
  echo "Example keyword section:"
  echo "$KEYWORD_SECTION"
  echo
  echo "-----------------------------------------------"
done

echo
echo "Copied example files to: $OUTPUT_DIR"
echo
echo "Analysis complete" 