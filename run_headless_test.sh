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
mkdir -p $BACKUP_DIR/parser/tamarin
mkdir -p $BACKUP_DIR/queries/spthy
mkdir -p $BACKUP_DIR/queries/tamarin
mkdir -p $BACKUP_DIR/lua/tamarin
mkdir -p $TEST_DIR

# Cleanup redundant files and directories
echo "Cleaning up directory structure..."

# 1. Check and backup tamarin parser directory
if [ -d "$CONFIG_DIR/parser/tamarin" ]; then
  echo "Moving redundant tamarin parser to backup..."
  cp -a $CONFIG_DIR/parser/tamarin/* $BACKUP_DIR/parser/tamarin/ 2>/dev/null || true
  rm -rf $CONFIG_DIR/parser/tamarin
fi

# 2. Remove symlinks
if [ -L "$CONFIG_DIR/queries/tamarin/highlights.scm" ]; then
  echo "Removing symlink from tamarin to spthy queries..."
  rm $CONFIG_DIR/queries/tamarin/highlights.scm
fi

# 3. Backup and remove old module files
echo "Backing up and removing old Lua modules..."
modules_to_backup=(
  "treesitter.lua"
  "parser_loader.lua" 
  "simplified.lua"
  "simplified_loader.lua"
)

for module in "${modules_to_backup[@]}"; do
  if [ -f "$CONFIG_DIR/lua/tamarin/$module" ]; then
    echo "Backing up $module..."
    cp -f "$CONFIG_DIR/lua/tamarin/$module" "$BACKUP_DIR/lua/tamarin/" 2>/dev/null || true
    echo "Removing $module..."
    rm -f "$CONFIG_DIR/lua/tamarin/$module"
  fi
done

echo "Directory cleanup complete!"

echo "------------------------------------------------------------"
echo "PHASE 2: Running Headless Tests"
echo "------------------------------------------------------------"

# Create test file with problematic constructs
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

# Run the truly headless test
echo "Running headless Neovim test..."
timeout 10s nvim --headless -u NONE -c "set rtp+=~/.config/nvim" -c "source ~/.config/nvim/init.lua" -c "luafile ~/.config/nvim/headless_test.lua" || echo "Headless test timed out or encountered an error"

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
  # Get test results from log
  MODULE_LOADED=$(grep "Module loaded" "$LOG_FILE" | awk '{print $NF}')
  SETUP_OK=$(grep "Setup successful" "$LOG_FILE" | awk '{print $NF}')
  LANG_REGISTERED=$(grep "Language registered" "$LOG_FILE" | awk '{print $NF}')
  PARSER_LOADED=$(grep "Parser loaded" "$LOG_FILE" | awk '{print $NF}')
  SCANNER_PRESENT=$(grep "External scanner present" "$LOG_FILE" | awk '{print $NF}')
  HIGHLIGHTER_ACTIVE=$(grep "Highlighter active" "$LOG_FILE" | awk '{print $NF}')
  APOSTROPHE_HANDLED=$(grep "Apostrophe variables handled" "$LOG_FILE" | awk '{print $NF}')
  
  echo "Module loaded: $MODULE_LOADED"
  echo "Setup successful: $SETUP_OK"
  echo "Language registered: $LANG_REGISTERED"
  echo "Parser loaded: $PARSER_LOADED"
  echo "External scanner present: $SCANNER_PRESENT"
  echo "Highlighter active: $HIGHLIGHTER_ACTIVE"
  echo "Apostrophe variables handled: $APOSTROPHE_HANDLED"
  
  # Create summary file for updating hypothesis database
  cat > test_summary.md << EOF
## Headless Neovim Testing Results

From headless testing with Neovim, we have the following evidence:

- Module loading: ${MODULE_LOADED}
- Setup success: ${SETUP_OK}
- Language registration: ${LANG_REGISTERED}
- Parser loading: ${PARSER_LOADED}
- External scanner present: ${SCANNER_PRESENT}
- Highlighter activation: ${HIGHLIGHTER_ACTIVE}
- Apostrophe variables handled: ${APOSTROPHE_HANDLED}

This evidence supports or updates the following hypotheses:

- H1 (TreeSitter parser loading): ${PARSER_LOADED}
- H3 (Parser exports _tree_sitter_spthy): ${PARSER_LOADED}
- H5 (Language to filetype mapping): ${LANG_REGISTERED}
- H8 (Redundant code simplification): ${SETUP_OK}
- H14 (External scanner for apostrophes): ${SCANNER_PRESENT} and ${APOSTROPHE_HANDLED}
- H16 (GC prevention): ${HIGHLIGHTER_ACTIVE}

Based on these results, we should ${SCANNER_PRESENT == "true" ? "continue to use the external scanner approach" : "reconsider our approach to the external scanner"}.
EOF

  echo "Test summary created in test_summary.md"
  cat test_summary.md
else
  echo "No log file found, cannot update hypotheses."
fi

echo "------------------------------------------------------------"
echo "PHASE 4: Manual verification"
echo "------------------------------------------------------------"
echo "To manually verify the installation:"
echo "1. Open the test file: nvim ~/tamarin-test/test.spthy"
echo "2. Check that syntax highlighting works, especially for variables with apostrophes"
echo "------------------------------------------------------------" 