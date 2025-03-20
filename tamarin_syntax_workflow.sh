#!/bin/bash

# tamarin_syntax_workflow.sh
# Complete workflow script for validating and improving Tamarin syntax highlighting

# Set colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE}   Tamarin Syntax Highlighting Validation Workflow      ${NC}"
echo -e "${BLUE}========================================================${NC}"
echo ""

# Step 1: Run the validation script
echo -e "${YELLOW}Step 1: Running syntax highlighting validation...${NC}"
echo "-----------------------------------------------"
./validate_highlighting.sh

# Check if validation produced results
if [ ! -f "syntax_validation_results.md" ]; then
  echo -e "${RED}Error: Validation did not produce results file.${NC}"
  exit 1
fi

# Step 2: Analyze results and generate suggestions
echo ""
echo -e "${YELLOW}Step 2: Analyzing results and generating suggestions...${NC}"
echo "-------------------------------------------------------"
nvim --headless -u NONE -c "luafile update_highlights.lua" > analysis_output.txt 2>&1

# Check if analysis was successful
if [ $? -eq 0 ]; then
  cat analysis_output.txt
  
  # Check if suggestions were generated
  if [ -f "treesitter_suggestions.md" ]; then
    echo ""
    echo -e "${GREEN}Suggestions have been generated in treesitter_suggestions.md${NC}"
  else
    echo -e "${RED}No suggestions file was generated.${NC}"
  fi
else
  echo -e "${RED}Error analyzing results:${NC}"
  cat analysis_output.txt
  exit 1
fi

# Step 3: Summary and next steps
echo ""
echo -e "${YELLOW}Step 3: Summary and next steps${NC}"
echo "----------------------------"
echo -e "${GREEN}✓${NC} Syntax highlighting validation completed"
echo -e "${GREEN}✓${NC} Analysis of TreeSitter captures completed"
echo ""
echo "To apply suggested changes:"
echo "1. Review the suggestions in treesitter_suggestions.md"
echo "2. Edit /Users/dan/.config/nvim/queries/spthy/highlights.scm"
echo "3. Run this workflow again to validate improvements"
echo ""
echo -e "${BLUE}==========================================================${NC}" 