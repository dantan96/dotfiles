#!/bin/bash

# Simple test script for Tamarin highlights.scm
# This respects the existing configuration and only tests our changes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

TEST_FILE="/tmp/test-tamarin.spthy"

echo -e "${YELLOW}Creating test file with relevant syntax...${NC}"
cat > $TEST_FILE << 'EOT'
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
EOT

# Run nvim with the test file
echo -e "${YELLOW}Running Neovim to verify highlights.scm...${NC}"
echo "Look for these specific elements in the file:"
echo "1. Variables with apostrophes (t', k', etc.)"
echo "2. Preprocessor directives (#ifdef, #endif)"
echo "3. Macro parameters"
echo ""
echo -e "${GREEN}Press Enter to open the test file in Neovim...${NC}"
read

# Open nvim with the test file
nvim $TEST_FILE

# Cleanup
echo ""
echo -e "${YELLOW}Cleaning up...${NC}"
rm $TEST_FILE

echo -e "${GREEN}Test completed. Please verify that:${NC}"
echo "1. Variables with apostrophes are highlighted correctly"
echo "2. Preprocessor directives are highlighted properly"
echo "3. Macro parameters have proper variable type colors" 