#!/bin/bash

# Test script to validate TreeSitter queries for syntax errors
# This script helps catch issues with TreeSitter query files before they're applied

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "TreeSitter Query Validator"
echo "-------------------------"

# Check if the query file exists
if [ "$1" == "" ]; then
  echo -e "${YELLOW}Usage: $0 <path-to-query-file>${NC}"
  echo "Example: $0 queries/spthy/highlights.scm"
  exit 1
fi

QUERY_FILE="$1"

if [ ! -f "$QUERY_FILE" ]; then
  echo -e "${RED}Error: File '$QUERY_FILE' not found${NC}"
  exit 1
fi

echo "Validating query file: $QUERY_FILE"

# Perform basic static analysis for obvious syntax errors
echo "Performing static analysis..."

# Check for unbalanced parentheses
OPENING_PARENS=$(grep -o "(" "$QUERY_FILE" | wc -l)
CLOSING_PARENS=$(grep -o ")" "$QUERY_FILE" | wc -l)

if [ "$OPENING_PARENS" != "$CLOSING_PARENS" ]; then
  echo -e "${RED}Error: Unbalanced parentheses detected!${NC}"
  echo "Opening parentheses: $OPENING_PARENS"
  echo "Closing parentheses: $CLOSING_PARENS"
  echo ""
  echo "This will definitely cause TreeSitter query parsing errors."
  
  # Advanced parenthesis check - find problematic lines
  echo -e "${YELLOW}Lines with possible parenthesis issues:${NC}"
  
  # Create a temporary file to track parenthesis balance
  TEMP_CHECK=$(mktemp)
  cat "$QUERY_FILE" | nl -ba | while read -r line_num line_content; do
    # Count parentheses in this line
    open_count=$(echo "$line_content" | tr -cd '(' | wc -c)
    close_count=$(echo "$line_content" | tr -cd ')' | wc -c)
    
    # Line-level balance check
    if [[ $open_count -ne $close_count && ($open_count -gt 0 || $close_count -gt 0) ]]; then
      echo "$line_num: $line_content" >> "$TEMP_CHECK"
    fi
  done
  
  # Show found issues
  if [ -s "$TEMP_CHECK" ]; then
    cat "$TEMP_CHECK"
  else
    echo "Could not identify specific lines. The issue may span multiple lines."
  fi
  
  rm "$TEMP_CHECK"
  echo ""
else
  echo -e "${GREEN}Parenthesis check passed!${NC}"
fi

# Check for invalid capture patterns
echo "Checking for common capture pattern issues..."
INVALID_CAPTURES=$(grep -n '@[a-zA-Z0-9_.]*[^)]' "$QUERY_FILE" | grep -v '#' | grep -v ';' || echo "")
if [ ! -z "$INVALID_CAPTURES" ]; then
  echo -e "${RED}Possible invalid capture patterns found:${NC}"
  echo "$INVALID_CAPTURES"
  echo ""
fi

# Create a minimal test file for the language
TEST_FILE=$(mktemp)
echo "test" > "$TEST_FILE"

# Extract the language from the query file path
LANG=$(echo "$QUERY_FILE" | sed -n 's/.*queries\/\([^\/]*\)\/.*/\1/p')

if [ -z "$LANG" ]; then
  echo -e "${YELLOW}Warning: Could not determine language from path. Using 'spthy' as default.${NC}"
  LANG="spthy"
else
  echo "Detected language: $LANG"
fi

# Run nvim with the query file in a headless mode to check for errors
echo "Running syntax validation..."
ERROR_OUTPUT=$(nvim --headless -c "lua print(vim.treesitter.query.parse('$LANG', io.open('$QUERY_FILE', 'r'):read('*all')))" -c "qa!" 2>&1)

