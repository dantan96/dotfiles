#!/bin/bash

# Test suite for run-tests.sh 
# This script tests the syntax highlighting test framework

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="/tmp/highlight_tests"
mkdir -p "$TEST_DIR"

# Cleanup function
function cleanup {
  rm -rf "$TEST_DIR"
}

# Register cleanup on exit
trap cleanup EXIT

# Helper functions
function echo_success {
  echo -e "${GREEN}✓ $1${NC}"
}

function echo_failure {
  echo -e "${RED}✗ $1${NC}"
}

function echo_info {
  echo -e "${YELLOW}$1${NC}"
}

# Create a mock test-highlighting.lua file with predictable results
function create_mock_test_file {
  local result_type="$1"  # "pass", "fail", or "error"
  
  cat > "$TEST_DIR/test-highlighting.lua" << EOT
-- Mock test highlighting script
local M = {}

-- Configuration 
local config = {
  results_file = "/tmp/tamarin_highlight_results.json",
  error_log = "/tmp/tamarin_highlight_errors.log",
  test_file = "/tmp/tamarin_test.spthy",
  debug = true
}

-- Save results to file
local function save_results(results)
  -- Convert to JSON
  local json = vim.json.encode(results)
  
  -- Write to file
  local f = io.open(config.results_file, "w")
  if f then
    f:write(json)
    f:close()
    print("Results saved to: " .. config.results_file)
    return true
  else
    print("Failed to save results: ERROR")
    return false
  end
end

-- Main function to run tests
function M.run()
  print("Starting mock tests...")
  
  -- Create test result based on the type
  local results
  if "$result_type" == "pass" then
    results = {
      { name = "Test 1", passed = true, expected = "keyword", actual = "keyword", line = 1, col = 1 },
      { name = "Test 2", passed = true, expected = "variable", actual = "variable", line = 2, col = 2 },
      { name = "Test 3", passed = true, expected = "function", actual = "function", line = 3, col = 3 }
    }
  elseif "$result_type" == "fail" then
    results = {
      { name = "Test 1", passed = true, expected = "keyword", actual = "keyword", line = 1, col = 1 },
      { name = "Test 2", passed = false, expected = "variable", actual = "string", line = 2, col = 2 },
      { name = "Test 3", passed = false, expected = "function", actual = "none", line = 3, col = 3 }
    }
  elseif "$result_type" == "error" then
    results = { error = "Mock error: Test execution failed" }
    
    -- Write to error log
    local f = io.open(config.error_log, "w")
    if f then
      f:write("# Tamarin Syntax Highlighting Test Errors\\n")
      f:write("# Generated: Mock date\\n\\n")
      f:write("[ERROR] Test execution failed: Mock error\\n")
      f:close()
    end
  end
  
  -- Save results
  save_results(results)
  
  -- For error type, exit with an error status
  if "$result_type" == "error" then
    error("Mock error thrown")
  end
  
  -- This function returns results, but in headless mode we rely on the file output
  return results
end

-- Run the tests when this file is executed directly
M.run()

return M
EOT
}

# Create a mock run-tests.sh that uses our mock test file
function create_mock_runner {
  cat > "$TEST_DIR/run-tests.sh" << 'EOT'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
RESULTS_FILE="/tmp/tamarin_highlight_results.json"
ERROR_LOG="/tmp/tamarin_highlight_errors.log"
NVIM_LOG="/tmp/nvim_headless.log"

# Run the test in Neovim
nvim --headless -c "luafile $PWD/test-highlighting.lua" -c "qa!" > "$NVIM_LOG" 2>&1
EXIT_CODE=$?

# Check if Neovim executed successfully
if [ $EXIT_CODE -ne 0 ]; then
  echo -e "${RED}[ERROR] Neovim exited with an error.${NC}"
  tail -n 10 "$NVIM_LOG"
  exit 1
fi

# Check if results file was created
if [ ! -f "$RESULTS_FILE" ]; then
  echo -e "${RED}[ERROR] Test results file was not created.${NC}"
  exit 1
fi

# Parse results
if command -v jq &> /dev/null; then
  ERROR=$(jq -r '.error // empty' "$RESULTS_FILE")
  if [ ! -z "$ERROR" ]; then
    echo -e "${RED}[ERROR] $ERROR${NC}"
    exit 1
  fi
  
  PASS_COUNT=$(jq '[.[] | select(.passed == true)] | length' "$RESULTS_FILE")
  FAIL_COUNT=$(jq '[.[] | select(.passed == false)] | length' "$RESULTS_FILE")
  
  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS] All tests passed! ($PASS_COUNT tests)${NC}"
  else
    echo -e "${RED}[ERROR] $FAIL_COUNT tests failed, $PASS_COUNT passed.${NC}"
    jq -r '.[] | select(.passed == false) | "- \(.name): expected \(.expected), got \(.actual)"' "$RESULTS_FILE"
    exit 1
  fi
else
  echo -e "${YELLOW}[WARNING] jq not found. Displaying raw results:${NC}"
  cat "$RESULTS_FILE"
fi

# Check for any logged errors
if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
  echo -e "${YELLOW}[WARNING] Errors were logged during test execution:${NC}"
  cat "$ERROR_LOG"
fi

echo "[INFO] Testing completed."
EOT

  chmod +x "$TEST_DIR/run-tests.sh"
}

# Test functions
function test_passing_case {
  echo_info "Testing: All tests pass"
  create_mock_test_file "pass"
  cd "$TEST_DIR" && ./run-tests.sh > /tmp/test_output.txt 2>&1
  local exit_code=$?
  
  if [ $exit_code -eq 0 ] && grep -q "All tests passed" /tmp/test_output.txt; then
    echo_success "Pass: Detected all passing tests"
    return 0
  else
    echo_failure "Fail: Did not correctly handle passing tests"
    echo "Output:"
    cat /tmp/test_output.txt
    return 1
  fi
}

function test_failing_case {
  echo_info "Testing: Some tests fail"
  create_mock_test_file "fail"
  cd "$TEST_DIR" && ./run-tests.sh > /tmp/test_output.txt 2>&1
  local exit_code=$?
  
  if [ $exit_code -ne 0 ] && grep -q "tests failed" /tmp/test_output.txt; then
    echo_success "Pass: Correctly detected failing tests"
    return 0
  else
    echo_failure "Fail: Did not correctly identify failing tests"
    echo "Output:"
    cat /tmp/test_output.txt
    return 1
  fi
}

function test_error_case {
  echo_info "Testing: Script execution error"
  create_mock_test_file "error"
  cd "$TEST_DIR" && ./run-tests.sh > /tmp/test_output.txt 2>&1
  local exit_code=$?
  
  if [ $exit_code -ne 0 ] && grep -q "error" /tmp/test_output.txt; then
    echo_success "Pass: Correctly captured script error"
    return 0
  else
    echo_failure "Fail: Did not correctly handle execution error"
    echo "Output:"
    cat /tmp/test_output.txt
    return 1
  fi
}

# Main test execution
echo "Testing run-tests.sh framework..."
create_mock_runner

test_passed=true

test_passing_case || test_passed=false
test_failing_case || test_passed=false
test_error_case || test_passed=false

# Summary
echo -e "\n${YELLOW}Test Summary:${NC}"
if [ "$test_passed" = true ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi 