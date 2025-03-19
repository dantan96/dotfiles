#!/bin/bash

# Script to run tests for TreeSitter regex patterns

# Set up the test directory
TEST_DIR="./consumables/test"
mkdir -p "$TEST_DIR/results"

echo "==== TreeSitter Regex Pattern Testing ===="
echo "Running tests in $TEST_DIR"

# Run the test regex patterns with nvim
echo "Testing regex patterns with nvim..."
nvim --headless -c "luafile $TEST_DIR/run_regex_tests.lua" -c "q"

# Analyze highlights.scm if it exists
if [ -f "$(nvim --headless -c 'echo stdpath("config") . "/queries/spthy/highlights.scm"' -c 'q' 2>&1)" ]; then
  echo "Analyzing spthy highlights.scm..."
  nvim --headless -c "luafile $TEST_DIR/test_highlights_scm.lua" -c "q"
elif [ -f "$(nvim --headless -c 'echo stdpath("config") . "/queries/tamarin/highlights.scm"' -c 'q' 2>&1)" ]; then
  echo "Analyzing tamarin highlights.scm..."
  nvim --headless -c "luafile $TEST_DIR/test_highlights_scm.lua" -c "q"
else
  echo "Could not find highlights.scm file. Skipping analysis."
fi

# Create a simplified highlights.scm file
echo "Creating simplified highlights.scm file..."
cat > "$TEST_DIR/simplified_highlights.scm" << 'EOF'
;; Simplified Tamarin Syntax Highlighting
;; Based on TreeSitter query patterns that avoid regex stack overflow

;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "let"
  "in"
  "functions"
  "equations"
  "builtins"
  "lemma"
  "axiom"
  "restriction"
  "protocol"
  "property"
  "all"
  "exists"
  "or"
  "and"
  "not"
  "if"
  "then"
  "else"
  "subsection"
  "section"
  "text"
] @keyword

;; Basic types
(string) @string
(comment) @comment
(number) @number

;; Functions and variables - simple captures without complex regex
(function_declaration name: (identifier) @function)
(function_call name: (identifier) @function.call)
(variable) @variable

;; Operators
[
  "="
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "+"
  "-"
  "*"
  "/"
  "^"
] @operator

;; Delimiters
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  ","
  ";"
  ":"
] @delimiter

;; Special identifiers - safe pattern matching
;; Use simple predicates instead of complex regex
((identifier) @constant
 (#match? @constant "^[A-Z][A-Z0-9_]*$"))

;; Variables with apostrophes - using safe patterns
((variable) @variable.prime
 (#match? @variable.prime "'$"))
EOF

echo "Tests completed. Check the following files for results:"
echo "- $TEST_DIR/regex_test_results.md"
echo "- $TEST_DIR/highlights_analysis_report.md"
echo "- $TEST_DIR/simplified_highlights.scm" 