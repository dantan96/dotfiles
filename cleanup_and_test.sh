#!/bin/bash
set -e  # Exit on error

CONFIG_DIR=~/.config/nvim
BACKUP_DIR=$CONFIG_DIR/backup
TEST_DIR=~/tamarin-test

echo "------------------------------------------------------------"
echo "PHASE 1: Directory Cleanup"
echo "------------------------------------------------------------"

# Create backup directories if they don't exist
mkdir -p $BACKUP_DIR/parser
mkdir -p $BACKUP_DIR/queries/spthy
mkdir -p $BACKUP_DIR/queries/tamarin
mkdir -p $BACKUP_DIR/lua/tamarin

# Clean up parser files
echo "Checking parser files..."
if [ -d "$CONFIG_DIR/parser/tamarin" ]; then
  echo "Moving tamarin parser to backup..."
  cp -a $CONFIG_DIR/parser/tamarin/* $BACKUP_DIR/parser/
  rm -rf $CONFIG_DIR/parser/tamarin
fi

# Clean up query files
echo "Checking query files..."
if [ -L "$CONFIG_DIR/queries/tamarin/highlights.scm" ]; then
  echo "Removing symlink from tamarin to spthy queries..."
  rm $CONFIG_DIR/queries/tamarin/highlights.scm
fi

# Backup old module files
echo "Backing up existing Lua modules..."
if [ -f "$CONFIG_DIR/lua/tamarin/treesitter.lua" ]; then
  cp $CONFIG_DIR/lua/tamarin/treesitter.lua $BACKUP_DIR/lua/tamarin/
fi
if [ -f "$CONFIG_DIR/lua/tamarin/parser_loader.lua" ]; then
  cp $CONFIG_DIR/lua/tamarin/parser_loader.lua $BACKUP_DIR/lua/tamarin/
fi
if [ -f "$CONFIG_DIR/lua/tamarin/simplified_loader.lua" ]; then
  cp $CONFIG_DIR/lua/tamarin/simplified_loader.lua $BACKUP_DIR/lua/tamarin/
fi
if [ -f "$CONFIG_DIR/lua/tamarin/simplified.lua" ]; then
  cp $CONFIG_DIR/lua/tamarin/simplified.lua $BACKUP_DIR/lua/tamarin/
fi

# Clean up the Lua modules
echo "Updating Lua modules..."
if [ -f "$CONFIG_DIR/lua/tamarin/treesitter.lua" ]; then
  rm $CONFIG_DIR/lua/tamarin/treesitter.lua
fi
if [ -f "$CONFIG_DIR/lua/tamarin/parser_loader.lua" ]; then
  rm $CONFIG_DIR/lua/tamarin/parser_loader.lua
fi
if [ -f "$CONFIG_DIR/lua/tamarin/simplified_loader.lua" ]; then
  rm $CONFIG_DIR/lua/tamarin/simplified_loader.lua
fi
if [ -f "$CONFIG_DIR/lua/tamarin/simplified.lua" ]; then
  rm $CONFIG_DIR/lua/tamarin/simplified.lua
fi

echo "Directory cleanup complete!"

echo "------------------------------------------------------------"
echo "PHASE 2: Testing Installation"
echo "------------------------------------------------------------"

# Create test directory and file
mkdir -p $TEST_DIR
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

# Create headless test script
cat > $TEST_DIR/test_headless.lua << 'EOF'
-- Headless test script for Tamarin TreeSitter integration
-- Records results to a log file for inspection

local log_file = io.open(vim.fn.expand("~/tamarin-test/test_results.log"), "w")

local function log(msg)
  log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
  log_file:flush()
end

log("Starting headless test")

-- Load and clean up any previous setup
local ok, tamarin = pcall(require, "tamarin")
if not ok then
  log("ERROR: Failed to load tamarin module: " .. tostring(tamarin))
  log_file:close()
  vim.cmd("quit!")
  return
end

tamarin.cleanup()
log("Cleaned up previous setup")

-- Setup Tamarin TreeSitter integration
log("Setting up Tamarin TreeSitter integration...")
local setup_ok = tamarin.setup()
log("Setup result: " .. (setup_ok and "SUCCESS" or "FAILED"))

-- Open the test file
vim.cmd("edit ~/tamarin-test/test.spthy")
log("Opened test file")

-- Ensure filetype is set correctly
vim.cmd("set filetype=tamarin")
log("Set filetype to tamarin")

-- Check buffer info
log("Buffer info:")
log("  Number: " .. vim.api.nvim_get_current_buf())
log("  Filetype: " .. vim.bo.filetype)
log("  Name: " .. vim.api.nvim_buf_get_name(0))

-- Ensure highlighting is set up
log("\nSetting up highlighting for current buffer...")
local highlight_ok = tamarin.ensure_highlighting(0)
log("Highlighting result: " .. (highlight_ok and "SUCCESS" or "FAILED"))

-- Test garbage collection
log("\nTesting garbage collection behavior...")
local gc_result = tamarin.test_gc(0)
log("GC prevention test: " .. (gc_result.active_after_gc and "PASSED" or "FAILED"))

-- Try to extract some diagnostic info
log("\nHighlighting diagnostics:")
if vim.treesitter and vim.treesitter.highlighter and vim.treesitter.highlighter.active then
  log("  Highlighter active: " .. tostring(vim.treesitter.highlighter.active[0] ~= nil))
end
log("  Buffer highlighter exists: " .. tostring(vim.b[0].tamarin_ts_highlighter ~= nil))

-- Check if we can get query info
if vim.treesitter and vim.treesitter.query and vim.treesitter.query.get then
  local ok, query = pcall(vim.treesitter.query.get, 'spthy', 'highlights')
  log("  Query loaded: " .. tostring(ok and query ~= nil))
end

-- Run diagnostics if available
if tamarin.diagnose then
  log("\nRunning diagnostics...")
  -- Capture output from diagnose function
  local old_print = print
  print = function(...)
    local args = {...}
    local line = ""
    for i, v in ipairs(args) do
      line = line .. tostring(v) .. (i < #args and "\t" or "")
    end
    log("  " .. line)
  end
  
  tamarin.diagnose()
  print = old_print
end

log("\nTest completed. Check highlighting in Neovim.")
log("End of test")
log_file:close()

-- Wait a moment to ensure logs are written
vim.defer_fn(function()
  vim.cmd("quit!")
end, 1000)
EOF

# Run headless Neovim test
echo "Running headless Neovim test..."
nvim --headless -u NONE -c "set rtp+=~/.config/nvim" -c "source ~/.config/nvim/init.lua" -c "luafile ~/tamarin-test/test_headless.lua"

# Show test results
echo "Test results:"
cat $TEST_DIR/test_results.log

echo "------------------------------------------------------------"
echo "PHASE 3: Manual verification"
echo "------------------------------------------------------------"
echo "To manually verify the installation:"
echo "1. Open the test file: nvim ~/tamarin-test/test.spthy"
echo "2. Run the diagnostics: :lua require('tamarin').diagnose()"
echo "3. Check that syntax highlighting works, especially for variables with apostrophes"
echo "------------------------------------------------------------" 