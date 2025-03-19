-- treesitter_query_validator.lua
-- A comprehensive TreeSitter query validator that checks for syntax errors,
-- node type validation, and other common problems in query files

local M = {}

-- List of directories to search for query files
local default_query_dirs = {
  vim.fn.stdpath('config') .. '/queries',
  vim.fn.stdpath('data') .. '/site/pack/packer/start/nvim-treesitter/queries',
  vim.fn.stdpath('data') .. '/lazy/nvim-treesitter/queries',
}

-- Utility functions
local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

local function get_grammar_nodes(lang)
  local installed_parsers = vim.api.nvim_get_runtime_files("parser/" .. lang .. ".so", true)
  if #installed_parsers == 0 then
    return nil, "Parser for language '" .. lang .. "' not found. Make sure it's installed."
  end
  
  -- Get all valid node types from the grammar
  local parser = vim.treesitter.get_parser(0, lang)
  if not parser then
    return nil, "Failed to create parser for language '" .. lang .. "'"
  end
  
  local nodes = {}
  local tstree = parser:parse()[1]
  local root = tstree:root()
  
  -- Function to collect all node types
  local function collect_node_types(node, seen)
    seen = seen or {}
    if not node then return seen end
    
    local node_type = node:type()
    seen[node_type] = true
    
    -- Process children
    for child in node:iter_children() do
      collect_node_types(child, seen)
    end
    
    return seen
  end
  
  -- Try to parse a simple example file for this language
  -- This approach won't get all node types, but it's a good start
  local node_types = collect_node_types(root, {})
  
  -- Convert to array for easier use
  local result = {}
  for node_type, _ in pairs(node_types) do
    table.insert(result, node_type)
  end
  
  return result
end

-- Main validation function
function M.validate_query(lang, query_type, query_string)
  local results = {
    errors = {},
    warnings = {},
    info = {},
  }
  
  -- 1. First try to parse the query - this will catch syntax errors
  local ok, parsed_query = pcall(vim.treesitter.query.parse, lang, query_string)
  if not ok then
    local error_msg = parsed_query or "Unknown parsing error"
    table.insert(results.errors, {
      type = "syntax_error",
      message = error_msg,
    })
    return results
  end
  
  -- 2. Get valid node types from the grammar
  local node_types, err = get_grammar_nodes(lang)
  if not node_types then
    table.insert(results.warnings, {
      type = "grammar_load_error",
      message = "Cannot validate against grammar: " .. err,
    })
  else
    -- 3. Extract node types used in the query and validate them
    local used_node_types = {}
    
    -- Define a pattern to extract node types from the query string
    local patterns = {
      -- Match (node_type) patterns
      "%(([%w_-]+)%)",
      
      -- Match node types in predicates
      "#match%? +@%w+ +\"([%w_-]+)\"",
      "#eq%? +@%w+ +\"([%w_-]+)\"",
    }
    
    for _, pattern in ipairs(patterns) do
      for node_type in query_string:gmatch(pattern) do
        used_node_types[node_type] = true
      end
    end
    
    -- Check if node types exist in the grammar
    local node_type_map = {}
    for _, nt in ipairs(node_types) do
      node_type_map[nt] = true
    end
    
    for node_type, _ in pairs(used_node_types) do
      if not node_type_map[node_type] then
        table.insert(results.errors, {
          type = "invalid_node_type",
          message = "Invalid node type: \"" .. node_type .. "\"",
          node_type = node_type,
        })
      end
    end
  end
  
  -- 4. Check for other common issues
  -- Check for capture names that might cause issues
  local capture_pattern = "@([%w_%.]+)"
  local seen_captures = {}
  
  for capture in query_string:gmatch(capture_pattern) do
    if seen_captures[capture] then
      -- Not necessarily an error, but potentially confusing
      table.insert(results.warnings, {
        type = "duplicate_capture",
        message = "Capture name used multiple times: @" .. capture,
        capture = capture,
      })
    end
    seen_captures[capture] = true
    
    -- Check for capture names with potential issues
    if capture:match("%.%.") then
      table.insert(results.warnings, {
        type = "suspicious_capture_name",
        message = "Capture name contains consecutive dots: @" .. capture,
        capture = capture,
      })
    end
  end
  
  return results
