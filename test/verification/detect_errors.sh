#!/bin/bash

# Script to detect all Neovim errors when loading a Tamarin file

# Create test directory and file
mkdir -p ~/test_tamarin
cat > ~/test_tamarin/test.spthy << 'EOF'
theory Test
begin

rule Test:
  [ ] --[ ]-> [ ]
  
lemma test:
  exists-trace
  "test"
  
end
EOF

# Error log files
ERROR_LOG="/tmp/nvim_errors.log"
DEBUG_LOG="/tmp/nvim_debug.log"

echo "Running Neovim with test file and capturing errors..."

# Clear any previous logs
rm -f $ERROR_LOG $DEBUG_LOG

# Create a Lua script to properly capture all errors
cat > /tmp/capture_errors.lua << 'EOF'
-- Script to capture errors from Neovim
local log_file = io.open('/tmp/nvim_debug.log', 'w')

-- Log function for debugging
local function log_debug(msg)
  log_file:write(msg .. "\n")
  log_file:flush()
end

log_debug("Starting error detection...")

-- Try to load the highlights.scm file directly to check for errors
local query_file = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
log_debug("Loading query file: " .. query_file)

local content = vim.fn.readfile(query_file)
local content_str = table.concat(content, "\n")

-- Try to parse the query file
local success, result = pcall(function()
  return vim.treesitter.query.parse('spthy', content_str)
end)

if not success then
  log_debug("ERROR parsing query: " .. tostring(result))
  print("ERROR: " .. tostring(result))
  vim.cmd('redir! > /tmp/nvim_errors.log')
  print("ERROR: " .. tostring(result))
  vim.cmd('redir END')
else
  log_debug("Query parsed successfully")
  
  -- Try to get a parser
  log_debug("Attempting to get parser for current buffer...")
  local parser_success, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
  
  if not parser_success then
    log_debug("ERROR getting parser: " .. tostring(parser))
    print("ERROR: " .. tostring(parser))
  else
    log_debug("Parser created successfully")
    
    -- Try to create a highlighter
    log_debug("Attempting to create highlighter...")
    local highlighter_success, highlighter = pcall(vim.treesitter.highlighter.new, parser)
    
    if not highlighter_success then
      log_debug("ERROR creating highlighter: " .. tostring(highlighter))
      print("ERROR: " .. tostring(highlighter))
    else
      log_debug("Highlighter created successfully")
      
      -- Store highlighter to prevent GC
      vim.g.tamarin_highlighter = highlighter
      log_debug("Highlighter stored in g:tamarin_highlighter")
      
      -- Check if the highlighter is active
      if vim.treesitter.highlighter.active and vim.treesitter.highlighter.active[0] then
        log_debug("Highlighter is active for current buffer")
      else
        log_debug("WARNING: Highlighter is NOT active for current buffer")
      end
    end
  end
end

log_debug("Error detection complete")
log_file:close()
EOF

# Run Neovim with our diagnostic script
nvim --headless \
     -c "lua vim.treesitter.language.register('spthy', 'tamarin')" \
     -c "edit ~/test_tamarin/test.spthy" \
     -c "set filetype=tamarin" \
     -c "luafile /tmp/capture_errors.lua" \
     -c "redir! >> $ERROR_LOG" \
     -c "silent! messages" \
     -c "redir END" \
     -c "qa!" 2>> $ERROR_LOG

echo "Debug log contents:"
echo "------------------------------------------------------------"
cat "$DEBUG_LOG"
echo "------------------------------------------------------------"

# Check if error log contains any errors
if grep -q "ERROR\|error\|Error" "$ERROR_LOG"; then
    echo "ERRORS DETECTED:"
    echo "------------------------------------------------------------"
    cat "$ERROR_LOG"
    echo "------------------------------------------------------------"
    
    # Look for specific TreeSitter errors
    if grep -q "Query error" "$ERROR_LOG"; then
        echo "TreeSitter query errors found! These need to be fixed in highlights.scm."
        grep -A 3 "Query error" "$ERROR_LOG"
    fi
    
    exit 1
else
    echo "No errors detected in error log. Checking if the debug log shows any issues..."
    
    if grep -q "ERROR\|WARNING" "$DEBUG_LOG"; then
        echo "Issues found in debug log:"
        grep -A 1 "ERROR\|WARNING" "$DEBUG_LOG"
        exit 1
    else
        echo "No issues found. Syntax highlighting appears to be working correctly."
        exit 0
    fi
fi

# Clean up
rm -rf ~/test_tamarin /tmp/capture_errors.lua 