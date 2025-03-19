#!/bin/bash
# Simple validation script for TreeSitter query files
# This specifically targets the error the user reported

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

QUERY_FILE="queries/spthy/highlights.scm"

echo "Simple TreeSitter Query Validator"
echo "--------------------------------"
echo "Testing query file: $QUERY_FILE"

# Check for parenthesis balance
OPEN_COUNT=$(grep -o "(" "$QUERY_FILE" | wc -l | tr -d ' ')
CLOSE_COUNT=$(grep -o ")" "$QUERY_FILE" | wc -l | tr -d ' ')
echo "Opening parentheses: $OPEN_COUNT"
echo "Closing parentheses: $CLOSE_COUNT"

if [ "$OPEN_COUNT" != "$CLOSE_COUNT" ]; then
  echo -e "${RED}FAIL: Unbalanced parentheses detected${NC}"
else
  echo -e "${GREEN}PASS: Parentheses are balanced${NC}"
fi

# Check for the specific error pattern the user encountered
if grep -n "(ident)) @preproc.identifier" "$QUERY_FILE"; then
  echo -e "${RED}FAIL: Found error pattern (ident)) @preproc.identifier${NC}"
else
  echo -e "${GREEN}PASS: No error pattern found${NC}"
fi

# Test for correct preprocessor identifier pattern
if grep -n "^(preprocessor" "$QUERY_FILE" | grep -q "ident) @preproc.identifier"; then
  echo -e "${GREEN}PASS: Preprocessor pattern looks correct${NC}"
else
  echo -e "${YELLOW}WARN: Potential issue with preprocessor pattern${NC}"
  grep -n "preprocessor" "$QUERY_FILE" | grep "ident"
fi

echo ""
echo "Creating test Tamarin file..."
TEST_FILE=$(mktemp)
TEST_FILE_SPTHY="$TEST_FILE.spthy"
mv "$TEST_FILE" "$TEST_FILE_SPTHY"
TEST_FILE="$TEST_FILE_SPTHY"

cat > "$TEST_FILE" << 'EOT'
theory Test
begin

builtins: diffie-hellman

#ifdef PREPROCESSING
// This is a preprocessor test
#endif

macro MAC(k, m) = mac(m, k)

end
EOT

echo "Test file created at: $TEST_FILE"
echo "Attempting to open with Neovim..."

# Run a more realistic test
nvim --headless -c "set filetype=spthy" \
  -c "lua vim.g.tamarin_highlight_debug = true" \
  -c "lua vim.opt.rtp:prepend('$PWD')" \
  -c "source lua/config/tamarin-highlights.lua" \
  -c "lua require('config.tamarin-highlights').setup()" \
  -c "sleep 300m" \
  -c "qa!" "$TEST_FILE" 2>&1 | grep -i "error\|E5108"

EXIT_CODE=$?
if [ $EXIT_CODE -eq 1 ]; then
  # grep found errors
  echo -e "${RED}FAIL: Errors detected when loading file${NC}"
  nvim --headless -c "set filetype=spthy" \
    -c "lua vim.g.tamarin_highlight_debug = true" \
    -c "lua vim.opt.rtp:prepend('$PWD')" \
    -c "source lua/config/tamarin-highlights.lua" \
    -c "lua require('config.tamarin-highlights').setup()" \
    -c "sleep 300m" \
    -c "qa!" "$TEST_FILE" 2>&1 | grep -i "error\|E5108" || echo "No detailed error output available"
else
  echo -e "${GREEN}PASS: No errors detected when loading file${NC}"
fi

rm "$TEST_FILE"

echo ""
echo "Manual verification steps:"
echo "1. Open a .spthy file in Neovim"
echo "2. Check that the preprocessor directives (#ifdef, #endif) are highlighted properly"
echo "3. Verify the highlighting of variables in macro definitions works"
echo "4. Ensure variables with apostrophes (t', k', etc.) have proper coloring" 