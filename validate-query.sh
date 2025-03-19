#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Script configuration
QUERY_FILE="${1:-queries/spthy/highlights.scm}"
LOG_FILE="/tmp/query_validation.log"

echo "TreeSitter Query Validator"
echo "-------------------------"
echo "Validating query file: $QUERY_FILE"

# Check if the file exists
if [ ! -f "$QUERY_FILE" ]; then
  echo -e "${RED}Error: File '$QUERY_FILE' not found${NC}"
  exit 1
fi

# Check for obvious syntax issues
echo "Performing static analysis..."

# Clean up old log file
> "$LOG_FILE"

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
INVALID_PREDICATE1='#[a-zA-Z?!]+\?\s*[^(]'  # Predicate without opening paren
INVALID_PREDICATE2='#[a-zA-Z?!]+\s+@'        # Missing ? in predicate

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
  fi
done < <(cat -n "$QUERY_FILE")

if [ $PREDICATE_ERRORS -eq 0 ]; then
  echo -e "${GREEN}Predicate format check passed.${NC}"
else
  echo -e "${RED}Found $PREDICATE_ERRORS potential predicate formatting issues.${NC}"
  echo "Predicates should be in the format: (#predicate? @capture \"value\")"
fi

# Perform an additional nested parentheses check
echo "Checking nested parentheses balance..."
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'EOF'
local function validate_parentheses()
  local file_path = arg[1]
  
  -- Read the query file
  local file = io.open(file_path, "r")
  if not file then
    print("Error: Could not open file: " .. file_path)
    return 1
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Strip comments to avoid false positives
  content = content:gsub(";[^\n]*", "")
  
  -- Stack-based parentheses checker
  local stack = {}
  local line = 1
  local col = 0
  local errors = {}
  
  for i = 1, #content do
    local char = content:sub(i, i)
    
    -- Track line and column
    if char == "\n" then
      line = line + 1
      col = 0
    else
      col = col + 1
    end
    
    if char == "(" then
      table.insert(stack, { char = char, line = line, col = col })
    elseif char == ")" then
      if #stack == 0 then
        table.insert(errors, { type = "unmatched_close", line = line, col = col })
      else
        table.remove(stack)
      end
    end
  end
  
  -- Check for unmatched opening parentheses
  for _, pos in ipairs(stack) do
    table.insert(errors, { type = "unmatched_open", line = pos.line, col = pos.col })
  end
  
  -- Report errors
  if #errors > 0 then
    print("Error: Found " .. #errors .. " parentheses matching errors:")
    for i, err in ipairs(errors) do
      if i <= 10 then  -- Limit to first 10 errors
        if err.type == "unmatched_open" then
          print("Unmatched opening parenthesis at line " .. err.line .. ", column " .. err.col)
        else
          print("Unmatched closing parenthesis at line " .. err.line .. ", column " .. err.col)
        end
      end
    end
    return 1
  else
    print("Success: Nested parentheses are properly balanced.")
    return 0
  end
end

os.exit(validate_parentheses())
EOF

# Run parentheses validation
nvim --headless -l "$TEMP_SCRIPT" "$QUERY_FILE" -c "qa!" 2>&1 | tee -a "$LOG_FILE"
PAREN_EXIT_CODE=${PIPESTATUS[0]}

# Cleanup
rm "$TEMP_SCRIPT"

# Final summary
echo ""
echo "Validation Summary:"
echo "--------------------"
echo "1. Basic parenthesis count: " $([ "$OPEN_COUNT" == "$CLOSE_COUNT" ] && echo -e "${GREEN}Passed${NC}" || echo -e "${RED}Failed${NC}")
echo "2. Capture formatting: " $([ $CAPTURE_ERRORS -eq 0 ] && echo -e "${GREEN}Passed${NC}" || echo -e "${RED}Failed ($CAPTURE_ERRORS issues)${NC}")
echo "3. Predicate formatting: " $([ $PREDICATE_ERRORS -eq 0 ] && echo -e "${GREEN}Passed${NC}" || echo -e "${RED}Failed ($PREDICATE_ERRORS issues)${NC}")
echo "4. Nested parentheses check: " $(grep -q "Success: Nested parentheses are properly balanced" "$LOG_FILE" && echo -e "${GREEN}Passed${NC}" || echo -e "${RED}Failed${NC}")

# Overall validation result
if [ "$OPEN_COUNT" == "$CLOSE_COUNT" ] && [ $CAPTURE_ERRORS -eq 0 ] && [ $PREDICATE_ERRORS -eq 0 ] && grep -q "Success: Nested parentheses are properly balanced" "$LOG_FILE"; then
  echo -e "\n${GREEN}Overall: Query syntax validation PASSED${NC}"
  echo "Your query file appears to be structurally valid."
  echo "Note: This only checks syntax structure, not semantic correctness."
  exit 0
else
  echo -e "\n${RED}Overall: Query syntax validation FAILED${NC}"
  echo "Please fix the highlighted issues before using this query file."
  exit 1
fi 