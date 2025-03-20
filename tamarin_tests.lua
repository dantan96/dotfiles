-- tamarin_tests.lua
-- Standalone test script for Tamarin TreeSitter integration
-- Run with: nvim --headless -l tamarin_tests.lua

-- Setup colors for output
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

local function print_colored(msg, color)
  print(color .. msg .. colors.reset)
end

local function format_result(name, success, message)
  if success then
    return colors.green .. "✓" .. colors.reset .. " " .. name .. ": " .. message
  else 
    return colors.red .. "✗" .. colors.reset .. " " .. name .. ": " .. message
  end
end

-- Run tests
local results = {}
local all_pass = true

print_colored("Running Tamarin TreeSitter tests...", colors.blue)

-- Test 1: Check if spthy parser is available
local has_parser = pcall(vim.treesitter.language.inspect, "spthy")
table.insert(results, format_result(
  "Parser Availability", 
  has_parser, 
  has_parser and "spthy parser is available" or "spthy parser is NOT available"
))

if not has_parser then
  all_pass = false
  print_colored("Parser test failed, skipping remaining tests", colors.red)
else
  -- Test 2: Check if highlight query exists
  local has_highlight_query = pcall(vim.treesitter.query.get, "spthy", "highlights")
  table.insert(results, format_result(
    "Highlight Query",
    has_highlight_query,
    has_highlight_query and "Highlight query exists" or "Highlight query does not exist"
  ))
  
  if not has_highlight_query then all_pass = false end
  
  -- Test 3: Simple parser test on a string
  local test_string = [[
theory Basic begin
builtins: hashing
end
]]
  
  local parser_test_success = pcall(function() 
    local parser = vim.treesitter.get_string_parser(test_string, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    return root ~= nil
  end)
  
  table.insert(results, format_result(
    "Basic Parsing",
    parser_test_success,
    parser_test_success and "Successfully parsed basic theory" or "Failed to parse basic theory"
  ))
  
  if not parser_test_success then all_pass = false end
  
  -- Test 4: Check parse tree structure for correctness
  local complex_string = [[
theory TestHighlighting
begin

builtins: diffie-hellman, hashing, symmetric-encryption, signing

/* Types and function declarations */
functions: f/1, g/2, test/3
equations: f(g(x,y)) = h(<x,y>)

/* Security properties */
lemma secrecy_of_key [reuse]:
  "All A B k #i.
    Secret(k, A, B)@i ==>
    not (Ex #j. K(k)@j)
    | (Ex X #r. Reveal(X)@r & Honest(X)@i)"

/* Rule block with annotations, facts and terms */
rule Register_User:
  [ Fr(~id), Fr(~ltk) ]
  --[ OnlyOnce(), Create($A, ~id), LongTermKey($A, ~ltk) ]->
  [ !User($A, ~id, ~ltk), !Pk($A, pk(~ltk)), Out(pk(~ltk)) ]

end
]]

  local structure_test_success = false
  local structure_message = "Failed to verify parse tree structure"
  
  -- Debug mode to print actual node types found
  local debug_mode = false
  local found_node_types = {}
  
  local success, result = pcall(function()
    local parser = vim.treesitter.get_string_parser(complex_string, "spthy")
    local tree = parser:parse()[1]
    local root = tree:root()
    
    if debug_mode then
      local function collect_node_types(node)
        if not node then return end
        
        local node_type = node:type()
        found_node_types[node_type] = true
        
        -- Check children
        for child, _ in node:iter_children() do
          collect_node_types(child)
        end
      end
      
      collect_node_types(root)
    end
    
    -- Define expected node types based on debug output
    local expected_nodes = {
      "theory",
      "built_ins", 
      "built_in",
      "functions", 
      "function_pub",
      "lemma",
      "lemma_attrs",
      "lemma_attr",
      "rule",
      "simple_rule",
      "premise",
      "action_fact",
      "conclusion",
      "persistent_fact",
      "linear_fact"
    }
    
    -- Check if required node types exist in the tree 
    local found_nodes = {}
    local found_all = true
    
    local function check_node_types(node)
      if not node then return end
      
      local node_type = node:type()
      found_nodes[node_type] = true
      
      -- Check children
      for child, _ in node:iter_children() do
        check_node_types(child)
      end
    end
    
    check_node_types(root)
    
    -- Verify all expected node types were found
    for _, expected_type in ipairs(expected_nodes) do
      if not found_nodes[expected_type] then
        found_all = false
        structure_message = "Missing node type: " .. expected_type
        break
      end
    end
    
    return found_all
  end)
  
  -- If in debug mode and there was a failure, print all found node types
  if debug_mode and (not success or not result) then
    local found_types = {}
    for node_type, _ in pairs(found_node_types) do
      table.insert(found_types, node_type)
    end
    table.sort(found_types)
    
    print("\nFound node types:")
    for _, node_type in ipairs(found_types) do
      print("- " .. node_type)
    end
  end
  
  structure_test_success = success and result == true
  
  if structure_test_success then
    structure_message = "Parse tree contains all expected node types"
  end
  
  table.insert(results, format_result(
    "Tree Structure",
    structure_test_success,
    structure_message
  ))
  
  if not structure_test_success then all_pass = false end
end

-- Print test results
print("\n" .. colors.cyan .. "=== Tamarin TreeSitter Test Results ===" .. colors.reset)
for _, result in ipairs(results) do
  print(result)
end

print("\n" .. (all_pass and colors.green or colors.red) ..
  "Overall: " .. (all_pass and "PASS" or "FAIL") .. colors.reset)

-- Exit correctly
if all_pass then
  vim.cmd('quit!')
else 
  vim.cmd('cquit!')
end 