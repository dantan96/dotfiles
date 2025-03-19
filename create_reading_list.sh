#!/bin/bash

# Script to generate and update the mandatory reading list for TreeSitter documentation
# This automatically finds all .md files in the consumables directory and creates a tracking table

OUTPUT_FILE="mandatory_reading_list.md"

# Find all markdown files in the consumables directory
MD_FILES=$(find ./consumables -name "*.md" | sort)

# Count total files
TOTAL_FILES=$(echo "$MD_FILES" | wc -l | xargs)

# If the file already exists, extract the current reading status
if [ -f "$OUTPUT_FILE" ]; then
  echo "Updating existing reading list..."
  PARTIAL_STATUS=$(grep -o '\[x\].*\[ \]' "$OUTPUT_FILE" | wc -l | xargs)
  COMPLETE_STATUS=$(grep -o '\[x\].*\[x\]' "$OUTPUT_FILE" | wc -l | xargs)
else
  echo "Creating new reading list..."
  PARTIAL_STATUS=0
  COMPLETE_STATUS=0
fi

# Generate the header of the markdown file
cat > "$OUTPUT_FILE" << EOF
# TreeSitter Mandatory Reading List

This document tracks the reading progress of TreeSitter documentation files. No changes to TreeSitter files (especially highlights.scm) should be made until all documentation has been thoroughly reviewed.

| File | Partial Reading | Complete Reading |
|------|:--------------:|:----------------:|
EOF

# Generate the table rows
for file in $MD_FILES; do
  # Check if this file already has reading status in the existing file
  if [ -f "$OUTPUT_FILE.bak" ]; then
    # Extract the status for this file if it exists
    PARTIAL_MARK="[ ]"
    COMPLETE_MARK="[ ]"
    
    grep_result=$(grep -F "$file" "$OUTPUT_FILE.bak")
    if [ ! -z "$grep_result" ]; then
      if echo "$grep_result" | grep -q '\[x\].*\[ \]'; then
        PARTIAL_MARK="[x]"
      fi
      if echo "$grep_result" | grep -q '\[x\].*\[x\]'; then
        PARTIAL_MARK="[x]"
        COMPLETE_MARK="[x]"
      fi
    fi
  else
    # For newly discovered files, set default status
    PARTIAL_MARK="[ ]"
    COMPLETE_MARK="[ ]"
    
    # Mark some files we know have been partially read
    if [[ "$file" == "./consumables/External Scanners.md" || 
          "$file" == "./consumables/Predicates and Directives.md" || 
          "$file" == "./consumables/Writing the Grammar.md" ]]; then
      PARTIAL_MARK="[x]"
    fi
  fi
  
  echo "| $file | $PARTIAL_MARK | $COMPLETE_MARK |" >> "$OUTPUT_FILE"
done

# Calculate progress statistics
if [ -f "$OUTPUT_FILE.bak" ]; then
  PARTIAL_COUNT=$(grep -o '\[x\].*\[ \]' "$OUTPUT_FILE" | wc -l | xargs)
  COMPLETE_COUNT=$(grep -o '\[x\].*\[x\]' "$OUTPUT_FILE" | wc -l | xargs)
else
  PARTIAL_COUNT=3  # Starting with 3 partially read files
  COMPLETE_COUNT=0
fi

PROGRESS_PCT=$(echo "scale=1; 100 * $COMPLETE_COUNT / $TOTAL_FILES" | bc)

# Add the progress section
cat >> "$OUTPUT_FILE" << EOF

## Reading Progress
- Files partially read: $PARTIAL_COUNT/$TOTAL_FILES
- Files completely read: $COMPLETE_COUNT/$TOTAL_FILES
- Progress: $PROGRESS_PCT%

## Notes
- Files will be marked as "partially read" when they've been skimmed for key information
- Files will be marked as "completely read" only when they've been thoroughly studied and fully understood
EOF

echo "Reading list updated: $OUTPUT_FILE"
echo "Progress: $PROGRESS_PCT% complete" 