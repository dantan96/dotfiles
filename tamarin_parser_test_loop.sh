#!/bin/bash

# tamarin_parser_test_loop.sh
# Script to run Tamarin parser tests and fixes in a rapid feedback loop

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_color() {
  color=$1
  message=$2
  echo -e "${color}${message}${NC}"
}

# Function to run a test
run_test() {
  test_file=$1
  print_color "$BLUE" "Running test: $test_file"
  nvim --headless -l "$test_file"
  
  # Check result
  if [ $? -eq 0 ]; then
    print_color "$GREEN" "✓ Test passed: $test_file"
    return 0
  else
    print_color "$RED" "✗ Test failed: $test_file"
    return 1
  fi
}

# Function to run a fix
run_fix() {
  fix_file=$1
  print_color "$YELLOW" "Running fix: $fix_file"
  nvim --headless -l "$fix_file"
  
  # Check result
  if [ $? -eq 0 ]; then
    print_color "$GREEN" "✓ Fix completed successfully: $fix_file"
    return 0
  else
    print_color "$RED" "✗ Fix failed: $fix_file"
    return 1
  fi
}

# Main loop
print_color "$CYAN" "=== Tamarin Parser Test and Fix Loop ==="
print_color "$BLUE" "Press Ctrl+C to exit"

iteration=1

while true; do
  print_color "$CYAN" "=== Iteration $iteration ==="
  
  # Run the enhanced parser test
  run_test "enhanced_parser_test.lua"
  test_result=$?
  
  # If test failed, run the fix
  if [ $test_result -ne 0 ]; then
    print_color "$YELLOW" "Test failed, running fix..."
    run_fix "fix_tamarin_parser.lua"
    fix_result=$?
    
    # Run test again to see if the fix worked
    if [ $fix_result -eq 0 ]; then
      print_color "$BLUE" "Running test again to verify fix..."
      run_test "enhanced_parser_test.lua"
      
      if [ $? -eq 0 ]; then
        print_color "$GREEN" "✓ Fix was successful!"
      else
        print_color "$RED" "✗ Fix did not resolve all issues"
      fi
    fi
  else
    print_color "$GREEN" "All tests passed! No fixes needed."
  fi
  
  # Wait for user input to continue or exit
  print_color "$BLUE" "Press Enter to run again or Ctrl+C to exit"
  read -r
  
  ((iteration++))
done 