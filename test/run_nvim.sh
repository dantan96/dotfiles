#!/bin/bash
set -e

# Setup file paths
LOG_DIR="/tmp/nvim-test-logs"
mkdir -p "$LOG_DIR"
ERROR_LOG="$LOG_DIR/nvim_errors.log"
TREESITTER_LOG="$LOG_DIR/treesitter_info.log"
TEST_FILE="$HOME/.config/nvim/documentation/professionalAttempt/test.spthy"

# Ensure test directory exists
mkdir -p "$(dirname "$TEST_FILE")"

# Log start of test
echo "Starting Neovim test at $(date)" > "$ERROR_LOG"
echo "Testing file: $TEST_FILE" >> "$ERROR_LOG"
echo "-----------------------------------" >> "$ERROR_LOG"

# Set environment variable to capture nvim logs
export NVIM_LOG_FILE="$LOG_DIR/nvim_internal.log"

# Create dump_treesitter_info.lua
mkdir -p "$HOME/.config/nvim/lua"
cat > "$HOME/.config/nvim/lua/dump_treesitter_info.lua" << 'EOF'
return function(output_file)
  local file = io.open(output_file, "w")
  if not file then return end
  
  file:write("TreeSitter Information\n===================\n\n")
  file:write("Runtime paths:\n")
  file:write(vim.inspect(vim.api.nvim_list_runtime_paths()))
  file:write("\n\n")
  
  file:write("Treesitter parsers:\n")
  local parsers = vim.api.nvim_get_runtime_file("parser/*.so", true)
  for _, parser in ipairs(parsers) do
    file:write("  " .. parser .. "\n")
  end
  file:write("\n")
  
  file:write("Query files:\n")
  local queries = vim.api.nvim_get_runtime_file("queries/*/highlights.scm", true)
  for _, query in ipairs(queries) do
    file:write("  " .. query .. "\n")
  end
  file:write("\n")
  
  file:write("Current buffer:\n")
  local bufnr = vim.api.nvim_get_current_buf()
  file:write("  Filetype: " .. vim.bo[bufnr].filetype .. "\n")
  
  -- Try to parse the query file
  for _, query_file in ipairs(queries) do
    local lang = query_file:match("queries/([^/]+)/highlights.scm")
    if lang == "spthy" or lang == "tamarin" then
      file:write("\nTesting query for " .. lang .. ":\n")
      file:write("  File: " .. query_file .. "\n")
      
      local content = io.open(query_file):read("*all")
      local ok, err = pcall(function()
        return vim.treesitter.query.parse(lang, content)
      end)
      
      if ok then
        file:write("  Query parsed successfully\n")
      else
        file:write("  ERROR parsing query: " .. tostring(err) .. "\n")
      end
    end
  end
  
  file:close()
end
EOF

# Run nvim headlessly with timeout
echo "Running Neovim test..."
timeout 10s nvim --headless \
  -c "edit $TEST_FILE" \
  -c "lua require('dump_treesitter_info')('$TREESITTER_LOG')" \
  -c "qa!" \
  2>> "$ERROR_LOG" || echo "Neovim exited with code $?" >> "$ERROR_LOG"

# Check for the specific error
echo "Checking for errors..."
if grep -q -E "couldn't parse regex: Vim:E874" "$NVIM_LOG_FILE" "$ERROR_LOG"; then
  echo "✅ Successfully reproduced the regex error"
  echo "Error found:"
  grep -E "couldn't parse regex: Vim:E874" "$NVIM_LOG_FILE" "$ERROR_LOG"
else
  echo "❌ Did not find the specific regex error"
  echo "Checking for any TreeSitter errors..."
  grep -E "treesitter|regex|parse|query|E5108|stack trace|error" "$NVIM_LOG_FILE" "$ERROR_LOG" || echo "No TreeSitter errors found in logs"
fi

echo "All logs saved to $LOG_DIR"
echo "  - Error log: $ERROR_LOG"
echo "  - Neovim log: $NVIM_LOG_FILE"
echo "  - TreeSitter info: $TREESITTER_LOG"
