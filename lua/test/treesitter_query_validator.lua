-- treesitter_query_validator.lua
-- A module for validating TreeSitter queries and providing suggestions

local M = {}

-- Configuration
local config = {
  debug = true,
  strict_mode = true, -- More stringent validation
  output_dir = vim.fn.expand("~/temp_files")
}

-- Set up logging
local function log(msg, level)
  level = level or vim.log.levels.INFO
  if config.debug then
    vim.notify("[QueryValidator] " .. msg, level)
  end
end

-- Get all node types available in a language's grammar
function M.get_available_node_types(lang)
  -- This is challenging since TreeSitter doesn't easily expose this info
  -- We'll use a combination of strategies:
  
  -- 1. Create a buffer with content in the target language
  -- 2. Parse it with the language's parser
  -- 3. Traverse the resulting tree to collect all node types
  
  local node_types = {}
  
  -- Try to get a parser for the language
  local parser_ok, parser = pcall(function()
    -- Create a temporary buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    
    -- Use a small sample of content
    local sample = ""
    if lang == "spthy" or lang == "tamarin" then
      sample = "theory Test\nbegin\nrule Test:\n [ ] --[ ]-> [ ]\nend"
    else
      sample = "// Sample content for parsing\n// This is just a placeholder"
    end
    
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(sample, "\n"))
    
    -- Get parser for buffer
    local parser = vim.treesitter.get_parser(bufnr, lang)
    
    -- Parse content
    local tree = parser:parse()[1]
    local root = tree:root()
    
    -- Collect node types recursively
    local function collect_node_types(node)
      local type = node:type()
      node_types[type] = true
      
      for child, _ in node:iter_children() do
        collect_node_types(child)
      end
    end
    
    collect_node_types(root)
    
    -- Clean up
    vim.api.nvim_buf_delete(bufnr, { force = true })
    
    return node_types
  end)
  
  if not parser_ok then
    log("Failed to get node types for language " .. lang .. ": " .. tostring(parser), vim.log.levels.WARN)
    return {}
  end
  
  return vim.tbl_keys(node_types)
end

