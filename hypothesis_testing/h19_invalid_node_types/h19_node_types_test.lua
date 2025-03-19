-- h19_node_types_test.lua
local function get_node_types()
  -- Try to get the language info
  if not vim.treesitter.language then
    return "TreeSitter language module not available"
  end
  
  -- Check if the language is registered
  local ok, lang = pcall(vim.treesitter.language.get, 'spthy')
  if not ok or not lang then
    return "Failed to get spthy language: " .. tostring(lang)
  end
  
  -- Get parser for current buffer
  local parser_ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
  if not parser_ok or not parser then
    return "Failed to get parser: " .. tostring(parser)
  end
  
  -- Get a reference file parsed
  local testfile = [[
  theory Test
  begin
  
  builtins: symmetric-encryption, hashing
  functions: f/1, g/2
  equations: f(x) = g(x, x)
  
  rule Simple:
      [ ] --[ ]-> [ ]
  
  rule WithVariables:
      let x = 'foo'
      let y = 'bar'
      in
      [ In(x) ] --[ Processed(x, y) ]-> [ Out(y) ]
  
  lemma secrecy:
      "∀ x #i. Secret(x) @ i ⟹ ¬(∃ #j. K(x) @ j)"
  
  end
  ]]
  
  -- Parse the test content
  local tree = parser:parse_string(testfile, nil, nil, true)
  
  if not tree or #tree == 0 then
    return "Failed to parse test content"
  end
  
  -- Get root node
  local root = tree[1]:root()
  
  -- Collect node types using a visitor function
  local node_types = {}
  local function visit(node)
    local type = node:type()
    node_types[type] = true
    
    for child in node:iter_children() do
      visit(child)
    end
  end
  
  visit(root)
  
  -- Convert to sorted array
  local result = {}
  for type, _ in pairs(node_types) do
    table.insert(result, type)
  end
  table.sort(result)
  
  return result
end

return get_node_types() 