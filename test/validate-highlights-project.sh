#!/bin/bash

# Validation script for highlights.scm that respects the project structure
# This script checks the structural validity of the query file

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Script configuration
QUERY_FILE="queries/spthy/highlights.scm"
LOG_FILE="/tmp/query_validation.log"

echo "Tamarin TreeSitter Query Validator"
echo "--------------------------------"
echo "Validating query file: $QUERY_FILE"

# Check if the file exists
if [ ! -f "$QUERY_FILE" ]; then
  echo -e "${RED}Error: File '$QUERY_FILE' not found${NC}"
  exit 1
fi

# Clean up old log file
> "$LOG_FILE"

# Perform basic static analysis for obvious syntax errors
echo "Performing static analysis..."

# Check for balanced parentheses 
OPEN_COUNT=$(grep -o "(" "$QUERY_FILE" | wc -l | tr -d ' ')
CLOSE_COUNT=$(grep -o ")" "$QUERY_FILE" | wc -l | tr -d ' ')
echo "Opening parentheses: $OPEN_COUNT"
echo "Closing parentheses: $CLOSE_COUNT"

PARENTHESES_BALANCED=true
if [ "$OPEN_COUNT" != "$CLOSE_COUNT" ]; then
  echo -e "${RED}Error: Unbalanced parentheses detected!${NC}"
  PARENTHESES_BALANCED=false
  
  # Find lines with unbalanced parentheses
  echo "Finding problematic lines..."
  BALANCE=0
  PROBLEMATIC_LINES=""
  
  while IFS= read -r line_num line_content; do
    # Count parens in this line
    open_parens=$(echo "$line_content" | grep -o "(" | wc -l)
    close_parens=$(echo "$line_content" | grep -o ")" | wc -l)
    
    # Skip empty or comment-only lines
    if [[ "$line_content" =~ ^[[:space:]]*$ || "$line_content" =~ ^[[:space:]]*\;.* ]]; then
      continue
    fi
    
    # Update balance
    PREV_BALANCE=$BALANCE
    BALANCE=$((BALANCE + open_parens - close_parens))
    
    # If balance changed, check if it crossed zero or went further from zero
    if [ $PREV_BALANCE -ne $BALANCE ]; then
      if [ $BALANCE -lt 0 ]; then
        echo -e "${RED}Line $line_num: Too many closing parentheses${NC}"
        echo "   $line_content"
        PROBLEMATIC_LINES="$PROBLEMATIC_LINES $line_num"
      elif [ $open_parens -ne $close_parens ]; then
        echo -e "${YELLOW}Line $line_num: Unbalanced parentheses (count: $BALANCE)${NC}"
        echo "   $line_content"
      fi
    fi
  done < <(cat -n "$QUERY_FILE")
  
  echo ""
  echo -e "${YELLOW}Recommended action:${NC} Fix the parenthesis balance in the highlighted lines"
  echo ""
else
  echo -e "${GREEN}Balanced parentheses check passed.${NC}"
fi

# Check for proper capture formatting
echo "Checking capture formatting..."
CAPTURE_ERRORS=0

# Pattern for valid capture format
VALID_CAPTURE='^\s*\([^@]*\) @[a-zA-Z.]*'
# Pattern for invalid captures
INVALID_CAPTURE1='@[a-zA-Z.]*\s*\('  # @ before the node
INVALID_CAPTURE2='\)[^@]*@'          # @ after the closing parenthesis
INVALID_CAPTURE3='\(\s*@'            # @ immediately after opening paren

# Check for invalid capture patterns
while IFS= read -r line_num line_content; do
  # Skip empty or comment-only lines
  if [[ "$line_content" =~ ^[[:space:]]*$ || "$line_content" =~ ^[[:space:]]*\;.* ]]; then
    continue
  fi
  
  # Check each invalid pattern
  if [[ "$line_content" =~ $INVALID_CAPTURE1 ]]; then
    echo -e "${RED}Line $line_num: Capture marker @ should come after node type${NC}"
    echo "   $line_content"
    CAPTURE_ERRORS=$((CAPTURE_ERRORS + 1))
  fi
  
  if [[ "$line_content" =~ $INVALID_CAPTURE2 ]]; then
    echo -e "${RED}Line $line_num: Capture marker @ should be attached to the node type${NC}"
    echo "   $line_content"
    CAPTURE_ERRORS=$((CAPTURE_ERRORS + 1))
  fi
  
  if [[ "$line_content" =~ $INVALID_CAPTURE3 ]]; then
    echo -e "${RED}Line $line_num: Capture marker @ should come after a node type, not before${NC}"
    echo "   $line_content"
    CAPTURE_ERRORS=$((CAPTURE_ERRORS + 1))
  fi
