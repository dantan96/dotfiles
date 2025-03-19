#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESULTS_FILE="/tmp/tamarin_highlight_results.json"
ERROR_LOG="/tmp/tamarin_highlight_errors.log"
NVIM_LOG="/tmp/nvim_headless.log"
DEBUG=true

# Helper functions
function log {
  echo -e "[$(date +%H:%M:%S)] $1"
}

function debug {
  if [ "$DEBUG" = true ]; then
    echo -e "${BLUE}[DEBUG] $1${NC}"
  fi
}

function error {
  echo -e "${RED}[ERROR] $1${NC}"
}

function success {
  echo -e "${GREEN}[SUCCESS] $1${NC}"
}

function warning {
  echo -e "${YELLOW}[WARNING] $1${NC}"
}

function check_file_exists {
  if [ ! -f "$1" ]; then
    error "File not found: $1"
    return 1
  fi
  return 0
}

# Clean up old test files
function cleanup {
  log "Cleaning up test files..."
  rm -f "$RESULTS_FILE" "$ERROR_LOG" "$NVIM_LOG" "/tmp/tamarin_test.spthy" > /dev/null 2>&1
}

# Run the test in Neovim
function run_test {
  log "Running tests in Neovim headlessly..."
  
  # Execute Neovim in headless mode, with more extensive initialization
  nvim --headless \
    -c "set runtimepath+=$PWD" \
    -c "luafile test-highlighting.lua" \
    -c "lua vim.g.tamarin_highlight_debug = true" \
    -c "lua vim.treesitter.language.add('spthy')" \
    -c "lua vim.filetype.add({extension = {spthy = 'spthy'}})" \
    -c "qa!" \
    > "$NVIM_LOG" 2>&1
  
  # Check if Neovim executed successfully
  if [ $? -ne 0 ]; then
    error "Neovim exited with an error."
    echo "Last 10 lines of output:"
    tail -n 10 "$NVIM_LOG"
    return 1
  fi
  
  # Check if results file was created
  if [ ! -f "$RESULTS_FILE" ]; then
    error "Test results file was not created. Test may have failed."
    echo "Last 10 lines of Neovim output:"
    tail -n 10 "$NVIM_LOG"
    return 1
  fi
  
  return 0
}

# Parse the results
function parse_results {
  log "Parsing test results..."
  
  # Make sure jq is installed
  if ! command -v jq &> /dev/null; then
    warning "jq not found. Displaying raw results."
    cat "$RESULTS_FILE"
    return 0
  fi
  
  # Check if there's an error in the results
  local error=$(jq -r '.error // empty' "$RESULTS_FILE")
  if [ ! -z "$error" ]; then
    error "Test reported an error: $error"
    return 1
  fi
  
  # Count passes and failures
  local pass_count=$(jq '[.[] | select(.passed == true)] | length' "$RESULTS_FILE")
  local fail_count=$(jq '[.[] | select(.passed == false)] | length' "$RESULTS_FILE")
  
  if [ "$fail_count" -eq 0 ]; then
    success "All tests passed! ($pass_count tests)"
  else
    error "$fail_count tests failed, $pass_count passed."
    
    # Show failed tests details
    echo "Failed tests:"
    jq -r '.[] | select(.passed == false) | "- \(.name): expected \(.expected), got \(.actual) (at line \(.line), col \(.col))"' "$RESULTS_FILE"
  fi
  
  # Check for any logged errors
  if check_file_exists "$ERROR_LOG"; then
    if [ -s "$ERROR_LOG" ]; then
      warning "Errors were logged during test execution:"
      cat "$ERROR_LOG"
    fi
  fi
  
  return 0
}

# Parse command line arguments
for i in "$@"; do
  case $i in
    --no-cleanup)
      NO_CLEANUP=true
      ;;
    --debug)
      DEBUG=true
      ;;
    --help)
      echo "Usage: run-tests.sh [OPTIONS]"
      echo "Run syntax highlighting tests headlessly in Neovim"
      echo ""
      echo "Options:"
      echo "  --no-cleanup    Don't clean up temporary files after running"
      echo "  --debug         Enable debug output"
      echo "  --help          Display this help message"
      exit 0
      ;;
    *)
      error "Unknown option: $i"
      echo "Use --help for usage information."
      exit 1
      ;;
  esac
done

# Main execution
log "Starting Tamarin syntax highlighting tests..."

# Ensure test script exists
if ! check_file_exists "test-highlighting.lua"; then
  error "Test script not found: test-highlighting.lua"
  exit 1
fi

# Clean up old files
cleanup

# Run the test
if ! run_test; then
  error "Failed to run tests."
  exit 1
fi

# Parse and display results
if ! parse_results; then
  error "Failed to parse test results."
  exit 1
fi

# Clean up unless --no-cleanup was specified
if [ "$NO_CLEANUP" != true ]; then
  cleanup
else
  log "Leaving test files for inspection:"
  log "- Results: $RESULTS_FILE"
  log "- Error log: $ERROR_LOG"
  log "- Neovim log: $NVIM_LOG"
  log "- Test file: /tmp/tamarin_test.spthy"
fi

log "Testing completed." 