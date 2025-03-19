#!/bin/bash
TEST_DIR="/tmp/tamarin-test"
mkdir -p "$TEST_DIR"

# Create backup of current highlights.scm
cp ~/.config/nvim/queries/spthy/highlights.scm ~/.config/nvim/queries/spthy/highlights.scm.bak

# Create a test file with apostrophes
cat > "$TEST_DIR/apostrophe.spthy" << 'EOT'
theory Test
begin

builtins: hashing

rule Test_Apostrophes:
  [ Fr(~k'), In($A'), Fr(#t') ]
  --[ Action(t') ]-->
  [ Out(~k'), !Store($A') ]

end
EOT

echo "Created test Tamarin file with apostrophes"

# Test with the current highlights.scm
echo "Testing with current highlights.scm..."
timeout 5s nvim --headless -u ~/.config/nvim/init.lua "$TEST_DIR/apostrophe.spthy" -c "qa!" 2> "$TEST_DIR/current.log" || echo "Nvim exited with code $?"

if grep -q -E "treesitter|regex|parse|query|error|stack" "$TEST_DIR/current.log"; then
  echo "❌ FAILED: TreeSitter errors found:"
  grep -E "treesitter|regex|parse|query|error|stack" "$TEST_DIR/current.log"
else
  echo "✅ PASSED: No TreeSitter errors"
fi

# Create simplified version (no regex patterns)
cat > "$TEST_DIR/highlights.scm.simplified" << 'EOT'
;; Simplified Tamarin Protocol Specification Highlighting
;; Removed complex regex patterns

;; Core Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "lemma"
  "builtins"
  "functions"
] @keyword

;; Comments
(multi_comment) @comment
(single_comment) @comment

;; Theory structure
(theory
  theory_name: (ident) @type)

;; Functions
(function_untyped) @function
(nullary_fun) @function

;; Facts
(linear_fact) @fact.linear
(persistent_fact) @fact.persistent
(action_fact) @fact.action

;; Variable types
(pub_var) @variable.public
(fresh_var) @variable.fresh
(temporal_var) @variable.temporal
(msg_var_or_nullary_fun) @variable.message

;; Constants and numbers
(natural) @number
(param) @string
EOT

# Test with simplified version
cp "$TEST_DIR/highlights.scm.simplified" ~/.config/nvim/queries/spthy/highlights.scm
echo "Testing with simplified highlights.scm..."
timeout 5s nvim --headless -u ~/.config/nvim/init.lua "$TEST_DIR/apostrophe.spthy" -c "qa!" 2> "$TEST_DIR/simplified.log" || echo "Nvim exited with code $?"

if grep -q -E "treesitter|regex|parse|query|error|stack" "$TEST_DIR/simplified.log"; then
  echo "❌ FAILED: TreeSitter errors found with simplified version:"
  grep -E "treesitter|regex|parse|query|error|stack" "$TEST_DIR/simplified.log"
else
  echo "✅ PASSED: No TreeSitter errors with simplified version"
fi

# Restore original highlights.scm
mv ~/.config/nvim/queries/spthy/highlights.scm.bak ~/.config/nvim/queries/spthy/highlights.scm

echo "Tests completed" 