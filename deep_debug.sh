#!/bin/bash
set -e

# Setup file paths
LOG_DIR="/tmp/nvim-debug-logs"
MAIN_LOG="$LOG_DIR/main_debug.log"
TRACE_LOG="$LOG_DIR/trace.log"
RUNTIME_LOG="$LOG_DIR/runtime_info.log"
PARSER_LOG="$LOG_DIR/parser_info.log"
QUERY_LOG="$LOG_DIR/query_info.log"
HIGHLIGHT_LOG="$LOG_DIR/highlight_info.log"
ENV_LOG="$LOG_DIR/environment.log"

# Create log directory
mkdir -p "$LOG_DIR"

# Clear previous logs
rm -f $LOG_DIR/*.log

# Log environment info
echo "=== Environment Info ===" > $ENV_LOG
echo "Date: $(date)" >> $ENV_LOG
echo "Neovim version: $(nvim --version | head -1)" >> $ENV_LOG
echo "OS: $(uname -a)" >> $ENV_LOG
echo "User config dir: $HOME/.config/nvim" >> $ENV_LOG
echo "Runtime paths:" >> $ENV_LOG
echo "VIMRUNTIME=$VIMRUNTIME" >> $ENV_LOG
echo "" >> $ENV_LOG

# Create detailed debug script
mkdir -p "$HOME/.config/nvim/lua/debug"
cat > "$HOME/.config/nvim/lua/debug/deep_trace.lua" << 'EOF'
local M = {}

function M.trace_everything()
  local log_dir = "/tmp/nvim-debug-logs"
  local runtime_log = io.open(log_dir .. "/runtime_info.log", "w")
  local parser_log = io.open(log_dir .. "/parser_info.log", "w")
  local query_log = io.open(log_dir .. "/query_info.log", "w")
  local highlight_log = io.open(log_dir .. "/highlight_info.log", "w")
  
  if not runtime_log or not parser_log or not query_log or not highlight_log then
    print("Error: Could not open log files")
    return
  end
  
  -- Runtime paths
  runtime_log:write("=== Runtime Paths ===\n")
  for i, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    runtime_log:write(i .. ": " .. path .. "\n")
  end
  runtime_log:write("\n")
  
  -- runtimepath setting
  runtime_log:write("=== runtimepath option ===\n")
  runtime_log:write(vim.o.runtimepath .. "\n\n")
  
  -- List all .so files in parser directories
  runtime_log:write("=== Parser .so Files ===\n")
  local parser_files = vim.api.nvim_get_runtime_file("parser/**/*.so", true)
  for _, file in ipairs(parser_files) do
    runtime_log:write(file .. "\n")
  end
  runtime_log:write("\n")
  
  -- Get all highlights.scm files
  runtime_log:write("=== Highlights SCM Files ===\n")
  local highlights_files = vim.api.nvim_get_runtime_file("queries/**/highlights.scm", true)
  for _, file in ipairs(highlights_files) do
    runtime_log:write(file .. "\n")
  end
  runtime_log:write("\n")
  
  -- Loaded parsers
  parser_log:write("=== Parser Info ===\n")
  
  -- Check for treesitter module
  parser_log:write("TreeSitter Module Available: " .. 
    tostring(pcall(require, "vim.treesitter")) .. "\n")
  
  -- List all languages with parsers
  parser_log:write("\n=== Available Languages ===\n")
  local langs = {}
  
  if vim.treesitter.language then
    if vim.treesitter.language.get_langs then
      langs = vim.treesitter.language.get_langs()
    end
  end
  
  for lang, _ in pairs(langs) do
    parser_log:write(lang .. "\n")
  end
  
  -- Parser for tamarin/spthy
  parser_log:write("\n=== Tamarin/Spthy Parser Info ===\n")
  
  local info = {
    ["tamarin"] = {},
    ["spthy"] = {}
  }
  
  for lang, _ in pairs(info) do
    info[lang].available = false
    
    -- Check if language is available
    if vim.treesitter.language and vim.treesitter.language.get_lang then
      info[lang].registered = vim.treesitter.language.get_lang(lang) ~= nil
    else
      info[lang].registered = false
    end
    
    -- Try to get parser for this language
    local ok, parser_or_err = pcall(function()
      if vim.treesitter.get_parser then
        local buffer = vim.api.nvim_get_current_buf()
        return vim.treesitter.get_parser(buffer, lang)
      end
      return nil, "get_parser function not available"
    end)
    
    info[lang].parser_loaded = ok and parser_or_err ~= nil
    info[lang].parser_error = ok and "" or parser_or_err
    
    -- Try to get language tree
    if ok and parser_or_err then
      local tree_ok, tree = pcall(function() 
        return parser_or_err:parse()[1]
      end)
      info[lang].tree_loaded = tree_ok and tree ~= nil
      info[lang].tree_error = tree_ok and "" or tree
    else
      info[lang].tree_loaded = false
      info[lang].tree_error = "No parser available"
    end
  end
  
  -- Log parser info
  for lang, data in pairs(info) do
    parser_log:write("Language: " .. lang .. "\n")
    parser_log:write("  Registered: " .. tostring(data.registered) .. "\n")
    parser_log:write("  Parser loaded: " .. tostring(data.parser_loaded) .. "\n")
    if data.parser_error ~= "" then
      parser_log:write("  Parser error: " .. data.parser_error .. "\n")
    end
    parser_log:write("  Tree loaded: " .. tostring(data.tree_loaded) .. "\n")
    if data.tree_error ~= "" then
      parser_log:write("  Tree error: " .. data.tree_error .. "\n")
    end
    parser_log:write("\n")
  end
  
  -- Query info
  query_log:write("=== Query Info ===\n")
  
  -- Log query module availability
  local query_module_ok = pcall(require, "vim.treesitter.query")
  query_log:write("TreeSitter Query Module Available: " .. tostring(query_module_ok) .. "\n\n")
  
  -- Check query functions
  query_log:write("Query Functions Available:\n")
  if vim.treesitter.query then
    query_log:write("  get: " .. tostring(vim.treesitter.query.get ~= nil) .. "\n")
    query_log:write("  get_query: " .. tostring(vim.treesitter.query.get_query ~= nil) .. "\n")
    query_log:write("  parse: " .. tostring(vim.treesitter.query.parse ~= nil) .. "\n")
    query_log:write("  parse_query: " .. tostring(vim.treesitter.query.parse_query ~= nil) .. "\n")
  else
    query_log:write("  No query functions available\n")
  end
  query_log:write("\n")
  
  -- Try to load queries for tamarin and spthy
  query_log:write("=== Loading Queries ===\n")
  
  -- Function to safely get query content
  local function safe_read_file(file_path)
    local file, err = io.open(file_path, "r")
    if not file then
      return nil, "Failed to open file: " .. (err or "unknown error")
    end
    local content = file:read("*all")
    file:close()
    return content
  end
  
  -- Highlight query files for tamarin and spthy
  local query_files = vim.api.nvim_get_runtime_file("queries/{tamarin,spthy}/highlights.scm", true)

  for _, file_path in ipairs(query_files) do
    local lang = file_path:match("queries/([^/]+)/highlights.scm")
    query_log:write("Query file for " .. lang .. ": " .. file_path .. "\n")
    
    -- If file is a symlink, record that
    local is_symlink = vim.fn.resolve(file_path) ~= file_path
    if is_symlink then
      query_log:write("  Is symlink: Yes\n")
      query_log:write("  Points to: " .. vim.fn.resolve(file_path) .. "\n")
    else
      query_log:write("  Is symlink: No\n")
    end
    
    -- Get file content
    local content, read_err = safe_read_file(file_path)
    if not content then
      query_log:write("  Error reading file: " .. read_err .. "\n")
    else
      query_log:write("  File size: " .. #content .. " bytes\n")
      
      -- Try to parse the query
      local parse_ok, parse_result = pcall(function()
        if vim.treesitter.query.parse then
          return vim.treesitter.query.parse(lang, content)
        else
          return nil, "vim.treesitter.query.parse not available"
        end
      end)
      
      if parse_ok and parse_result then
        query_log:write("  Query parsed successfully\n")
      else
        query_log:write("  Query parse error: " .. tostring(parse_result) .. "\n")
      end
      
      -- Try to get query using get function
      local get_ok, get_result = pcall(function()
        if vim.treesitter.query.get then
          return vim.treesitter.query.get(lang, "highlights")
        else
          return nil, "vim.treesitter.query.get not available"
        end
      end)
      
      if get_ok and get_result then
        query_log:write("  Query loaded successfully via get()\n")
      else
        query_log:write("  Query load error via get(): " .. tostring(get_result) .. "\n")
      end
    end
    query_log:write("\n")
  end
  
  -- Examine highlighting
  highlight_log:write("=== Highlight Info ===\n")
  
  -- Current buffer info
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.bo[bufnr].filetype
  
  highlight_log:write("Current buffer: " .. bufnr .. "\n")
  highlight_log:write("Filename: " .. filename .. "\n")
  highlight_log:write("Filetype: " .. filetype .. "\n\n")
  
  -- Get runtime logs
  highlight_log:write("NVIM_LOG_FILE: " .. (vim.env.NVIM_LOG_FILE or "not set") .. "\n\n")
  
  -- Check if nvim-treesitter is loaded
  local has_nvim_treesitter = pcall(require, "nvim-treesitter")
  highlight_log:write("nvim-treesitter plugin loaded: " .. tostring(has_nvim_treesitter) .. "\n")
  
  -- Check highlighting state
  highlight_log:write("\n=== TreeSitter Highlighting Status ===\n")
  if vim.treesitter.highlighter then
    local highlighter = vim.treesitter.highlighter.active[bufnr]
    highlight_log:write("TreeSitter highlighter active: " .. tostring(highlighter ~= nil) .. "\n")
    
    if highlighter then
      highlight_log:write("Highlighter language: " .. tostring(highlighter.lang) .. "\n")
      highlight_log:write("Has queries: " .. tostring(highlighter.queries ~= nil) .. "\n")
    end
  else
    highlight_log:write("TreeSitter highlighter module not available\n")
  end
  
  -- Check highlighting errors
  highlight_log:write("\n=== Error Info ===\n")
  local messages = vim.api.nvim_exec("messages", true)
  highlight_log:write("Messages output:\n" .. messages .. "\n")
  
  -- Close all log files
  runtime_log:close()
  parser_log:close()
  query_log:close()
  highlight_log:close()
end

return M
EOF

# Create debug command script
cat > "$HOME/.config/nvim/debug_commands.vim" << 'EOF'
" Debug commands file
let s:debug = 1

" Load the debug module
lua require('debug.deep_trace').trace_everything()

" Quit when done
qa!
EOF

# Test by opening a Tamarin file
echo "Running debug trace on a Tamarin file..."
export NVIM_LOG_FILE="$TRACE_LOG"
export NVIM_LOG_LEVEL=debug

# Run Neovim with full user config
nvim --cmd "let g:auto_session_enabled = 0" --cmd "source ~/.config/nvim/debug_commands.vim" $HOME/.config/nvim/documentation/professionalAttempt/test.spthy

# Combine logs for analysis
echo "=== Debug Summary ===" > $MAIN_LOG
echo "Date: $(date)" >> $MAIN_LOG
echo "" >> $MAIN_LOG

echo "=== Environment Information ===" >> $MAIN_LOG
cat $ENV_LOG >> $MAIN_LOG
echo "" >> $MAIN_LOG

# Check if we got the specific regex error
if grep -q "couldn't parse regex: Vim:E874" $TRACE_LOG; then
  echo "=== FOUND THE REGEX ERROR ===" >> $MAIN_LOG
  echo "Line from NVIM log:" >> $MAIN_LOG
  grep -A 5 "couldn't parse regex: Vim:E874" $TRACE_LOG >> $MAIN_LOG
  echo "" >> $MAIN_LOG
fi

# Highlight key information about parsers and queries
echo "=== Parsers Found ===" >> $MAIN_LOG
grep -A 4 "Language: tamarin\|Language: spthy" $PARSER_LOG >> $MAIN_LOG
echo "" >> $MAIN_LOG

echo "=== Highlight Query Files ===" >> $MAIN_LOG
grep -A 2 "Query file for tamarin\|Query file for spthy" $QUERY_LOG >> $MAIN_LOG
echo "" >> $MAIN_LOG

echo "=== Query Parse Results ===" >> $MAIN_LOG
grep -E "Query parse error|Query parsed successfully" $QUERY_LOG >> $MAIN_LOG
echo "" >> $MAIN_LOG

echo "Debug information saved to $MAIN_LOG"
echo "All details are in $LOG_DIR directory" 