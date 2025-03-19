#!/bin/bash

# Script to detect all Neovim errors when loading a Tamarin file

# Error log files
ERROR_LOG="/tmp/nvim_errors.log"
DEBUG_LOG="/tmp/nvim_debug.log"

echo "Running query validation..."

# Clear any previous logs
rm -f $ERROR_LOG $DEBUG_LOG

# Create a Lua script to properly validate the query
cat > /tmp/validate_query.lua << 'EOF'
-- Script to validate TreeSitter query file

local log_file = io.open('/tmp/nvim_debug.log', 'w')

-- Log function for debugging
local function log_debug(msg)
  log_file:write(msg .. "\n")
  log_file:flush()
end

log_debug("Starting query validation...")

-- First ensure the parser is registered and loaded
log_debug("Registering spthy language for tamarin filetype...")
vim.treesitter.language.register('spthy', 'tamarin')

-- Find the parser in standard locations
local function find_parser()
  local possible_paths = {
    vim.fn.stdpath('config') .. '/parser/spthy/spthy.so',
    vim.fn.stdpath('config') .. '/parser/tamarin/tamarin.so',
    vim.fn.stdpath('data') .. '/site/pack/packer/start/nvim-treesitter/parser/spthy.so',
    vim.fn.stdpath('data') .. '/site/pack/lazy/opt/nvim-treesitter/parser/spthy.so',
    vim.fn.stdpath('data') .. '/lazy/nvim-treesitter/parser/spthy.so'
  }
  
  -- Try to find a parser file
  for _, path in ipairs(possible_paths) do
    if vim.fn.filereadable(path) == 1 then
      log_debug("Found parser at: " .. path)
      return path
    end
  end
  
  log_debug("ERROR: No parser found in standard locations")
  return nil
end

-- Load the parser explicitly
local parser_path = find_parser()
if parser_path then
  if vim.treesitter.language.add then
    local add_ok, add_err = pcall(vim.treesitter.language.add, 'spthy', { path = parser_path })
    if add_ok then
      log_debug("Successfully added spthy language from: " .. parser_path)
    else
      log_debug("ERROR adding language: " .. tostring(add_err))
      print("ERROR: " .. tostring(add_err))
    end
  else
    log_debug("vim.treesitter.language.add not available, trying alternative loading methods")
  end
end

-- Try to validate the query file
local query_file = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
log_debug("Loading query file: " .. query_file)

local success, content = pcall(vim.fn.readfile, query_file)
if not success then
  log_debug("ERROR reading query file: " .. tostring(content))
  print("ERROR: " .. tostring(content))
  vim.cmd('qa!')
  return
end

local content_str = table.concat(content, "\n")

-- Try to parse the query file
local parse_success, result = pcall(function()
  return vim.treesitter.query.parse('spthy', content_str)
end)

if not parse_success then
  log_debug("ERROR parsing query: " .. tostring(result))
  print("ERROR parsing query: " .. tostring(result))
  log_file:close()
  vim.cmd('qa!')
  return
end

log_debug("Query validation successful!")
log_file:close()
print("SUCCESS: Query file is valid")
EOF

# Run Neovim with our validation script
nvim --headless \
     -c "luafile /tmp/validate_query.lua" \
     -c "qa!" 2>> $ERROR_LOG

echo "Debug log contents:"
echo "------------------------------------------------------------"
cat "$DEBUG_LOG" 2>/dev/null || echo "No debug log found"
echo "------------------------------------------------------------"

# Check if debug log contains any errors
if grep -q "ERROR" "$DEBUG_LOG" 2>/dev/null; then
    echo "ERRORS DETECTED in validation:"
    grep -A 2 "ERROR" "$DEBUG_LOG"
    exit 1
else
    echo "Query validation successful. Highlights.scm file is valid."
    exit 0
fi

# Clean up
rm -f /tmp/validate_query.lua 