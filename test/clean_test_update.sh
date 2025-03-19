#!/bin/bash
set -e  # Exit on error

CONFIG_DIR=~/.config/nvim
BACKUP_DIR=$CONFIG_DIR/backup
TEST_DIR=~/tamarin-test
LOG_FILE=$TEST_DIR/test_results.log

echo "------------------------------------------------------------"
echo "PHASE 1: Directory Cleanup"
echo "------------------------------------------------------------"

# Create backup directories if they don't exist
mkdir -p $BACKUP_DIR/parser
mkdir -p $BACKUP_DIR/queries/spthy
mkdir -p $BACKUP_DIR/queries/tamarin
mkdir -p $BACKUP_DIR/lua/tamarin
mkdir -p $TEST_DIR

# Proper cleanup of tamarin directory structure
echo "Cleaning up directory structure..."

# 1. Check and backup existing parsers
if [ -d "$CONFIG_DIR/parser/tamarin" ]; then
  echo "Moving redundant tamarin parser to backup..."
  mkdir -p $BACKUP_DIR/parser/tamarin
  cp -a $CONFIG_DIR/parser/tamarin/* $BACKUP_DIR/parser/tamarin/
  rm -rf $CONFIG_DIR/parser/tamarin
fi

# 2. Remove and backup any symlinks
if [ -L "$CONFIG_DIR/queries/tamarin/highlights.scm" ]; then
  echo "Backing up and removing symlink from tamarin to spthy queries..."
  mkdir -p $BACKUP_DIR/queries/tamarin
  cp -a $CONFIG_DIR/queries/tamarin/highlights.scm $BACKUP_DIR/queries/tamarin/
  rm $CONFIG_DIR/queries/tamarin/highlights.scm
fi

# 3. Backup and cleanup old module files
echo "Backing up and cleaning up Lua modules..."
for file in treesitter.lua parser_loader.lua simplified.lua simplified_loader.lua; do
  if [ -f "$CONFIG_DIR/lua/tamarin/$file" ]; then
    echo "Backing up $file..."
    cp "$CONFIG_DIR/lua/tamarin/$file" "$BACKUP_DIR/lua/tamarin/"
    echo "Removing $file..."
    rm "$CONFIG_DIR/lua/tamarin/$file"
  fi
done

echo "Directory cleanup complete!"

echo "------------------------------------------------------------"
echo "PHASE 2: Testing Installation"
echo "------------------------------------------------------------"

# Create test file with problematic constructs (variables with apostrophes)
echo "Creating test file..."
cat > $TEST_DIR/test.spthy << 'EOF'
theory Test
begin

builtins: symmetric-encryption, hashing

// Basic keywords and constructs
functions: f/1, g/2
equations: f(x) = g(x, x)

// Simple rule
rule Simple:
    [ ] --[ ]-> [ ]

// Rule with variables
rule WithVariables:
    let x = 'foo'
    let y = 'bar'
    in
    [ In(x) ] --[ Processed(x, y) ]-> [ Out(y) ]

// Variables with apostrophes (previously problematic)
rule Apostrophes:
    let x' = 'foo'
    let y' = 'bar'
    let complex'name = 'complex'
    in
    [ In(x') ] --[ Processed(x', y') ]-> [ Out(complex'name) ]

// Constants
rule Constants:
    [ ] --[ ]-> [ Out(CONSTANT, VALUE) ]

// Lemma
lemma secrecy:
    "∀ x #i. Secret(x) @ i ⟹ ¬(∃ #j. K(x) @ j)"

end
EOF

# Create a truly headless test script that writes to log and exits cleanly
echo "Creating headless test script..."
cat > $TEST_DIR/true_headless_test.lua << 'EOF'
-- Truly headless test script for Tamarin TreeSitter integration
local log_file = io.open(vim.fn.expand("~/tamarin-test/test_results.log"), "w")

local function log(msg)
  log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
  log_file:flush()
  print(msg) -- Also output to console
end

log("Starting truly headless test")

-- 1. Load the tamarin module
local ok, tamarin = pcall(require, "tamarin")
if not ok then
  log("ERROR: Failed to load tamarin module: " .. tostring(tamarin))
  log_file:close()
  vim.cmd("qa!") -- Exit Neovim
  return
end

-- 2. Cleanup previous setup
log("Cleaning up previous setup...")
tamarin.cleanup()

-- 3. Setup Tamarin TreeSitter integration
log("Setting up Tamarin TreeSitter integration...")
local setup_ok = tamarin.setup()
log("Setup result: " .. (setup_ok and "SUCCESS" or "FAILED"))

-- 4. Open the test file
vim.cmd("edit ~/tamarin-test/test.spthy")
log("Opened test file: ~/tamarin-test/test.spthy")

-- 5. Set filetype
vim.cmd("set filetype=tamarin")
log("Set filetype to tamarin")

-- 6. Collect basic buffer info
log("Buffer info:")
log("  Number: " .. vim.api.nvim_get_current_buf())
log("  Filetype: " .. vim.bo.filetype)
log("  Name: " .. vim.api.nvim_buf_get_name(0))

-- 7. Try to set up highlighting
log("Setting up highlighting...")
local highlight_ok = pcall(tamarin.ensure_highlighting, 0)
log("Highlighting setup: " .. (highlight_ok and "SUCCESS" or "FAILED"))

-- 8. Run diagnostics with captured output
log("Running diagnostics...")
local diagnostic_output = {}
local original_print = print
print = function(...)
  local args = {...}
  local line = ""
  for i, v in ipairs(args) do
    line = line .. tostring(v) .. (i < #args and "\t" or "")
  end
  table.insert(diagnostic_output, line)
  log("DIAG: " .. line)
end

pcall(tamarin.diagnose)

print = original_print

-- 9. Check parser status
log("Checking parser status...")
local has_parser = false
if vim.treesitter and vim.treesitter.language and vim.treesitter.language.get then
  has_parser = pcall(vim.treesitter.language.get, 'spthy')
end
log("Parser registered: " .. tostring(has_parser))

-- 10. Check highlighter status
log("Checking highlighter status...")
local has_highlighter = false
if vim.treesitter and vim.treesitter.highlighter and vim.treesitter.highlighter.active then
  has_highlighter = vim.treesitter.highlighter.active[0] ~= nil
end
log("Active highlighter: " .. tostring(has_highlighter))
log("Buffer highlighter object: " .. tostring(vim.b[0].tamarin_ts_highlighter ~= nil))

-- 11. Test for apostrophe variables
log("Testing for apostrophe variables...")
-- Try to parse the buffer with TreeSitter
local ts_parser_ok = false
if vim.treesitter.get_parser then
  ts_parser_ok = pcall(vim.treesitter.get_parser, 0, 'spthy')
end
log("Buffer parsed by TreeSitter: " .. tostring(ts_parser_ok))

-- 12. Check query file status
log("Checking query files...")
if vim.treesitter and vim.treesitter.query and vim.treesitter.query.get then
  local query_ok, query = pcall(vim.treesitter.query.get, 'spthy', 'highlights')
  log("Query loaded: " .. tostring(query_ok and query ~= nil))
end

-- 13. Summarize findings
log("\nTEST SUMMARY:")
log("  Parser loaded: " .. tostring(has_parser))
log("  Highlighter active: " .. tostring(has_highlighter))
log("  Setup status: " .. (setup_ok and "SUCCESS" or "FAILED"))
log("  Highlighting status: " .. (highlight_ok and "SUCCESS" or "FAILED"))

log("Test completed. Exiting...")
log_file:close()

-- Exit Neovim after a short delay to ensure log file is written
vim.defer_fn(function() vim.cmd("qa!") end, 500)
EOF

# Run the truly headless test
echo "Running truly headless test..."
timeout 10s nvim --headless -u NONE -c "set rtp+=~/.config/nvim" -c "source ~/.config/nvim/init.lua" -c "luafile ~/tamarin-test/true_headless_test.lua" || echo "Test timed out or encountered an error"

# Display test results
echo "Test results:"
if [ -f "$LOG_FILE" ]; then
  cat "$LOG_FILE"
else
  echo "No log file found at $LOG_FILE"
fi

echo "------------------------------------------------------------"
echo "PHASE 3: Updating Hypotheses Database"
echo "------------------------------------------------------------"

# Extract test results to update hypotheses
echo "Extracting test results to update hypotheses..."
if [ -f "$LOG_FILE" ]; then
  PARSER_LOADED=$(grep "Parser registered" "$LOG_FILE" | awk '{print $NF}')
  HIGHLIGHTER_ACTIVE=$(grep "Active highlighter" "$LOG_FILE" | awk '{print $NF}')
  SETUP_STATUS=$(grep "Setup status" "$LOG_FILE" | awk '{print $NF}')
  HIGHLIGHT_STATUS=$(grep "Highlighting status" "$LOG_FILE" | awk '{print $NF}')
  
  echo "Parser loaded: $PARSER_LOADED"
  echo "Highlighter active: $HIGHLIGHTER_ACTIVE"
  echo "Setup status: $SETUP_STATUS"
  echo "Highlighting status: $HIGHLIGHT_STATUS"
  
  # Update hypothesis database with findings
  echo "Updating hypothesis database..."
  cat > hypothesis_update.txt << EOF
Based on headless testing with Neovim, we have new evidence:

- Parser registration: ${PARSER_LOADED}
- Highlighter activation: ${HIGHLIGHTER_ACTIVE}
- Setup success: ${SETUP_STATUS}
- Highlighting success: ${HIGHLIGHT_STATUS}

This evidence supports or refines the following hypotheses:
- H1 (TreeSitter parser loading issues): ${PARSER_LOADED}
- H5 (Language to filetype mapping): ${PARSER_LOADED}
- H14 (External scanner for apostrophes): ${HIGHLIGHTER_ACTIVE}
- H16 (GC prevention): ${HIGHLIGHTER_ACTIVE}

Note: This is an automated assessment and should be manually verified.
EOF

  cat hypothesis_update.txt
else
  echo "No log file found, cannot update hypotheses."
fi

echo "------------------------------------------------------------"
echo "PHASE 4: Manual verification"
echo "------------------------------------------------------------"
echo "To manually verify the installation:"
echo "1. Open the test file: nvim ~/tamarin-test/test.spthy"
echo "2. Run the diagnostics: :lua require('tamarin').diagnose()"
echo "3. Check that syntax highlighting works, especially for variables with apostrophes"
echo "------------------------------------------------------------" 