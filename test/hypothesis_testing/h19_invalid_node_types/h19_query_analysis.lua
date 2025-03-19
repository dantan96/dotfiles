-- h19_query_analysis.lua
local function analyze_query_file()
  -- Read the query file
  local query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
  local file = io.open(query_path, 'r')
  if not file then
    return "Could not open query file"
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Try to parse the query
  local ok, result = pcall(vim.treesitter.query.parse, 'spthy', content)
  
  -- Store the error message for analysis
  local error_message = not ok and result or nil
  
  -- Extract node types mentioned in the query
  local node_types = {}
  for line in content:gmatch("[^\r\n]+") do
    -- Look for node types in parentheses
    for node_type in line:gmatch("%(([%w_]+)") do
      if node_type ~= "match" and node_type ~= "eq" and node_type ~= "not" and 
         node_type ~= "any" and node_type ~= "is" and node_type ~= "set" then
        node_types[node_type] = true
      end
    end
  end
  
  -- Look for keywords in string literals
  local keywords_in_strings = {}
  for line in content:gmatch("[^\r\n]+") do
    for keyword in line:gmatch("\"([%w_]+)\"") do
      keywords_in_strings[keyword] = true
    end
  end
  
  -- Convert to array
  local result = {}
  table.insert(result, "Query parsing: " .. (ok and "SUCCESS" or "FAILED"))
  
  if error_message then
    table.insert(result, "Error: " .. error_message:gsub(".*Invalid node type \"([^\"]+)\".*", "Invalid node type: %1"))
  end
  
  table.insert(result, "")
  table.insert(result, "Node types referenced in the query:")
  
  local node_types_list = {}
  for type, _ in pairs(node_types) do
    table.insert(node_types_list, type)
  end
  table.sort(node_types_list)
  
  for _, type in ipairs(node_types_list) do
    table.insert(result, "- " .. type)
  end
  
  table.insert(result, "")
  table.insert(result, "Keywords in string literals:")
  
  local keywords_list = {}
  for keyword, _ in pairs(keywords_in_strings) do
    table.insert(keywords_list, keyword)
  end
  table.sort(keywords_list)
  
  for _, keyword in ipairs(keywords_list) do
    table.insert(result, "- " .. keyword)
  end
  
  -- Specific analysis for "protocol" keyword
  if keywords_in_strings["protocol"] then
    table.insert(result, "")
    table.insert(result, "NOTE: Found 'protocol' as a string literal in the query file.")
    table.insert(result, "This might be causing the error if used incorrectly.")
    
    -- Look for the problematic line
    local line_number = 1
    for line in content:gmatch("([^\r\n]+)") do
      if line:find("\"protocol\"") then
        table.insert(result, "Line " .. line_number .. ": " .. line:gsub("^%s+", ""))
      end
      line_number = line_number + 1
    end
  end
  
  return result
end

return analyze_query_file() 