done < <(cat -n "$QUERY_FILE")

if [ $CAPTURE_ERRORS -eq 0 ]; then
  echo -e "${GREEN}Capture format check passed.${NC}"
else
  echo -e "${RED}Found $CAPTURE_ERRORS potential capture formatting issues.${NC}"
  echo "Captures should be in the format: (node_type) @capture.name"
fi

# Check for proper predicate formatting
echo "Checking predicate formatting..."
PREDICATE_ERRORS=0

# Pattern for valid predicate format
VALID_PREDICATE='^\s*\(#[a-zA-Z?!]+\?'
# Pattern for invalid predicates
INVALID_PREDICATE1='#[a-zA-Z?!]+\?[^( ]'  # Predicate without opening paren
INVALID_PREDICATE2='#[a-zA-Z]+ @'        # Missing ? in predicate
INVALID_PREDICATE3='#[a-zA-Z]+ [^@]'     # Missing ? in predicate
INVALID_PREDICATE4='#match[^?]'          # Missing ? after match

# Check for invalid predicate patterns
while IFS= read -r line_num line_content; do
  # Skip empty or comment-only lines
  if [[ "$line_content" =~ ^[[:space:]]*$ || "$line_content" =~ ^[[:space:]]*\;.* ]]; then
    continue
  fi
  
  # Only process lines with predicates
  if [[ "$line_content" =~ "#" ]]; then
    # Check each invalid pattern
    if [[ "$line_content" =~ $INVALID_PREDICATE1 ]]; then
      echo -e "${RED}Line $line_num: Predicate should be followed by a capture in parentheses${NC}"
      echo "   $line_content"
      PREDICATE_ERRORS=$((PREDICATE_ERRORS + 1))
    fi
    
    if [[ "$line_content" =~ $INVALID_PREDICATE2 ]]; then
      echo -e "${RED}Line $line_num: Predicate missing ? separator${NC}"
      echo "   $line_content"
      PREDICATE_ERRORS=$((PREDICATE_ERRORS + 1))
    fi
    
    if [[ "$line_content" =~ $INVALID_PREDICATE3 ]]; then
      echo -e "${RED}Line $line_num: Predicate missing ? separator${NC}"
      echo "   $line_content"
      PREDICATE_ERRORS=$((PREDICATE_ERRORS + 1))
    fi
    
    if [[ "$line_content" =~ $INVALID_PREDICATE4 ]]; then
      echo -e "${RED}Line $line_num: Missing ? after match predicate${NC}"
      echo "   $line_content"
      PREDICATE_ERRORS=$((PREDICATE_ERRORS + 1))
    fi
  fi
done < <(cat -n "$QUERY_FILE")

if [ $PREDICATE_ERRORS -eq 0 ]; then
  echo -e "${GREEN}Predicate format check passed.${NC}"
else
  echo -e "${RED}Found $PREDICATE_ERRORS potential predicate formatting issues.${NC}"
  echo "Predicates should be in the format: (#predicate? @capture \"value\")"
fi

# Final summary
echo ""
echo "Validation Summary:"
echo "--------------------"
echo "1. Basic parenthesis count: " $([ "$OPEN_COUNT" == "$CLOSE_COUNT" ] && echo -e "${GREEN}Passed${NC}" || echo -e "${RED}Failed${NC}")
echo "2. Capture formatting: " $([ $CAPTURE_ERRORS -eq 0 ] && echo -e "${GREEN}Passed${NC}" || echo -e "${RED}Failed ($CAPTURE_ERRORS issues)${NC}")
echo "3. Predicate formatting: " $([ $PREDICATE_ERRORS -eq 0 ] && echo -e "${GREEN}Passed${NC}" || echo -e "${RED}Failed ($PREDICATE_ERRORS issues)${NC}")

# Overall validation result
if [ "$PARENTHESES_BALANCED" = true ] && [ $CAPTURE_ERRORS -eq 0 ] && [ $PREDICATE_ERRORS -eq 0 ]; then
  echo -e "\n${GREEN}Overall: Query syntax validation PASSED${NC}"
  echo "Your query file appears to be structurally valid."
  echo "Note: This only checks syntax structure, not semantic correctness."
  exit 0
else
  echo -e "\n${RED}Overall: Query syntax validation FAILED${NC}"
  echo "Please fix the highlighted issues before using this query file."
  exit 1
fi 