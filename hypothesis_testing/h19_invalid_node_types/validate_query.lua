local function validate_query(query_path)
  -- Read the query file
  local file = io.open(query_path, 'r')
  if not file then
    return {
      valid = false,
      error = "Could not open query file"
    }
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Try to parse the query
  local ok, result = pcall(vim.treesitter.query.parse, 'spthy', content)
  
  if not ok then
    return {
      valid = false,
      error = result
    }
  end
  
  return {
    valid = true,
    query = result
  }
end

return validate_query(...)
