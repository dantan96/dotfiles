-- h18_lua_type_conversion_test.lua
-- Test for type conversion issues with TreeSitter highlighter

-- Capture errors
local errors = {}
local orig_error = vim.api.nvim_err_writeln
vim.api.nvim_err_writeln = function(msg)
  table.insert(errors, msg)
  orig_error(msg)
end

-- Steps to reproduce the issue
print("1. Getting parser...")
local parser_ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
print("   Parser result: " .. tostring(parser_ok))

print("2. Creating highlighter...")
local highlighter_ok, highlighter = pcall(vim.treesitter.highlighter.new, parser)
print("   Highlighter result: " .. tostring(highlighter_ok))

print("3. Storing highlighter in buffer variable...")
local store_ok, store_result = pcall(function()
  -- Test different storage approaches
  print("   3.1. Direct assignment")
  local direct_ok, direct_result = pcall(function()
    vim.b[0].ts_highlighter_test1 = highlighter
    return true
  end)
  print("   3.1 Result: " .. tostring(direct_ok))
  
  print("   3.2. Table wrapper")
  local wrapper_ok, wrapper_result = pcall(function()
    vim.b[0].ts_highlighter_test2 = { highlighter = highlighter }
    return true
  end)
  print("   3.2 Result: " .. tostring(wrapper_ok))
  
  print("   3.3. Using nvim_buf_set_var")
  local var_ok, var_result = pcall(function()
    vim.api.nvim_buf_set_var(0, "ts_highlighter_test3", highlighter)
    return true
  end)
  print("   3.3 Result: " .. tostring(var_ok))
  
  print("   3.4. Using a global registry")
  local registry_ok, registry_result = pcall(function()
    -- Create a global registry if it doesn't exist
    if not _G._tamarin_highlighters then
      _G._tamarin_highlighters = {}
    end
    
    -- Store the highlighter in the registry
    local bufnr = vim.api.nvim_get_current_buf()
    _G._tamarin_highlighters[bufnr] = highlighter
    
    -- Store only the reference to the buffer number
    vim.b[bufnr].ts_highlighter_ref = bufnr
    
    return true
  end)
  print("   3.4 Result: " .. tostring(registry_ok))
  
  return true
end)
print("   Storage tests completed: " .. tostring(store_ok))

-- Check if any errors were recorded
print("Recorded errors:")
if #errors == 0 then
  print("No errors recorded")
else
  for i, err in ipairs(errors) do
    print("Error " .. i .. ": " .. err)
  end
end

-- Restore original error function
vim.api.nvim_err_writeln = orig_error

-- Return test results
return {
  parser_ok = parser_ok,
  highlighter_ok = highlighter_ok,
  store_ok = store_ok,
  errors = errors,
  registry_approach_works = _G._tamarin_highlighters ~= nil
} 