# Hypothesis H19: Invalid Node Types in Query File

## Hypothesis Statement

The TreeSitter syntax highlighting for Tamarin is failing because the `highlights.scm` query file contains references to node types that don't exist in the actual Tamarin/Spthy grammar.

## Background

Our tests revealed an error in the query file validation: `Query error at 18:4. Invalid node type "protocol": "protocol" ^`. This suggests that the `highlights.scm` file is trying to highlight a node type called "protocol" that doesn't exist in the parser's grammar.

TreeSitter query files must reference valid node types from the grammar. If a node type mentioned in the query doesn't exist in the grammar, TreeSitter will fail to parse the query, resulting in syntax highlighting failures.

## Test Approach

1. Identify the invalid node types in the current `highlights.scm` file
2. Validate the actual node types supported by the Tamarin/Spthy grammar
3. Create a revised query file that only references valid node types

## Test Implementation

### Step 1: Extract the actual node types from the Tamarin parser

First, we need to determine what node types the Tamarin/Spthy parser actually supports:

```lua
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
```

### Step 2: Analyze current query file for invalid node types

Next, we need to identify which node types in our current query file are invalid:

```lua
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
  if not ok then
    return "Query parse error: " .. result
  end
  
  -- Extract node types mentioned in the query
  local node_types = {}
  for line in content:gmatch("[^\r\n]+") do
    -- Look for node types in parentheses
    for node_type in line:gmatch("%(([%w_]+)") do
      if node_type ~= "match" and node_type ~= "eq" and node_type ~= "not" then
        node_types[node_type] = true
      end
    end
  end
  
  -- Convert to array
  local result = {}
  for type, _ in pairs(node_types) do
    table.insert(result, type)
  end
  table.sort(result)
  
  return result
end

return analyze_query_file()
```

### Step 3: Create a test script to run the tests

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="/tmp/h19_test.spthy"
RESULTS_FILE="$SCRIPT_DIR/test_results.txt"

# Create a simple test file
cat > "$TEST_FILE" << 'EOF'
theory Test
begin

builtins: symmetric-encryption, hashing

rule Simple:
    [ ] --[ ]-> [ ]

rule WithVariables:
    let x' = 'foo'
    let y' = 'bar'
    in
    [ In(x') ] --[ Processed(x', y') ]-> [ Out(y') ]

lemma secrecy:
    "∀ x' #i. Secret(x') @ i ⟹ ¬(∃ #j. K(x') @ j)"

end
EOF

# Create test Lua files
NODE_TYPES_FILE="$SCRIPT_DIR/h19_node_types_test.lua"
QUERY_ANALYSIS_FILE="$SCRIPT_DIR/h19_query_analysis.lua"

# Run Neovim in headless mode
nvim --headless -u NORC \
  -c "set rtp+=$(cd ~/.config/nvim && pwd)" \
  -c "lua package.path = '$(cd ~/.config/nvim && pwd)/lua/?.lua;' .. package.path" \
  -c "lua vim.opt.runtimepath:append('$(cd ~/.config/nvim && pwd)')" \
  -c "lua require('tamarin').setup()" \
  -c "e $TEST_FILE" \
  -c "lua local node_types = dofile('$NODE_TYPES_FILE'); local query_types = dofile('$QUERY_ANALYSIS_FILE'); vim.fn.writefile({string.format('SUPPORTED NODE TYPES:'), unpack(type(node_types) == 'table' and node_types or {tostring(node_types)}), '', string.format('NODE TYPES IN QUERY:'), unpack(type(query_types) == 'table' and query_types or {tostring(query_types)})}, '$RESULTS_FILE')" \
  -c "qa!"

# Display test results
if [ -f "$RESULTS_FILE" ]; then
  echo "=== TEST RESULTS ==="
  cat "$RESULTS_FILE"
  echo "===================="
else
  echo "Test failed: No results file generated"
  exit 1
fi

# Clean up
rm -f "$TEST_FILE"
```

## Expected Results

If the hypothesis is correct, we expect to find node types in the query file that don't exist in the actual grammar, including specifically the "protocol" node type mentioned in the error message.

## Next Steps

1. Based on the findings, create a fixed version of the query file that only references valid node types
2. Test the updated query file to verify that it resolves the highlighting issues
3. Update the main implementation accordingly

These tests will help us determine if invalid node types are indeed the cause of our syntax highlighting issues. 