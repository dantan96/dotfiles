-- highlight_debugger.lua
-- A utility to debug and log syntax highlighting information

local M = {}

-- Constants
local DEBUG_LOG_FILE = vim.fn.stdpath("cache") .. "/highlight_debug.log"
local TAMARIN_FILE = vim.fn.stdpath("config") .. "/test/tamarin/test.spthy"
local HIGHLIGHT_TIMEOUT = 1000 -- ms to wait for highlighting to complete

-- Initialize log file
local function init_log_file()
  local f = io.open(DEBUG_LOG_FILE, "w")
  if f then
    f:write("Syntax Highlighting Debug Log\n")
    f:write("=========================\n\n")
    f:write("Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    f:write("File: " .. TAMARIN_FILE .. "\n\n")
    f:write("Buffer: " .. vim.fn.bufnr() .. "\n\n")
    f:write("Filetype: " .. vim.api.nvim_buf_get_option(vim.fn.bufnr(), "filetype") .. "\n\n")
    f:write("tamarin_treesitter_initialized: " .. tostring(vim.g.tamarin_treesitter_initialized) .. "\n")
    f:write("tamarin_highlight_debug: " .. tostring(vim.g.tamarin_highlight_debug) .. "\n")
    f:write("tamarin_loaded: " .. tostring(vim.g.tamarin_loaded) .. "\n\n")
    f:write("TREESITTER STATUS:\n")
    f:write("TreeSitter active for buffer: " .. tostring(vim.treesitter.highlighter.active[vim.fn.bufnr()] ~= nil) .. "\n")
    f:write("Spthy parser available: " .. tostring(pcall(vim.treesitter.language.inspect, "spthy")) .. "\n")
    f:write("Tamarin parser available: " .. tostring(pcall(vim.treesitter.language.inspect, "tamarin")) .. "\n")
    f:write("Query path: " .. (vim.api.nvim_get_runtime_file("queries/spthy/highlights.scm", false)[1] or "Not found") .. "\n\n")
    f:write("HIGHLIGHT GROUPS:\n")
    local highlight_groups = {
      "@keyword", "@function", "@variable", "@variable.public", "@variable.fresh",
      "@fact.persistent", "@fact.linear", "@operator", "@punctuation.bracket",
      "@comment"
    }
    for _, group in ipairs(highlight_groups) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
      if ok and hl then
        local fg = hl.fg and string.format("#%06x", hl.fg) or "None"
        local bg = hl.bg and string.format("#%06x", hl.bg) or "None"
        f:write(string.format("%-25s fg=%-10s bg=%-10s bold=%-5s italic=%-5s\n", 
          group, fg, bg, 
          tostring(hl.bold or false), tostring(hl.italic or false)))
      else
        f:write(group .. ": Not defined\n")
      end
    end
    f:write("\nSAMPLE HIGHLIGHTING AT KEY POSITIONS:\n")
    local positions = {
      {1, 2, "Comment"},
      {5, 0, "Keyword 'theory'"},
      {5, 8, "Theory name"},
      {6, 0, "Keyword 'begin'"},
      {8, 0, "Keyword 'builtins'"},
      {8, 10, "Builtin type"},
      {11, 0, "Keyword 'functions'"},
      {11, 12, "Function name"},
      {12, 0, "Keyword 'equations'"},
      {12, 20, "Operator '='"},
      {15, 0, "Keyword 'lemma'"},
      {15, 10, "Lemma name"},
      {15, 23, "Lemma attribute"},
      {21, 0, "Keyword 'rule'"},
      {21, 7, "Rule name"},
      {22, 3, "Bracket '['"}, 
      {22, 4, "Built-in fact 'Fr'"},
      {22, 7, "Fresh variable '~id'"},
      {23, 3, "Action fact start '--['"},
      {23, 6, "Action fact name 'OnlyOnce'"},
      {23, 26, "Public variable '$A'"},
      {24, 3, "Persistent fact '!User'"},
      {26, 0, "Keyword 'end'"}
    }
    for _, pos in ipairs(positions) do
      local row, col, desc = unpack(pos)
      row = row - 1  -- Convert to 0-based
      
      local char = get_char_at_pos(vim.fn.bufnr(), row, col)
      local info = get_syntax_at_pos(vim.fn.bufnr(), row, col)
      
      f:write("\n" .. desc .. " (line " .. (row+1) .. ", col " .. (col+1) .. ", char '" .. char .. "'):\n")
      f:write("  Vim syntax: " .. info.syntax.name .. 
          (info.syntax.name ~= info.syntax.trans_name and " -> " .. info.syntax.trans_name or "") .. "\n")
      f:write("  Color: fg=" .. info.syntax.fg .. ", bg=" .. info.syntax.bg .. 
          (info.syntax.bold and ", bold" or "") .. 
          (info.syntax.italic and ", italic" or "") .. 
          (info.syntax.underline and ", underline" or "") .. "\n")
      
      if #info.treesitter > 0 then
        f:write("  TreeSitter captures:\n")
        for _, capture in ipairs(info.treesitter) do
          f:write("    - " .. capture.capture .. " (node: " .. capture.node_type .. ")\n")
        end
      else
        f:write("  TreeSitter captures: None\n")
      end
    end
    f:write("\nSUMMARY:\n")
    f:write("TreeSitter highlighting: " .. (vim.treesitter.highlighter.active[vim.fn.bufnr()] ~= nil and "Active" or "Not active") .. "\n")
    f:write("Traditional syntax highlighting: " .. (vim.treesitter.highlighter.active[vim.fn.bufnr()] == nil and "Active" or "Fallback") .. "\n")
    f:write("\nDebug information written to: " .. DEBUG_LOG_FILE .. "\n")
    f:close()
    return true
  else
    vim.notify("Failed to create debug log file: " .. DEBUG_LOG_FILE, vim.log.levels.ERROR)
    return false
  end
end

-- Log to file
local function log(msg)
  local f = io.open(DEBUG_LOG_FILE, "a")
  if f then
    f:write(msg .. "\n")
    f:close()
    return true
  end
  return false
end

-- Helper to get syntax information at a position
local function get_syntax_at_pos(bufnr, row, col)
  -- Get traditional syntax
  local synID = vim.fn.synID(row + 1, col + 1, 1)
  local syn_name = vim.fn.synIDattr(synID, "name")
  local trans_id = vim.fn.synIDtrans(synID)
  local trans_name = vim.fn.synIDattr(trans_id, "name")
  local fg_color = vim.fn.synIDattr(trans_id, "fg#")
  local bg_color = vim.fn.synIDattr(trans_id, "bg#")
  local is_bold = vim.fn.synIDattr(trans_id, "bold") == "1"
  local is_italic = vim.fn.synIDattr(trans_id, "italic") == "1"
  local is_underline = vim.fn.synIDattr(trans_id, "underline") == "1"
  
  -- Get TreeSitter syntax
  local ts_captures = {}
  pcall(function()
    local parser = vim.treesitter.get_parser(bufnr, "spthy")
    if parser then
      local tree = parser:parse()[1]
      local root = tree:root()
      
      -- Find the node at this position
      local node = root:named_descendant_for_range(row, col, row, col)
      
      -- Get captures
      if node then
        local query = vim.treesitter.query.get("spthy", "highlights")
        if query then
          for id, node_match, metadata in query:iter_captures(root, bufnr, row, row + 1) do
            local range = {node_match:range()}
            local node_row, node_col, node_end_row, node_end_col = unpack(range)
            
            if node_row == row and node_col <= col and node_end_col > col then
              local name = query.captures[id]
              table.insert(ts_captures, {
                capture = name,
                node_type = node_match:type()
              })
            end
          end
        end
      end
    end
  end)
  
  return {
    syntax = {
      id = synID,
      name = syn_name ~= "" and syn_name or "None",
      trans_name = trans_name ~= "" and trans_name or "None",
      fg = fg_color ~= "" and fg_color or "None",
      bg = bg_color ~= "" and bg_color or "None",
      bold = is_bold,
      italic = is_italic,
      underline = is_underline
    },
    treesitter = ts_captures
  }
end

-- Get character at position
local function get_char_at_pos(bufnr, row, col)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  if line and col < #line then
    return line:sub(col + 1, col + 1)
  end
  return ""
end

-- Analyze a specific file and log the highlighting information
function M.analyze_file()
  -- Verify required files
  if not vim.fn.filereadable(TAMARIN_FILE) then
    vim.notify("Test file not found: " .. TAMARIN_FILE, vim.log.levels.ERROR)
    return false
  end
  
  -- Initialize log
  if not init_log_file() then return false end
  
  -- Create a new buffer and load the test file
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "test_tamarin.spthy")
  local lines = vim.fn.readfile(TAMARIN_FILE)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "tamarin")
  
  -- Ensure highlighting has time to apply
  vim.defer_fn(function()
    log("ANALYSIS OF TAMARIN SYNTAX HIGHLIGHTING")
    log("--------------------------------------")
    log("File: " .. TAMARIN_FILE)
    log("Buffer: " .. bufnr)
    log("Filetype: " .. vim.api.nvim_buf_get_option(bufnr, "filetype"))
    
    -- Log vim.g values that might affect highlighting
    log("\nGLOBAL VARIABLES:")
    log("tamarin_treesitter_initialized: " .. tostring(vim.g.tamarin_treesitter_initialized))
    log("tamarin_highlight_debug: " .. tostring(vim.g.tamarin_highlight_debug))
    log("tamarin_loaded: " .. tostring(vim.g.tamarin_loaded))
    
    -- Check if TreeSitter is active
    local has_ts = false
    pcall(function()
      has_ts = vim.treesitter.highlighter.active[bufnr] ~= nil
    end)
    log("\nTREESITTER STATUS:")
    log("TreeSitter active for buffer: " .. tostring(has_ts))
    
    -- Check parser availability
    local spthy_parser_ok = pcall(vim.treesitter.language.inspect, "spthy")
    local tamarin_parser_ok = pcall(vim.treesitter.language.inspect, "tamarin")
    log("Spthy parser available: " .. tostring(spthy_parser_ok))
    log("Tamarin parser available: " .. tostring(tamarin_parser_ok))
    
    -- Check query path
    local query_path = vim.api.nvim_get_runtime_file("queries/spthy/highlights.scm", false)[1]
    log("Query path: " .. (query_path or "Not found"))
    
    -- Check highlight groups
    log("\nHIGHLIGHT GROUPS:")
    local highlight_groups = {
      "@keyword", "@function", "@variable", "@variable.public", "@variable.fresh",
      "@fact.persistent", "@fact.linear", "@operator", "@punctuation.bracket",
      "@comment"
    }
    
    for _, group in ipairs(highlight_groups) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
      if ok and hl then
        local fg = hl.fg and string.format("#%06x", hl.fg) or "None"
        local bg = hl.bg and string.format("#%06x", hl.bg) or "None"
        log(string.format("%-25s fg=%-10s bg=%-10s bold=%-5s italic=%-5s", 
          group, fg, bg, 
          tostring(hl.bold or false), tostring(hl.italic or false)))
      else
        log(group .. ": Not defined")
      end
    end
    
    -- Sample highlighting at different positions
    log("\nSAMPLE HIGHLIGHTING AT KEY POSITIONS:")
    
    -- Define key positions to check in the test file (line, col, description)
    local positions = {
      {1, 2, "Comment"},
      {5, 0, "Keyword 'theory'"},
      {5, 8, "Theory name"},
      {6, 0, "Keyword 'begin'"},
      {8, 0, "Keyword 'builtins'"},
      {8, 10, "Builtin type"},
      {11, 0, "Keyword 'functions'"},
      {11, 12, "Function name"},
      {12, 0, "Keyword 'equations'"},
      {12, 20, "Operator '='"},
      {15, 0, "Keyword 'lemma'"},
      {15, 10, "Lemma name"},
      {15, 23, "Lemma attribute"},
      {21, 0, "Keyword 'rule'"},
      {21, 7, "Rule name"},
      {22, 3, "Bracket '['"}, 
      {22, 4, "Built-in fact 'Fr'"},
      {22, 7, "Fresh variable '~id'"},
      {23, 3, "Action fact start '--['"},
      {23, 6, "Action fact name 'OnlyOnce'"},
      {23, 26, "Public variable '$A'"},
      {24, 3, "Persistent fact '!User'"},
      {26, 0, "Keyword 'end'"}
    }
    
    for _, pos in ipairs(positions) do
      local row, col, desc = unpack(pos)
      row = row - 1  -- Convert to 0-based
      
      local char = get_char_at_pos(bufnr, row, col)
      local info = get_syntax_at_pos(bufnr, row, col)
      
      log("\n" .. desc .. " (line " .. (row+1) .. ", col " .. (col+1) .. ", char '" .. char .. "'):")
      log("  Vim syntax: " .. info.syntax.name .. 
          (info.syntax.name ~= info.syntax.trans_name and " -> " .. info.syntax.trans_name or ""))
      log("  Color: fg=" .. info.syntax.fg .. ", bg=" .. info.syntax.bg .. 
          (info.syntax.bold and ", bold" or "") .. 
          (info.syntax.italic and ", italic" or "") .. 
          (info.syntax.underline and ", underline" or ""))
      
      if #info.treesitter > 0 then
        log("  TreeSitter captures:")
        for _, capture in ipairs(info.treesitter) do
          log("    - " .. capture.capture .. " (node: " .. capture.node_type .. ")")
        end
      else
        log("  TreeSitter captures: None")
      end
    end
    
    -- Summary
    log("\nSUMMARY:")
    log("TreeSitter highlighting: " .. (has_ts and "Active" or "Not active"))
    log("Traditional syntax highlighting: " .. (not has_ts and "Active" or "Fallback"))
    log("\nDebug information written to: " .. DEBUG_LOG_FILE)
    
    -- Clean up
    vim.api.nvim_buf_delete(bufnr, {force = true})
    
    -- Notify user
    vim.notify("Highlighting analysis completed. Log file: " .. DEBUG_LOG_FILE, 
               vim.log.levels.INFO)
    
    -- Display log file path in message area
    print("Highlighting analysis completed. Log file: " .. DEBUG_LOG_FILE)
  end, HIGHLIGHT_TIMEOUT)
  
  return true
end

-- Run the analyzer immediately
function M.run()
  return M.analyze_file()
end

return M 