# Check if there were any errors
if echo "$ERROR_OUTPUT" | grep -q "Query error"; then
  echo -e "${RED}Validation failed. Query syntax errors detected:${NC}"
  echo "$ERROR_OUTPUT" | grep "Query error" -A 3
  
  # Try to extract the error location
  ERROR_LINE=$(echo "$ERROR_OUTPUT" | grep -o "at [0-9]*:[0-9]*" | head -1)
  if [ ! -z "$ERROR_LINE" ]; then
    LINE_NUM=$(echo "$ERROR_LINE" | cut -d ":" -f 1 | cut -d " " -f 2)
    COL_NUM=$(echo "$ERROR_LINE" | cut -d ":" -f 2)
    
    echo -e "${YELLOW}Error location: Line $LINE_NUM, Column $COL_NUM${NC}"
    
    # Show the problematic line and surrounding context
    echo -e "${YELLOW}Context:${NC}"
    START_LINE=$((LINE_NUM - 3))
    if [ $START_LINE -lt 1 ]; then START_LINE=1; fi
    END_LINE=$((LINE_NUM + 3))
    
    sed -n "${START_LINE},${END_LINE}p" "$QUERY_FILE" | nl -v $START_LINE | while read line; do
      CURRENT_LINE=$(echo "$line" | awk '{print $1}')
      if [ "$CURRENT_LINE" -eq "$LINE_NUM" ]; then
        echo -e "${RED}$line${NC}"
        # Print a caret at the error position
        PADDING=$(echo "$line" | cut -c1-$((5 + COL_NUM)) | sed 's/./ /g')
        echo -e "${RED}$PADDING^--- Possible error here${NC}"
      else
        echo "$line"
      fi
    done
    
    # Extract the exact reported pattern causing the error
    ERROR_PATTERN=$(echo "$ERROR_OUTPUT" | grep -o "Impossible pattern:.*" | cut -d ":" -f 2- | tr -d '\n')
    if [ ! -z "$ERROR_PATTERN" ]; then
      echo -e "${YELLOW}Error pattern:${NC} $ERROR_PATTERN"
      
      # Try to suggest a fix
      echo -e "${YELLOW}Possible fix:${NC}"
      # Check for common issues and suggest fixes
      if echo "$ERROR_PATTERN" | grep -q ".*)).*@"; then
        echo "You might have an extra closing parenthesis. Try removing one of the ')' characters."
      elif echo "$ERROR_PATTERN" | grep -q ".*@.*))"; then
        echo "You might have an extra closing parenthesis. Ensure your capture pattern has balanced parentheses."
      elif echo "$ERROR_PATTERN" | grep -q "(.*@"; then
        echo "The capture marker '@' should come after the node pattern. Example: (node) @capture"
      fi
    fi
    
    echo ""
    echo -e "${YELLOW}Tips for fixing TreeSitter query errors:${NC}"
    echo "1. Check for unbalanced parentheses"
    echo "2. Verify node types exist in the grammar"
    echo "3. Ensure captures have correct format: (node) @capture.name"
    echo "4. Predicates need properly formatted parameters: (#match? @capture \"regex\")"
  fi
  
  exit 1
else
  echo -e "${GREEN}Query syntax validation successful!${NC}"
fi

# Clean up
rm "$TEST_FILE"

echo ""
echo "Additional validation for Neovim integration..."

# Test loading the file with Neovim's treesitter module in a more realistic way
# Including more initialization to better simulate a real user environment
echo "Testing with full Neovim initialization (may take longer)..."
ERROR_OUTPUT2=$(nvim --headless -c "source lua/config/tamarin-highlights.lua" -c "lua require('config.tamarin-highlights').setup()" -c "lua vim.treesitter.start()" -c "lua vim.g.tamarin_highlight_debug = true" -c "set filetype=$LANG" -c "lua vim.treesitter.parse_query('$LANG', io.open('$QUERY_FILE', 'r'):read('*all'))" -c "qa!" 2>&1)

if echo "$ERROR_OUTPUT2" | grep -q "Error\|error\|Exception"; then
  echo -e "${RED}Issues detected when loading into Neovim:${NC}"
  echo "$ERROR_OUTPUT2" | grep -i "Error\|error\|Exception" -A 3
  exit 1
else
  echo -e "${GREEN}Neovim integration test passed!${NC}"
fi

# Try with a real file and run in a way that simulates user's environment with plugins
echo "Running final validation with real file..."

# Create a test file with actual language content
echo "Creating a test Tamarin file..."
TEST_REAL_FILE=$(mktemp)
TEST_REAL_FILE_SPTHY="$TEST_REAL_FILE.spthy"
mv "$TEST_REAL_FILE" "$TEST_REAL_FILE_SPTHY"
TEST_REAL_FILE="$TEST_REAL_FILE_SPTHY"

# Add some realistic test content
cat > "$TEST_REAL_FILE" << 'EOF'
theory Test
begin

builtins: diffie-hellman, symmetric-encryption

functions: f/2, mac/2, kdf/2, pk/1
private functions: priv/1

#ifdef PREPROCESSING
// This is a preprocessor test
#endif

rule Test_Rule:
  let 
    t' = MAC(k, m)
    x = kdf(~k, $A)
  in
  [ Fr(~k) ]
  --[ Action() ]->
  [ Out(mac(m, k)) ]

end
EOF

# Run with more thorough initialization
ERROR_OUTPUT3=$(nvim --headless "$TEST_REAL_FILE" -c "set filetype=spthy" -c "source lua/config/tamarin-highlights.lua" -c "lua require('config.tamarin-highlights').setup()" -c "sleep 500m" -c "qa!" 2>&1)

if echo "$ERROR_OUTPUT3" | grep -q "E5108\|Query error"; then
  echo -e "${RED}Issues detected with real file test:${NC}"
  echo "$ERROR_OUTPUT3" | grep -i "E5108\|Query error" -A 3
  rm "$TEST_REAL_FILE"
  exit 1
else
  echo -e "${GREEN}Real file test passed!${NC}"
fi

# Clean up
rm "$TEST_REAL_FILE"

echo -e "${GREEN}All validation tests passed!${NC}"
echo ""
echo "You can safely use this query file in your Neovim configuration." 