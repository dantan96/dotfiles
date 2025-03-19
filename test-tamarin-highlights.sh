#!/bin/bash

# Test script for Tamarin syntax highlighting in Neovim
# This creates a temporary .spthy file with all the elements we need to test and
# opens it in Neovim for visual inspection

# Create a temporary file for testing
# macOS-compatible version
TEST_FILE=$(mktemp)
TEST_FILE_SPTHY="$TEST_FILE.spthy"
mv "$TEST_FILE" "$TEST_FILE_SPTHY"
TEST_FILE="$TEST_FILE_SPTHY"
echo "Creating test file at: $TEST_FILE"

# Sample Tamarin code with all the features we need to test
cat > $TEST_FILE << 'EOL'
theory TestHighlighting
begin

builtins: diffie-hellman, symmetric-encryption, hashing

functions: f/2, g/1, mac/2, h/1, pk/1
private functions: priv/1

/* Comment test */
// Another comment test

#ifdef PREPROCESSING
// This is preprocessor content
#endif

rule Test_Rule:
  let 
    t' = MAC(k, m)
    x = kdf(~k, $A)
    y = PK($A)
  in
  [ Fr(~k), In(x) ]
  --[ Action() ]->
  [ Out(senc(m, k)), !Persistent(~k) ]

lemma Test_Lemma:
  "All #i. Action()@i ==> Ex y. K(y)@i"
  
restriction Test_Restriction:
  "All a b #i. A(a, b)@i ==> B(a)@i"

macro MAC(k, m) = mac(m, k)
macro KDF(k, n) = kdf(k, n)
macro PK($A) = pk($A)

/* Test variables with apostrophes */
rule Variable_Apostrophes:
  [
    Fr(~k'), In($A'), Fr(#t')
  ]
  --[ TestAction(t') ]->
  [
    Out(~k'), !Store($A')
  ]

end
EOL

# Run Neovim in headless mode with the test file
echo "Opening file in Neovim (headless mode)..."
nvim --headless -c "set filetype=spthy" -c "source lua/config/tamarin-highlights.lua" -c "lua require('config.tamarin-highlights').setup()" -c "lua vim.g.tamarin_highlight_debug = true" $TEST_FILE -c "sleep 1" -c "qa!" 2>&1

echo "To manually inspect highlighting, run:"
echo "nvim $TEST_FILE"
echo ""
echo "Look for these specific test cases:"
echo "1. Preprocessor directives (#ifdef, #endif) should be muted purple"
echo "2. PREPROCESSING identifier should be muted purple"
echo "3. Variables in macro definitions (k, m, n, $A) should be properly colored"
echo "4. Variables with apostrophes (t', k', A', etc.) should be colored according to their type"
echo "5. Macro names (MAC, KDF, PK) should be consistent with calls"
echo "6. The $ in $A should have the same color as the A"
echo "7. Built-in functions (senc, mac) should be properly highlighted"

# Keep the file around for manual inspection
echo ""
echo "Test file created at: $TEST_FILE"
echo "To clean up, run: rm $TEST_FILE"
