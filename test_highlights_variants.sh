#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# Test file
TEST_FILE="/tmp/tamarin-highlights-test.spthy"

# Create test directory
TEST_DIR="/tmp/tamarin-debug"
mkdir -p "$TEST_DIR"

# Function to test a highlights.scm variant
test_variant() {
  local variant="$1"
  local variant_name=$(basename "$variant")
  
  echo -e "${YELLOW}Testing $variant_name...${NC}"
  
  # Copy the variant to the active highlights.scm
  cp "$variant" queries/spthy/highlights.scm
  
  # Create a test file with tamarin code including apostrophes
  cat > "$TEST_FILE" << 'EOF'
theory Test
begin

builtins: hashing, diffie-hellman

// Test variables with apostrophes
rule Test_Apostrophes:
  [ Fr(~k'), In($A'), Fr(#t') ]
  --[ TestAction(t') ]-->
  [ Out(~k'), !Store($A') ]

end
EOF
  
  # Run nvim and capture errors
  echo "Running Neovim with $variant_name..."
  LOG_FILE="$TEST_DIR/${variant_name}.log"
  
  # Clear previous logs
  rm -f "$LOG_FILE"
  
  # Run neovim headlessly with test file
  timeout 5s nvim --headless -u init.lua "$TEST_FILE" -c "qa!" 2> "$LOG_FILE" || echo "Nvim exited with code $?"
  
  # Check for errors
  if grep -q -E "treesitter|regex|parse|query|E5108|E874|stack" "$LOG_FILE"; then
    echo -e "${RED}❌ FAILED: TreeSitter errors found with $variant_name${NC}"
    echo -e "${RED}--- Error log start ---${NC}"
    grep -E "treesitter|regex|parse|query|E5108|E874|stack" "$LOG_FILE"
    echo -e "${RED}--- Error log end ---${NC}"
    FAILED_VARIANTS="$FAILED_VARIANTS $variant_name"
  else
    echo -e "${GREEN}✅ PASSED: No TreeSitter errors with $variant_name${NC}"
    PASSED_VARIANTS="$PASSED_VARIANTS $variant_name"
  fi
  
  echo ""
}

# Save the current highlights.scm
if [ -f queries/spthy/highlights.scm ]; then
  cp queries/spthy/highlights.scm queries/spthy/highlights.scm.bak
fi

# Track which variants pass and fail
PASSED_VARIANTS=""
FAILED_VARIANTS=""

# Test each variant
echo "=== Starting highlights.scm variant tests ==="
for variant in queries/spthy/highlights.scm.0*; do
  test_variant "$variant"
done

# Restore the original highlights.scm
if [ -f queries/spthy/highlights.scm.bak ]; then
  mv queries/spthy/highlights.scm.bak queries/spthy/highlights.scm
fi

# Print summary
echo "=== Test Summary ==="
echo -e "${GREEN}Passing variants:${NC}$PASSED_VARIANTS"
echo -e "${RED}Failing variants:${NC}$FAILED_VARIANTS"
echo ""
echo "Log files are in $TEST_DIR"
echo ""

# If we have a failing variant, determine which pattern causes problems
if [ -n "$FAILED_VARIANTS" ]; then
  echo "=== Analysis of Failing Variants ==="
  for variant in $FAILED_VARIANTS; do
    # Find what's in this variant but not in the preceding variant
    variant_num=${variant#*_}
    prev_num=$((10#${variant_num%_*} - 1))
    if [ $prev_num -lt 1 ]; then
      echo "Cannot analyze $variant (no preceding variant)"
      continue
    fi
    
    prev_variant="queries/spthy/highlights.scm.0${prev_num}_"*
    if [ ! -f "$prev_variant" ]; then
      echo "Cannot find preceding variant for $variant"
      continue
    fi
    
    echo "Comparing $variant with $prev_variant..."
    diff -u "$prev_variant" "queries/spthy/highlights.scm.$variant" | grep -E "^\+" | grep -v "^+++"
  done
fi 