-- Print the syntax tree of sample content in a language
function M.print_syntax_tree(lang, sample_content, output_path)
  output_path = output_path or (config.output_dir .. "/syntax_tree_" .. lang .. ".txt")
  
  -- Ensure output directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(output_path, ":h"), "p")
  
  -- Create a temp buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Set sample content
  local lines = vim.split(sample_content, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  -- Try to get a parser
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not parser_ok or not parser then
    log("Failed to get parser for language " .. lang, vim.log.levels.ERROR)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return false, "Failed to get parser"
  end
  
  -- Parse content
  local tree_ok, tree = pcall(function() return parser:parse()[1] end)
  if not tree_ok or not tree then
    log("Failed to parse tree: " .. tostring(tree), vim.log.levels.ERROR)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return false, "Failed to parse tree"
  end
  
  local root = tree:root()
  
  -- Open output file
  local out_file = io.open(output_path, "w")
  if not out_file then
    log("Failed to open output file: " .. output_path, vim.log.levels.ERROR)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return false, "Failed to open output file"
  end
  
  -- Function to print tree recursively
  local function print_tree(node, indent, field_name)
    indent = indent or 0
    local padding = string.rep("  ", indent)
    
    -- Get node info
    local node_type = node:type()
    local start_row, start_col, end_row, end_col = node:range()
    local text = vim.treesitter.get_node_text(node, bufnr)
    
    -- Truncate text if necessary
    if text and #text > 40 then
      text = text:sub(1, 37) .. "..."
    end
    
    -- Remove newlines for display
    if text then
      text = text:gsub("\n", "\\n")
      text = '"' .. text .. '"'
    else
      text = ""
    end
    
    -- Print node info
    local field_prefix = field_name and ("Field: " .. field_name .. " -> ") or ""
    out_file:write(padding .. field_prefix .. "(" .. node_type .. ") " ..
                  "[" .. start_row .. ":" .. start_col .. " - " .. 
                  end_row .. ":" .. end_col .. "] " .. text .. "\n")
    
    -- Print children
    for child, field in node:iter_children() do
      print_tree(child, indent + 1, field)
    end
  end
  
  -- Write header
  out_file:write("SYNTAX TREE FOR LANGUAGE: " .. lang .. "\n")
  out_file:write("=================================\n\n")
  
  -- Write original content
  out_file:write("CONTENT:\n")
  out_file:write("---------\n")
  out_file:write(sample_content)
  out_file:write("\n\n")
  
  -- Write tree
  out_file:write("SYNTAX TREE:\n")
  out_file:write("------------\n")
  print_tree(root, 0)
  
  -- Close file and clean up
  out_file:close()
  vim.api.nvim_buf_delete(bufnr, { force = true })
  
  log("Syntax tree written to " .. output_path)
  return true, output_path
end

-- Check if a query string is valid
function M.validate_query(lang, query_string)
  -- Try to parse query
  local ok, result = pcall(vim.treesitter.query.parse, lang, query_string)
  
  if not ok then
    -- Parse error
    return {
      valid = false,
      error = result,
      captures = {}
    }
  end
  
  -- Query is valid - extract captures
  local captures = {}
  for id, name in pairs(result.captures) do
    captures[name] = true
  end
  
  return {
    valid = true,
    query = result,
    captures = vim.tbl_keys(captures)
  }
end

-- Check if node types used in a query exist in the language grammar
function M.validate_node_types(lang, query_string)
  -- First get all available node types in the language
  local available_types = M.get_available_node_types(lang)
  local available_types_map = {}
  for _, type in ipairs(available_types) do
    available_types_map[type] = true
  end
  
  -- Parse the query string to an AST to inspect used node types
  -- This is a simplified approach - a proper parser for the query language would be better
  local used_types = {}
  local issues = {}
  
  -- Simple extraction of node types from query string
  for type in query_string:gmatch("%(([%w_]+)") do
    -- Skip common non-node-type patterns in queries
    if type ~= "or" and type ~= "not" and type ~= "set" and type ~= "any-of" and
       type ~= "has-parent" and type ~= "has-ancestor" and type ~= "match" and 
       type ~= "eq" and not type:match("^#") then
      used_types[type] = true
      
      -- Check if type exists
      if not available_types_map[type] and type ~= "_" and type ~= "ERROR" and type ~= "MISSING" then
        table.insert(issues, {
          type = type,
          issue = "Node type not found in language grammar"
        })
      end
    end
  end
  
  return {
    used_types = vim.tbl_keys(used_types),
    available_types = available_types,
    issues = issues
  }
end

-- Validate a query file
function M.validate_query_file(lang, query_path)
  log("Validating query file: " .. query_path)
  
  -- Read query file
  local content_ok, content = pcall(vim.fn.readfile, query_path)
  if not content_ok then
    return {
      valid = false,
      error = "Failed to read query file: " .. tostring(content)
    }
  end
  
  local query_string = table.concat(content, "\n")
  
  -- Check syntax validity
  local validation = M.validate_query(lang, query_string)
  
  -- Check node types if query is valid
  local node_type_validation = {}
  if validation.valid then
    node_type_validation = M.validate_node_types(lang, query_string)
  end
  
  -- Merge results
  local result = vim.tbl_extend("force", validation, {
    node_types = node_type_validation,
    query_string = query_string,
    query_path = query_path
  })
  
  return result
end

-- Generate suggestions for fixing query issues
function M.suggest_query_fixes(validation_result)
  if validation_result.valid then
    if #validation_result.node_types.issues == 0 then
      return { "Query is valid with no node type issues." }
    end
    
    local suggestions = {}
    table.insert(suggestions, "Query is syntactically valid but has node type issues:")
    
    for _, issue in ipairs(validation_result.node_types.issues) do
      -- Check if there's a similar type name (typo)
      local similar_types = {}
      for _, available_type in ipairs(validation_result.node_types.available_types) do
        -- Very basic similarity check - could be improved
        if available_type:sub(1, 3) == issue.type:sub(1, 3) or
           available_type:find(issue.type, 1, true) or
           issue.type:find(available_type, 1, true) then
          table.insert(similar_types, available_type)
        end
      end
      
      local suggestion = "- Node type '" .. issue.type .. "' not found. "
      
      if #similar_types > 0 then
        suggestion = suggestion .. "Did you mean: " .. table.concat(similar_types, ", ") .. "?"
      else
        suggestion = suggestion .. "No similar node types found. Check the syntax tree to confirm available types."
      end
      
      table.insert(suggestions, suggestion)
    end
    
    -- Suggest printing the syntax tree
    table.insert(suggestions, "Run print_syntax_tree() to see all available node types in your language.")
    
    return suggestions
  else
    -- Query has syntax errors
    local suggestions = {}
    table.insert(suggestions, "Query has syntax errors:")
    table.insert(suggestions, "- " .. validation_result.error)
    
    -- Common error suggestions
    if validation_result.error:find("Unexpected character") then
      table.insert(suggestions, "Check for mismatched parentheses or invalid characters.")
    elseif validation_result.error:find("expected.*capture") then
      table.insert(suggestions, "Ensure all captures are properly formatted with '@' prefix.")
    elseif validation_result.error:find("unexpected.*after") then
      table.insert(suggestions, "Check the syntax around predicates like #eq?, #match?, etc.")
    end
    
    return suggestions
  end
end

-- Write validation report to file
function M.write_validation_report(validation_result, output_path)
  output_path = output_path or (config.output_dir .. "/query_validation_" .. 
                                vim.fn.fnamemodify(validation_result.query_path, ":t") .. ".txt")
  
  -- Ensure output directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(output_path, ":h"), "p")
  
  -- Open output file
  local out_file = io.open(output_path, "w")
  if not out_file then
    log("Failed to open output file: " .. output_path, vim.log.levels.ERROR)
    return false
  end
  
  -- Write header
  out_file:write("QUERY VALIDATION REPORT\n")
  out_file:write("=====================\n\n")
  out_file:write("Query file: " .. validation_result.query_path .. "\n")
  out_file:write("Valid: " .. tostring(validation_result.valid) .. "\n\n")
  
  -- Write error if invalid
  if not validation_result.valid then
    out_file:write("ERROR:\n")
    out_file:write(validation_result.error .. "\n\n")
  end
  
  -- Write captures
  out_file:write("CAPTURES:\n")
  if #validation_result.captures == 0 then
    out_file:write("No captures defined.\n")
  else
    for _, capture in ipairs(validation_result.captures) do
      out_file:write("- @" .. capture .. "\n")
    end
  end
  out_file:write("\n")
  
  -- Write node type issues if available
  if validation_result.node_types and validation_result.node_types.issues then
    out_file:write("NODE TYPE ISSUES:\n")
    if #validation_result.node_types.issues == 0 then
      out_file:write("No node type issues found.\n")
    else
      for _, issue in ipairs(validation_result.node_types.issues) do
        out_file:write("- '" .. issue.type .. "': " .. issue.issue .. "\n")
      end
    end
    out_file:write("\n")
    
    -- Write used types
    out_file:write("USED NODE TYPES:\n")
    for _, type in ipairs(validation_result.node_types.used_types) do
      out_file:write("- " .. type .. "\n")
    end
    out_file:write("\n")
    
    -- Write available types (limit to first 50 for brevity)
    out_file:write("AVAILABLE NODE TYPES (first 50):\n")
    for i, type in ipairs(validation_result.node_types.available_types) do
      if i <= 50 then
        out_file:write("- " .. type .. "\n")
      else
        out_file:write("... and " .. (#validation_result.node_types.available_types - 50) .. " more\n")
        break
      end
    end
  end
  
  -- Write suggestions
  out_file:write("\nSUGGESTIONS:\n")
  local suggestions = M.suggest_query_fixes(validation_result)
  for _, suggestion in ipairs(suggestions) do
    out_file:write(suggestion .. "\n")
  end
  
  -- Close file
  out_file:close()
  log("Validation report written to " .. output_path)
  
  return true
end

-- Validate multiple query files in a directory
function M.validate_query_directory(lang, dir_path, pattern)
  pattern = pattern or "*.scm"
  
  -- Find query files in directory
  local files = vim.fn.glob(dir_path .. "/" .. pattern, false, true)
  
  -- Validate each file
  local results = {}
  for _, file in ipairs(files) do
    local result = M.validate_query_file(lang, file)
    results[file] = result
    
    -- Write report
    M.write_validation_report(result)
  end
  
  return results
end

-- Run an incremental validation process that attempts to fix issues
function M.incremental_validation(lang, query_path, test_file_path)
  log("Starting incremental validation for " .. query_path)
  
  -- 1. First validate the original query
  local validation = M.validate_query_file(lang, query_path)
  
  if validation.valid and #validation.node_types.issues == 0 then
    log("Query is already valid with no issues!")
    return true, validation
  end
  
  -- 2. Back up the original query
  local backup_path = query_path .. ".backup." .. os.time()
  vim.fn.writefile(vim.fn.readfile(query_path), backup_path)
  log("Original query backed up to " .. backup_path)
  
  -- 3. Process the issues incrementally
  local lines = vim.fn.readfile(query_path)
  local modified = false
  
  -- First handle syntax errors
  if not validation.valid then
    log("Query has syntax errors. Attempting to fix...")
    
    -- Create a minimal valid query to start with
    if #lines == 0 or validation.error:find("unexpected end of file") then
      lines = {
        "; Minimal valid query",
        "(theory) @keyword"
      }
      modified = true
    end
    
    -- Handle common syntax errors (simplified approach)
    local new_lines = {}
    for _, line in ipairs(lines) do
      local modified_line = line
      
      -- Fix missing closing parentheses
      local open_count = select(2, line:gsub("%(", ""))
      local close_count = select(2, line:gsub("%)", ""))
      
      if open_count > close_count then
        modified_line = line .. string.rep(")", open_count - close_count)
        modified = true
      end
      
      -- Fix capture format
      if line:find("@%s") then
        modified_line = modified_line:gsub("@%s", "@")
        modified = true
      end
      
      table.insert(new_lines, modified_line)
    end
    
    lines = new_lines
  end
  
  -- Handle node type issues if we have a valid query or fixed the syntax
  if validation.valid or modified then
    for _, issue in ipairs(validation.node_types.issues) do
      log("Handling issue with node type: " .. issue.type)
      
      -- Find similar node types
      local similar_types = {}
      for _, available_type in ipairs(validation.node_types.available_types) do
        if available_type:sub(1, 3) == issue.type:sub(1, 3) or
           available_type:find(issue.type, 1, true) or
           issue.type:find(available_type, 1, true) then
          table.insert(similar_types, available_type)
        end
      end
      
      -- Try to replace the problematic type if we have alternatives
      if #similar_types > 0 then
        log("Found similar types: " .. table.concat(similar_types, ", "))
        
        -- Replace in all lines
        for i, line in ipairs(lines) do
          if line:find("%(%" .. issue.type .. "[%)%s]") then
            local new_line = line:gsub("%(%" .. issue.type .. "([%)%s])", 
                                    "%(" .. similar_types[1] .. "%1")
            if new_line ~= line then
              lines[i] = new_line
              modified = true
              log("Replaced '" .. issue.type .. "' with '" .. similar_types[1] .. "' on line " .. i)
            end
          end
        end
      else
        log("No similar types found for '" .. issue.type .. "'")
        
        -- If it's likely a literal pattern, convert it to a string pattern
        if issue.type:match("^[a-z]+$") then
          for i, line in ipairs(lines) do
            if line:find("%(%" .. issue.type .. "[%)%s]") then
              local new_line = line:gsub("%(%" .. issue.type .. "([%)%s])", 
                                      "\"" .. issue.type .. "\"%1")
              if new_line ~= line then
                lines[i] = new_line
                modified = true
                log("Converted '" .. issue.type .. "' to string literal on line " .. i)
              end
            end
          end
        end
      end
    end
  end
  
  -- Write modified query if changes were made
  if modified then
    vim.fn.writefile(lines, query_path)
    log("Modified query written back to " .. query_path)
    
    -- Validate the modified query
    local new_validation = M.validate_query_file(lang, query_path)
    M.write_validation_report(new_validation)
    
    return true, new_validation
  end
  
  log("No modifications were made to the query.")
  return false, validation
end

return M 