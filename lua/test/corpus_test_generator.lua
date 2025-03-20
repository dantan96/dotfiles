-- corpus_test_generator.lua 
-- Generate and validate TreeSitter corpus test files for the Tamarin parser

local M = {}

-- Configuration
local config = {
  test_dir = vim.fn.stdpath('config') .. '/test/tamarin/corpus',
  parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so',
  debug = true,
  output_dir = vim.fn.expand("~/temp_files")
}

-- Set up logging
local function log(msg, level)
  level = level or vim.log.levels.INFO
  if config.debug then
    vim.notify("[CorpusTest] " .. msg, level)
  end
end

-- Ensure test directory exists
local function ensure_test_dir()
  -- Create test directory if it doesn't exist
  if vim.fn.isdirectory(config.test_dir) ~= 1 then
    vim.fn.mkdir(config.test_dir, "p")
    log("Created test directory: " .. config.test_dir)
  end
end

-- Ensure parser is loaded
local function ensure_parser_loaded()
  -- Register language mapping
  if vim.treesitter.language and vim.treesitter.language.register then
    vim.treesitter.language.register('spthy', 'tamarin')
  end
  
  -- Check if parser exists
  if vim.fn.filereadable(config.parser_path) ~= 1 then
    return false, "Parser not found at: " .. config.parser_path
  end
  
  -- Load parser explicitly
  if vim.treesitter.language.add then
    local ok, err = pcall(vim.treesitter.language.add, 'spthy', { path = config.parser_path })
    if not ok then
      return false, "Failed to add language: " .. tostring(err)
    end
  end
  
  return true
end

-- Generate a corpus test file
function M.generate_corpus_test(name, content, expected_tree)
  ensure_test_dir()
  
  -- Format the corpus test
  local test_content = {}
  
  -- Add header
  table.insert(test_content, string.rep("=", name:len()))
  table.insert(test_content, name)
  table.insert(test_content, string.rep("=", name:len()))
  table.insert(test_content, "")
  
  -- Add test content
  for _, line in ipairs(vim.split(content, "\n")) do
    table.insert(test_content, line)
  end
  
  -- Add separator
  table.insert(test_content, "")
  table.insert(test_content, "---")
  table.insert(test_content, "")
  
  -- Add expected tree
  if expected_tree then
    for _, line in ipairs(vim.split(expected_tree, "\n")) do
      table.insert(test_content, line)
    end
  else
    -- If no expected tree provided, generate it automatically
    local auto_tree = M.generate_expected_tree(content)
    for _, line in ipairs(auto_tree) do
      table.insert(test_content, line)
    end
  end
  
  -- Write to file
  local file_path = config.test_dir .. "/" .. name:lower():gsub("%s+", "_") .. ".txt"
  local ok = vim.fn.writefile(test_content, file_path)
  
  if ok == 0 then
    log("Generated corpus test: " .. file_path)
    return true, file_path
  else
    log("Failed to write corpus test: " .. file_path, vim.log.levels.ERROR)
    return false, "Failed to write corpus test"
  end
end

