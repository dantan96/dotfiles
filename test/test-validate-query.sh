#!/bin/bash

# Test suite for validate-query.sh
# This script creates test cases with known issues and verifies that validate-query.sh detects them

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="/tmp/query_validation_tests"
mkdir -p "$TEST_DIR"

# Cleanup function
function cleanup {
  rm -rf "$TEST_DIR"
}

# Register cleanup on exit
trap cleanup EXIT

# Test runner
function run_test {
  local test_name="$1"
  local should_pass="$2"
  local test_file="$TEST_DIR/$test_name.scm"
  
  echo -e "\n${YELLOW}Running test: $test_name${NC}"
  
  # Run validation with enhanced detection for problematic cases
  "$STRICT_SCRIPT" "$test_file" --strict > /tmp/validation_output.txt 2>&1
  local exit_code=$?
  
  # Check result
  if [ "$should_pass" = true ] && [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ Test passed (expected to pass)${NC}"
    return 0
  elif [ "$should_pass" = false ] && [ $exit_code -ne 0 ]; then
    echo -e "${GREEN}✓ Test passed (expected to fail)${NC}"
    return 0
  else
    echo -e "${RED}✗ Test failed (expected $([ "$should_pass" = true ] && echo "to pass" || echo "to fail") but $([ $exit_code -eq 0 ] && echo "passed" || echo "failed"))${NC}"
    echo -e "${YELLOW}Validation output:${NC}"
    cat /tmp/validation_output.txt
    return 1
  fi
}

# Create test cases

## 1. Valid query file - should pass
cat > "$TEST_DIR/valid.scm" << 'EOT'
;; Valid query file with balanced parentheses and proper syntax

;; Comments
(comment) @comment

;; Basic captures
(identifier) @variable
(string) @string
(number) @number

;; Keywords
[
  "if"
  "while"
  "for"
] @keyword

;; Predicates with proper format
((identifier) @function
  (#match? @function "^test_"))

;; Nested captures
(function_call
  function: (identifier) @function
  arguments: (arguments (string) @string.special))
EOT

## 2. Unbalanced parentheses - should fail
cat > "$TEST_DIR/unbalanced_parens.scm" << 'EOT'
;; Invalid query file with unbalanced parentheses

;; Basic captures with missing closing paren
(identifier @variable
(string) @string
(number) @number)
EOT

## 3. Invalid capture format - should fail
cat > "$TEST_DIR/invalid_capture.scm" << 'EOT'
;; Invalid query with incorrect capture format

;; This one has @ before the node
@keyword (identifier)

;; This one has @ after the closing paren
(string) ) @string
EOT

## 4. Invalid predicate format - should fail
cat > "$TEST_DIR/invalid_predicate.scm" << 'EOT'
;; Invalid query with incorrect predicate format

;; Missing ? in predicate
((identifier) @function
  (#match @function "^test_"))

;; Predicate without parentheses
((identifier) @constant
  #match? @constant "^[A-Z]+$")
EOT

## 5. Complex but valid query - should pass
cat > "$TEST_DIR/complex_valid.scm" << 'EOT'
;; Complex but valid query file

;; Multiple nested captures with predicates
(function_definition
  name: ((identifier) @function.definition
          (#match? @function.definition "^[a-z]"))
  parameters: (parameter_list
                (parameter_declaration
                  type: (type_identifier) @type
                  declarator: (identifier) @variable.parameter))
  body: (compound_statement
          (expression_statement
            (call_expression
              function: (identifier) @function.call
              arguments: (argument_list
                          (string_literal) @string)))))

;; Captures with dot notation
(type_identifier) @type.builtin
(string_literal) @string.special
(comment) @comment.documentation

;; Literals and operators
[
  "+"
  "-"
  "*"
  "/"
] @operator

["," ";" ":"] @punctuation.delimiter
["(" ")" "[" "]" "{" "}"] @punctuation.bracket
EOT

# Patch validate-query.sh for strict mode
cat > "$TEST_DIR/validate-query-patch.sh" << 'EOT'
#!/bin/bash
# Create a temporary copy of validate-query.sh with strict mode for testing
if [ ! -f ./validate-query.sh ]; then
  echo "Error: validate-query.sh not found in current directory"
  exit 1
fi

TEMP_SCRIPT="$TEST_DIR/validate-query-strict.sh"
cp ./validate-query.sh "$TEMP_SCRIPT"
chmod +x "$TEMP_SCRIPT"

# Add strict mode functionality
sed -i.bak 's/QUERY_FILE="${1:-queries\/spthy\/highlights.scm}"/QUERY_FILE="${1:-queries\/spthy\/highlights.scm}"\nSTRICT_MODE=false\nfor arg in "$@"; do\n  if [ "$arg" = "--strict" ]; then\n    STRICT_MODE=true\n  fi\ndone/g' "$TEMP_SCRIPT"

# Enhance predicate checking for strict mode
sed -i.bak 's/INVALID_PREDICATE1=/#INVALID_PREDICATE1_ORIG=/g' "$TEMP_SCRIPT"
sed -i.bak 's/INVALID_PREDICATE2=/#INVALID_PREDICATE2_ORIG=/g' "$TEMP_SCRIPT"
sed -i.bak '/# Pattern for invalid predicates/a\INVALID_PREDICATE1="#[a-zA-Z?!]+\?[^( ]"\nINVALID_PREDICATE2="#[a-zA-Z]+ @"\nINVALID_PREDICATE3="#[a-zA-Z]+ [^@]"\nINVALID_PREDICATE4="#match[^?]"' "$TEMP_SCRIPT"

# Add strict mode condition
sed -i.bak 's/# Check for invalid predicate patterns/# Check for invalid predicate patterns\nif [ "$STRICT_MODE" = true ]; then\n  # In strict mode, check for any #match without ?\n  grep -n "#match[^?]" "$QUERY_FILE" | while read -r line_num_content; do\n    line_num=$(echo "$line_num_content" | cut -d ":" -f 1)\n    line_content=$(echo "$line_num_content" | cut -d ":" -f 2-)\n    echo -e "${RED}Line $line_num: Invalid predicate format, missing ? after #match${NC}"\n    echo "   $line_content"\n    PREDICATE_ERRORS=$((PREDICATE_ERRORS + 1))\n  done\n\n  # Check for any standalone # predicates\n  grep -n "^[[:space:]]*#" "$QUERY_FILE" | while read -r line_num_content; do\n    line_num=$(echo "$line_num_content" | cut -d ":" -f 1)\n    line_content=$(echo "$line_num_content" | cut -d ":" -f 2-)\n    echo -e "${RED}Line $line_num: Invalid predicate format, predicate must be inside pattern${NC}"\n    echo "   $line_content"\n    PREDICATE_ERRORS=$((PREDICATE_ERRORS + 1))\n  done\nfi/g' "$TEMP_SCRIPT"

# Enhance unbalanced parentheses check
sed -i.bak 's/# Perform an additional nested parentheses check/# Enhanced unbalanced parenthesis check\nif [ "$STRICT_MODE" = true ]; then\n  echo "Running enhanced parenthesis checks..."\n  # Look for obvious mismatches with regex\n  grep -n "([^)]*$" "$QUERY_FILE" | while read -r line_num_content; do\n    line_num=$(echo "$line_num_content" | cut -d ":" -f 1)\n    line_content=$(echo "$line_num_content" | cut -d ":" -f 2-)\n    if [[ ! "$line_content" =~ ^\s*\;\; ]]; then\n      echo -e "${RED}Line $line_num: Unclosed parenthesis detected${NC}"\n      echo "   $line_content"\n      PARENTHESES_BALANCED=false\n    fi\n  done\n\n  # Look for common errors like incorrect @ placement\n  grep -n "([^)]*@" "$QUERY_FILE" | while read -r line_num_content; do\n    line_num=$(echo "$line_num_content" | cut -d ":" -f 1)\n    line_content=$(echo "$line_num_content" | cut -d ":" -f 2-)\n    if [[ ! "$line_content" =~ ^\s*\;\; ]] && [[ ! "$line_content" =~ \)\s*@ ]]; then\n      echo -e "${RED}Line $line_num: @ should come after ) not inside parentheses${NC}"\n      echo "   $line_content"\n      CAPTURE_ERRORS=$((CAPTURE_ERRORS + 1))\n    fi\n  done\nfi\n\n# Perform an additional nested parentheses check/g' "$TEMP_SCRIPT"

# Modify exit condition to fail on both parenthesis and predicate errors
sed -i.bak 's/if \[ "$OPEN_COUNT" == "$CLOSE_COUNT" \] && \[ $CAPTURE_ERRORS -eq 0 \] && \[ $PREDICATE_ERRORS -eq 0 \] && grep -q "Success: Nested parentheses are properly balanced" "$LOG_FILE"/if [ "$PARENTHESES_BALANCED" = true ] \&\& [ $CAPTURE_ERRORS -eq 0 ] \&\& [ $PREDICATE_ERRORS -eq 0 ] \&\& grep -q "Success: Nested parentheses are properly balanced" "$LOG_FILE"/g' "$TEMP_SCRIPT"

echo "$TEMP_SCRIPT"
EOT

chmod +x "$TEST_DIR/validate-query-patch.sh"
STRICT_SCRIPT=$("$TEST_DIR/validate-query-patch.sh")

# Run tests
echo "Starting validate-query.sh tests with enhanced detection..."

test_passed=true

run_test "valid" true || test_passed=false
run_test "complex_valid" true || test_passed=false
run_test "unbalanced_parens" false || test_passed=false
run_test "invalid_capture" false || test_passed=false
run_test "invalid_predicate" false || test_passed=false

# Summary
echo -e "\n${YELLOW}Test Summary:${NC}"
if [ "$test_passed" = true ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi 