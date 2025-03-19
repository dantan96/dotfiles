-- professionalAttempt/test_highlighting.lua
-- Script to test Tamarin syntax highlighting

-- Expected highlighting for test cases
local expected_highlights = {
  test_macro_definitions = {
    {row = 1, col = 0, expected_capture = "keyword.function", description = "Macro keyword should be highlighted"},
    {row = 1, col = 10, expected_capture = "macro.name", description = "Macro name should be highlighted"},
    {row = 3, col = 10, expected_capture = "macro.name", description = "Macro name with public var should be highlighted"}
  },
  
  test_macro_usage = {
    {row = 2, col = 2, expected_capture = "variable.fresh", description = "Fresh variable should be highlighted"},
    {row = 2, col = 6, expected_capture = "macro.usage", description = "Macro usage should be highlighted"},
    {row = 3, col = 2, expected_capture = "variable", description = "Variable should be highlighted"},
    {row = 3, col = 9, expected_capture = "macro.usage", description = "Macro usage with public var should be highlighted"},
    {row = 3, col = 16, expected_capture = "variable.public", description = "Public variable in macro should maintain highlighting"}
  },
  
  test_preprocessor = {
    {row = 1, col = 0, expected_capture = "keyword.directive", description = "Preprocessor directive should be highlighted"}
  },
  
  test_begin_end = {
    {row = 2, col = 0, expected_capture = "keyword.begin", description = "Begin keyword should be highlighted"},
    {row = 4, col = 0, expected_capture = "keyword.end", description = "End keyword should be highlighted"}
  },
  
  test_special_constants = {
    {row = 3, col = 2, expected_capture = "constant.special", description = "Special constant 'g' should be highlighted"}
  },
  
  test_tactic = {
    {row = 3, col = 2, expected_capture = "keyword.tactic", description = "Tactic keyword should be highlighted"},
    {row = 4, col = 2, expected_capture = "keyword.tactic", description = "Another tactic keyword should be highlighted"}
  },
  
  test_apostrophe_vars = {
    {row = 2, col = 2, expected_capture = "variable.fresh", description = "Variable with apostrophe should be highlighted"}
  },
  
  -- Add more test cases as needed
}

-- Function to test highlighting
local function test_highlighting(filename, expected)
  local bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Read file content
  local file = io.open(filename, "r")
  if not file then
    print("Error: Could not open file " .. filename)
    return {error = "File not found"}
  end
  local content = {}
  for line in file:lines() do
    table.insert(content, line)
  end
  file:close()
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
  
  -- Set filetype
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'tamarin')
  
  -- Enable syntax highlighting
  vim.cmd("syntax on")
  
  -- Use the modern API to enable TreeSitter highlighting
  pcall(function()
    vim.treesitter.start(bufnr)
  end)
  
  -- Load our custom syntax highlighting
  local ok, _ = pcall(function()
    if _G.setup_tamarin_highlights then
      _G.setup_tamarin_highlights()
    end
  end)
  
  -- Give Neovim time to apply the highlighting
  vim.cmd("sleep 100m")
  
  -- Test positions for expected highlights
  local results = {
    passed = 0,
    failed = 0,
    details = {}
  }
  
  for _, test in ipairs(expected) do
    local row, col = test.row, test.col
    
    -- Ensure the position is valid
    if row >= #content or col >= #content[row+1] then
      table.insert(results.details, {
        test = test,
        success = false,
        message = "Invalid position: row " .. row .. ", col " .. col,
        actual = nil
      })
      results.failed = results.failed + 1
      goto continue
    end
    
    local actual = vim.inspect_pos(bufnr, row, col)
    
    -- Compare expected vs actual
    local success = false
    local found_captures = {}
    
    for _, capture in ipairs(actual.treesitter or {}) do
      table.insert(found_captures, capture.capture)
      if capture.capture == test.expected_capture then
        success = true
        break
      end
    end
    
    if success then
      results.passed = results.passed + 1
    else
      results.failed = results.failed + 1
    end
    
    table.insert(results.details, {
      test = test,
      success = success,
      message = success and "Passed" or ("Expected " .. test.expected_capture .. " but found: " .. table.concat(found_captures, ", ")),
      actual = actual
    })
    
    ::continue::
  end
  
  return results
end

-- Run tests for each test file
local all_results = {}

for test_file, tests in pairs(expected_highlights) do
  print("\nTesting " .. test_file .. ".spthy...")
  local results = test_highlighting("professionalAttempt/" .. test_file .. ".spthy", tests)
  all_results[test_file] = results
  
  print(string.format("Results: %d passed, %d failed", results.passed, results.failed))
  
  -- Show details for failures
  for _, detail in ipairs(results.details) do
    if not detail.success then
      print(string.format("✗ %s (row %d, col %d): %s", 
                         detail.test.description,
                         detail.test.row,
                         detail.test.col,
                         detail.message))
    end
  end
end

-- Write results to JSON file for further analysis
local json_file = io.open("professionalAttempt/test_results.json", "w")
json_file:write(vim.json.encode(all_results))
json_file:close()

-- Summary
local total_passed = 0
local total_failed = 0

for _, results in pairs(all_results) do
  total_passed = total_passed + results.passed
  total_failed = total_failed + results.failed
end

print("\nOverall Summary:")
print(string.format("%d tests passed, %d tests failed", total_passed, total_failed))

if total_failed > 0 then
  os.exit(1)
else
  os.exit(0)
end 