end

-- Function to validate a specific query file
function M.validate_query_file(path)
  local file_content = read_file(path)
  if not file_content then
    return {
      errors = {{ type = "file_error", message = "Could not read file: " .. path }}
    }
  end
  
  -- Extract language and query type from path
  local lang, query_type = path:match(".*/([^/]+)/([^/]+)%.scm$")
  if not lang or not query_type then
    return {
      errors = {{ 
        type = "file_path_error", 
        message = "Could not determine language and query type from path: " .. path 
      }}
    }
  end
  
  -- Validate the query
  return M.validate_query(lang, query_type, file_content)
end

-- Function to validate all query files for a language
function M.validate_language_queries(lang)
  local results = {}
  
  -- Find all query files for this language
  for _, dir in ipairs(default_query_dirs) do
    local lang_dir = dir .. '/' .. lang
    local files = vim.fn.glob(lang_dir .. '/*.scm', false, true)
    
    for _, file in ipairs(files) do
      local query_type = vim.fn.fnamemodify(file, ':t:r')
      results[query_type] = M.validate_query_file(file)
      results[query_type].path = file
    end
  end
  
  return results
end

-- Function to validate all query files in the config
function M.validate_all_queries()
  local languages = {}
  
  -- Find all language directories in query paths
  for _, dir in ipairs(default_query_dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local lang_dirs = vim.fn.glob(dir .. '/*', false, true)
      for _, lang_dir in ipairs(lang_dirs) do
        if vim.fn.isdirectory(lang_dir) == 1 then
          local lang = vim.fn.fnamemodify(lang_dir, ':t')
          languages[lang] = true
        end
      end
    end
  end
  
  -- Validate queries for each language
  local results = {}
  for lang, _ in pairs(languages) do
    results[lang] = M.validate_language_queries(lang)
  end
  
  return results
end

-- Utility to print validation results
function M.print_validation_results(results)
  local has_errors = false
  
  -- Print errors and warnings for each language and query type
  for lang, lang_results in pairs(results) do
    local lang_has_errors = false
    
    for query_type, query_results in pairs(lang_results) do
      if type(query_results) == "table" and (
         #query_results.errors > 0 or 
         #query_results.warnings > 0) then
        
        if not lang_has_errors then
          print("\n" .. string.rep("=", 80))
          print("Language: " .. lang)
          print(string.rep("=", 80))
          lang_has_errors = true
        end
        
        local path = query_results.path or "[Unknown path]"
        print("\nQuery: " .. query_type .. " (" .. path .. ")")
        print(string.rep("-", 80))
        
        -- Print errors
        if #query_results.errors > 0 then
          print("ERRORS:")
          for _, err in ipairs(query_results.errors) do
            print("  - " .. err.message)
            has_errors = true
          end
        end
        
        -- Print warnings
        if #query_results.warnings > 0 then
          print("WARNINGS:")
          for _, warn in ipairs(query_results.warnings) do
            print("  - " .. warn.message)
          end
        end
      end
    end
  end
  
  if not has_errors then
    print("\nAll TreeSitter queries validated successfully!")
  end
  
  return has_errors
end

-- Run validation on a specific query file directly
function M.run_file_validation(path)
  local results = M.validate_query_file(path)
  
  print("\nValidation results for: " .. path)
  print(string.rep("=", 80))
  
  if #results.errors > 0 then
    print("ERRORS:")
    for _, err in ipairs(results.errors) do
      print("  - " .. err.message)
    end
  end
  
  if #results.warnings > 0 then
    print("WARNINGS:")
    for _, warn in ipairs(results.warnings) do
      print("  - " .. warn.message)
    end
  end
  
  if #results.errors == 0 and #results.warnings == 0 then
    print("No issues found!")
  end
  
  return #results.errors == 0
end

return M 