-- Generate expected tree from content
function M.generate_expected_tree(content)
  -- Load parser
  local parser_ok, parser_err = ensure_parser_loaded()
  if not parser_ok then
    log("Parser loading failed: " .. parser_err, vim.log.levels.ERROR)
    return { "(ERROR Parser loading failed)" }
  end
  
  -- Create a temporary buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  -- Parse buffer
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_ok or not parser then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    log("Failed to create parser", vim.log.levels.ERROR)
    return { "(ERROR Failed to create parser)" }
  end
  
  local tree_ok, tree = pcall(function() return parser:parse()[1] end)
  if not tree_ok or not tree then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    log("Failed to parse tree: " .. tostring(tree), vim.log.levels.ERROR)
    return { "(ERROR Failed to parse tree)" }
  end
  
  local root = tree:root()
  
  -- Generate S-expression
  local result = {}
  
  -- Function to build S-expression recursively
  local function build_sexp(node, indent)
    indent = indent or 0
    local indent_str = string.rep("  ", indent)
    
    if not node then return end
    
    -- Skip anonymous nodes
    if not node:named() then
      return
    end
    
    local node_type = node:type()
    local has_children = false
    
    for child in node:iter_children() do
      if child:named() then
        has_children = true
        break
      end
    end
    
    if has_children then
      -- Node with children
      table.insert(result, indent_str .. "(" .. node_type)
      
      -- Add children
      for child, field_name in node:iter_children() do
        if child:named() then
          if field_name then
            -- Add field name
            table.insert(result, indent_str .. "  " .. field_name .. ": ")
            -- Remove the last empty string and append to the previous line
            local last = result[#result]
            result[#result] = nil
            build_sexp(child, indent + 1)
            -- Prepend the field name to the first line of the child
            if #result > 0 then
              result[#result] = last .. result[#result]:gsub("^%s+", "")
            end
          else
            build_sexp(child, indent + 1)
          end
        end
      end
      
      table.insert(result, indent_str .. ")")
    else
      -- Leaf node
      table.insert(result, indent_str .. "(" .. node_type .. ")")
    end
  end
  
  -- Build the S-expression
  build_sexp(root, 0)
  
  -- Clean up
  vim.api.nvim_buf_delete(bufnr, { force = true })
  
  return result
end

-- Run a corpus test
function M.run_corpus_test(test_path)
  -- Ensure parser is loaded
  local parser_ok, parser_err = ensure_parser_loaded()
  if not parser_ok then
    log("Parser loading failed: " .. parser_err, vim.log.levels.ERROR)
    return false, parser_err
  end
  
  -- Read test file
  local content_ok, content = pcall(vim.fn.readfile, test_path)
  if not content_ok then
    log("Failed to read test file: " .. tostring(content), vim.log.levels.ERROR)
    return false, "Failed to read test file"
  end
  
  -- Parse test file structure
  local is_header = true
  local separator_index = nil
  
  for i, line in ipairs(content) do
    if line == "---" then
      separator_index = i
      break
    end
  end
  
  if not separator_index then
    log("Invalid test format: Missing separator", vim.log.levels.ERROR)
    return false, "Invalid test format: Missing separator"
  end
  
  -- Extract test content and expected tree
  local test_lines = {}
  local expected_tree_lines = {}
  
  local name_index = 2 -- Assuming name is on the second line
  local name = content[name_index]
  
  -- Skip header and collect content
  for i = 4, separator_index - 2 do
    table.insert(test_lines, content[i])
  end
  
  -- Collect expected tree
  for i = separator_index + 2, #content do
    table.insert(expected_tree_lines, content[i])
  end
  
  -- Create test content
  local test_content = table.concat(test_lines, "\n")
  
  -- Set up a buffer with test content
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, test_lines)
  
  -- Parse the buffer
  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'spthy')
  if not parser_ok or not parser then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    log("Failed to create parser", vim.log.levels.ERROR)
    return false, "Failed to create parser"
  end
  
  local tree_ok, tree = pcall(function() return parser:parse()[1] end)
  if not tree_ok or not tree then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    log("Failed to parse tree: " .. tostring(tree), vim.log.levels.ERROR)
    return false, "Failed to parse tree"
  end
  
  -- Generate actual S-expression
  local actual_tree = M.generate_expected_tree(test_content)
  
  -- Compare expected and actual trees
  local success = true
  local diff_lines = {}
  
  -- Clean up whitespace for comparison
  local clean_expected = {}
  local clean_actual = {}
  
  for _, line in ipairs(expected_tree_lines) do
    table.insert(clean_expected, line:gsub("^%s+", ""))
  end
  
  for _, line in ipairs(actual_tree) do
    table.insert(clean_actual, line:gsub("^%s+", ""))
  end
  
  if #clean_expected ~= #clean_actual then
    success = false
    table.insert(diff_lines, "Tree line count mismatch: expected " .. 
                           #clean_expected .. ", got " .. #clean_actual)
  end
  
  for i = 1, math.min(#clean_expected, #clean_actual) do
    if clean_expected[i] ~= clean_actual[i] then
      success = false
      table.insert(diff_lines, "Line " .. i .. " mismatch:")
      table.insert(diff_lines, "  Expected: " .. clean_expected[i])
      table.insert(diff_lines, "  Actual:   " .. clean_actual[i])
    end
  end
  
  -- Clean up
  vim.api.nvim_buf_delete(bufnr, { force = true })
  
  if success then
    log("Test passed: " .. name)
    return true, name
  else
    log("Test failed: " .. name, vim.log.levels.WARN)
    return false, {
      name = name,
      diff = diff_lines
    }
  end
end

-- Run all corpus tests
function M.run_all_corpus_tests()
  ensure_test_dir()
  
  -- Find all corpus test files
  local test_files = vim.fn.glob(config.test_dir .. "/*.txt", false, true)
  
  if #test_files == 0 then
    log("No corpus tests found in " .. config.test_dir, vim.log.levels.WARN)
    return true, {}
  end
  
  local results = {
    passed = {},
    failed = {}
  }
  
  -- Run each test
  for _, test_file in ipairs(test_files) do
    local ok, result = M.run_corpus_test(test_file)
    if ok then
      table.insert(results.passed, result)
    else
      table.insert(results.failed, result)
    end
  end
  
  -- Print summary
  log(string.format("Tests complete: %d passed, %d failed", 
                  #results.passed, 
                  #results.failed))
  
  return #results.failed == 0, results
end

-- Generate a standard set of corpus tests
function M.generate_standard_tests()
  ensure_test_dir()
  
  local tests = {
    {
      name = "Simple theory",
      content = [[
theory Test
begin
end
]]
    },
    {
      name = "Theory with builtins",
      content = [[
theory Test
begin
builtins: symmetric-encryption, hashing
end
]]
    },
    {
      name = "Theory with simple rule",
      content = [[
theory Test
begin
rule Simple:
  [ ] --[ ]-> [ ]
end
]]
    },
    {
      name = "Rule with variables",
      content = [[
theory Test
begin
rule WithVariables:
  let x = 'foo'
  in
  [ In(x) ] --[ ]-> [ Out(x) ]
end
]]
    },
    {
      name = "Rule with apostrophe variables",
      content = [[
theory Test
begin
rule Apostrophes:
  let x' = 'const'
  in
  [ Fr(~k) ] --[ Secret(x') ]-> [ Out(x') ]
end
]]
    },
    {
      name = "Lemma with quantifiers",
      content = [[
theory Test
begin
lemma secrecy:
  "All x #i. Secret(x) @ i ==> not(Ex #j. K(x) @ j)"
end
]]
    },
    {
      name = "Executable lemma",
      content = [[
theory Test
begin
lemma executable:
  exists-trace
  "Ex x #i. Action(x) @ i"
end
]]
    },
    {
      name = "Comments",
      content = [[
theory Test
begin
// Single line comment
/* Multiline comment
   with multiple lines */
end
]]
    },
    {
      name = "Facts and terms",
      content = [[
theory Test
begin
rule Facts:
  [ Fr(~k), !Ltk($A, ~lk), In(senc(m, ~k)) ]
  --[ Secret(m) ]->
  [ Out(h(m)) ]
end
]]
    }
  }
  
  -- Generate each test
  local results = {}
  for _, test in ipairs(tests) do
    local ok, result = M.generate_corpus_test(test.name, test.content, test.expected_tree)
    if ok then
      table.insert(results, result)
    end
  end
  
  log(string.format("Generated %d standard corpus tests", #results))
  return results
end

-- Update expected output in a corpus test
function M.update_expected_output(test_path)
  -- Read test file
  local content_ok, content = pcall(vim.fn.readfile, test_path)
  if not content_ok then
    log("Failed to read test file: " .. tostring(content), vim.log.levels.ERROR)
    return false, "Failed to read test file"
  end
  
  -- Parse test file structure
  local separator_index = nil
  
  for i, line in ipairs(content) do
    if line == "---" then
      separator_index = i
      break
    end
  end
  
  if not separator_index then
    log("Invalid test format: Missing separator", vim.log.levels.ERROR)
    return false, "Invalid test format: Missing separator"
  end
  
  -- Extract test content
  local test_lines = {}
  local name = content[2] -- Assuming name is on the second line
  
  -- Skip header and collect content
  for i = 4, separator_index - 2 do
    table.insert(test_lines, content[i])
  end
  
  -- Create test content
  local test_content = table.concat(test_lines, "\n")
  
  -- Generate new expected tree
  local new_tree = M.generate_expected_tree(test_content)
  
  -- Create updated test content
  local updated_content = {}
  
  -- Copy header and content
  for i = 1, separator_index do
    table.insert(updated_content, content[i])
  end
  
  -- Add new tree
  for _, line in ipairs(new_tree) do
    table.insert(updated_content, line)
  end
  
  -- Write updated content back to file
  local ok = vim.fn.writefile(updated_content, test_path)
  
  if ok == 0 then
    log("Updated expected output for: " .. test_path)
    return true, test_path
  else
    log("Failed to write updated test: " .. test_path, vim.log.levels.ERROR)
    return false, "Failed to write updated test"
  end
end

-- Generate a full test report
function M.generate_test_report(results, output_path)
  output_path = output_path or (config.output_dir .. "/corpus_test_report.txt")
  
  -- Ensure output directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(output_path, ":h"), "p")
  
  -- Open output file
  local out_file = io.open(output_path, "w")
  if not out_file then
    log("Failed to open output file: " .. output_path, vim.log.levels.ERROR)
    return false
  end
  
  -- Write header
  out_file:write("CORPUS TEST REPORT\n")
  out_file:write("=================\n\n")
  out_file:write(string.format("Tests: %d passed, %d failed\n\n", 
                               #results.passed, 
                               #results.failed))
  
  -- Write failed tests
  if #results.failed > 0 then
    out_file:write("FAILED TESTS\n")
    out_file:write("-----------\n\n")
    
    for _, failed in ipairs(results.failed) do
      out_file:write("Test: " .. failed.name .. "\n")
      out_file:write("Differences:\n")
      
      for _, line in ipairs(failed.diff) do
        out_file:write("  " .. line .. "\n")
      end
      
      out_file:write("\n")
    end
  end
  
  -- Write passed tests
  out_file:write("PASSED TESTS\n")
  out_file:write("-----------\n\n")
  
  for _, passed in ipairs(results.passed) do
    out_file:write("- " .. passed .. "\n")
  end
  
  -- Close file
  out_file:close()
  log("Test report written to " .. output_path)
  
  return true
end

-- Run tests and generate report
function M.run_tests_with_report()
  -- Run all tests
  local success, results = M.run_all_corpus_tests()
  
  -- Generate report
  M.generate_test_report(results)
  
  return success, results
end

return M 