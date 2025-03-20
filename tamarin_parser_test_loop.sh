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
print_color "$BLUE" "Running automated tests and fixes..."

# Maximum number of iterations before giving up
MAX_ITERATIONS=5
iteration=1

# Array of fix scripts to try in order - now that we have gobjcopy, try the rename approach first
FIX_SCRIPTS=("tamarin_parser_rename.lua" "modified_spthy_parser_approach.lua" "fix_tamarin_neovim_only.lua" "fix_tamarin_parser.lua")

while [ $iteration -le $MAX_ITERATIONS ]; do
  print_color "$CYAN" "=== Iteration $iteration/$MAX_ITERATIONS ==="
  
  # First run the tamarin parser test (testing direct tamarin symbol)
  print_color "$CYAN" "--- Testing Tamarin Parser Symbol ---"
  run_test "simple_tamarin_test.lua"
  tamarin_test_result=$?
  
  # Then run the spthy parser test (testing if we can use spthy for .spthy files)
  print_color "$CYAN" "--- Testing Spthy Parser for Tamarin Files ---"
  run_test "spthy_test.lua"
  spthy_test_result=$?
  
  # If either test failed, run fixes
  if [ $tamarin_test_result -ne 0 ] || [ $spthy_test_result -ne 0 ]; then
    if [ $tamarin_test_result -ne 0 ]; then
      print_color "$YELLOW" "Tamarin parser test failed, trying fixes..."
    fi
    
    if [ $spthy_test_result -ne 0 ]; then
      print_color "$YELLOW" "Spthy parser for Tamarin files test failed, trying fixes..."
    fi
    
    fix_success=false
    
    # Try each fix script until one succeeds
    for fix_file in "${FIX_SCRIPTS[@]}"; do
      print_color "$CYAN" "Trying fix: $fix_file"
      run_fix "$fix_file"
      fix_result=$?
      
      # If the fix was successful, verify with both tests
      if [ $fix_result -eq 0 ]; then
        print_color "$BLUE" "Running tests again to verify fix..."
        
        # First verify tamarin parser
        if [ $tamarin_test_result -ne 0 ]; then
          print_color "$CYAN" "--- Re-testing Tamarin Parser Symbol ---"
          run_test "simple_tamarin_test.lua"
          tamarin_verify_result=$?
        else
          tamarin_verify_result=0
        fi
        
        # Then verify spthy parser
        if [ $spthy_test_result -ne 0 ]; then
          print_color "$CYAN" "--- Re-testing Spthy Parser for Tamarin Files ---"
          run_test "spthy_test.lua" 
          spthy_verify_result=$?
        else
          spthy_verify_result=0
        fi
        
        # Check if all tests now pass
        if [ $tamarin_verify_result -eq 0 ] && [ $spthy_verify_result -eq 0 ]; then
          print_color "$GREEN" "✓ Fix was successful with $fix_file!"
          fix_success=true
          
          # Save the successful fix info
          echo "Fix successful on $(date)" > successful_fix.txt
          echo "Using script: $fix_file" >> successful_fix.txt
          
          break
        else
          if [ $tamarin_verify_result -ne 0 ]; then
            print_color "$RED" "✗ Fix with $fix_file did not resolve Tamarin parser issues"
          fi
          
          if [ $spthy_verify_result -ne 0 ]; then
            print_color "$RED" "✗ Fix with $fix_file did not resolve Spthy parser issues"
          fi
        fi
      else
        print_color "$RED" "✗ Fix $fix_file failed to run correctly"
      fi
    done
    
    # If none of the fixes worked, continue to next iteration
    if [ "$fix_success" = false ]; then
      print_color "$YELLOW" "All fixes attempted without success. Continuing to next iteration..."
    else
      # A fix was successful, we can exit
      print_color "$GREEN" "A successful fix was applied! Exiting loop."
      exit 0
    fi
    
  else
    print_color "$GREEN" "All tests passed! No fixes needed."
    exit 0
  fi
  
  # Sleep briefly before next iteration
  sleep 2
  
  ((iteration++))
done

# If we get here, we've reached the maximum iterations without success
print_color "$RED" "Maximum iterations ($MAX_ITERATIONS) reached without success."
print_color "$YELLOW" "You may need to manually restart Neovim for changes to take effect, or investigate further."
exit 1 