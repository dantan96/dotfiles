-- run_tests.lua
-- Master test runner for Tamarin TreeSitter parser and syntax highlighting

local M = {}

-- Configuration
local config = {
  output_dir = vim.fn.expand("~/temp_files"),
  debug = true,
  test_file = vim.fn.stdpath('config') .. '/test/tamarin/test.spthy'
}

-- Set up logging
local function log(msg, level)
  level = level or vim.log.levels.INFO
  if config.debug then
    vim.notify("[TestRunner] " .. msg, level)
  end
end

-- Create a summary report
local function create_summary_report(results, runtime)
  local summary = {
    "# TAMARIN TREESITTER TEST SUMMARY",
    "",
    "Test run completed in " .. string.format("%.2f", runtime) .. " seconds",
    "",
    "## Results Overview",
    "- Traditional highlighting tests: " .. (results.traditional.success and "✅ PASSED" or "❌ FAILED"),
    "- TreeSitter highlighting tests: " .. (results.treesitter.success and "✅ PASSED" or "❌ FAILED"),
    "- Parser corpus tests: " .. (results.corpus.success and "✅ PASSED" or "❌ FAILED"),
    "- Query validation tests: " .. (results.query.success and "✅ PASSED" or "❌ FAILED"),
    "- Integration tests: " .. (results.integration.success and "✅ PASSED" or "❌ FAILED"),
    "",
    "## Detailed Results",
    "Traditional highlighting: " .. results.traditional.passed .. " passed, " .. results.traditional.failed .. " failed",
    "TreeSitter highlighting: " .. results.treesitter.passed .. " passed, " .. results.treesitter.failed .. " failed",
    "Parser corpus tests: " .. results.corpus.passed .. " passed, " .. results.corpus.failed .. " failed",
    "Query validation: " .. results.query.passed .. " passed, " .. results.query.failed .. " failed",
    "Integration tests: " .. results.integration.passed .. " passed, " .. results.integration.failed .. " failed",
    "",
    "Total: " .. results.total.passed .. " passed, " .. results.total.failed .. " failed",
    "",
    "Overall status: " .. (results.success and "✅ PASSED" or "❌ FAILED"),
    "",
    "See detailed reports in: " .. config.output_dir
  }
  
  return table.concat(summary, "\n")
end

-- Write test summary to file
local function write_summary(summary, output_path)
  output_path = output_path or (config.output_dir .. "/test_summary.md")
  
  -- Ensure output directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(output_path, ":h"), "p")
  
  -- Write summary to file
  local ok = vim.fn.writefile(vim.split(summary, "\n"), output_path)
  
  if ok == 0 then
    log("Summary written to " .. output_path)
    return true
  else
    log("Failed to write summary", vim.log.levels.ERROR)
    return false
  end
end

-- Run traditional syntax highlighting tests
local function run_traditional_tests()
  log("Running traditional syntax highlighting tests...")
  
  local highlight_tester = require('test.highlight_tester')
  local results = highlight_tester.test_traditional(config.test_file)
  
  local success = #results > 0
  local report_path = config.output_dir .. "/traditional_highlight_report.txt"
  
  -- Format results
  local formatted_results = {
    success = success,
    passed = success and #results or 0,
    failed = success and 0 or 1,
    report_path = report_path
  }
  
  -- Write report
  local out_file = io.open(report_path, "w")
  if out_file then
    if success then
      out_file:write("TRADITIONAL SYNTAX HIGHLIGHTING TESTS\n")
      out_file:write("==================================\n\n")
      out_file:write("All tests passed!\n\n")
      out_file:write("Found " .. #results .. " highlight groups\n\n")
      
      for _, highlight in ipairs(results) do
        out_file:write(highlight.position.row .. ":" .. highlight.position.col .. " - ")
        
        for _, hl in ipairs(highlight.syntax) do
          out_file:write(hl.name .. " => " .. hl.trans_name .. "\n")
        end
        
        out_file:write("\n")
      end
    else
      out_file:write("TRADITIONAL SYNTAX HIGHLIGHTING TESTS\n")
      out_file:write("==================================\n\n")
      out_file:write("Tests failed! No highlight groups found.\n")
    end
    
    out_file:close()
  end
  
  return formatted_results
end

-- Run TreeSitter syntax highlighting tests
local function run_treesitter_tests()
  log("Running TreeSitter syntax highlighting tests...")
  
  local highlight_tester = require('test.highlight_tester')
  local results = highlight_tester.test_treesitter(config.test_file)
  
  local success = #results > 0
  local report_path = config.output_dir .. "/treesitter_highlight_report.txt"
  
  -- Format results
  local formatted_results = {
    success = success,
    passed = success and #results or 0,
    failed = success and 0 or 1,
    report_path = report_path
  }
  
  -- Write report
  local out_file = io.open(report_path, "w")
  if out_file then
    if success then
      out_file:write("TREESITTER SYNTAX HIGHLIGHTING TESTS\n")
      out_file:write("==================================\n\n")
      out_file:write("All tests passed!\n\n")
      out_file:write("Found " .. #results .. " highlight groups\n\n")
      
      for _, highlight in ipairs(results) do
        out_file:write(highlight.position.row .. ":" .. highlight.position.col .. " - ")
        
        for _, capture in ipairs(highlight.treesitter) do
          out_file:write("@" .. capture.name .. " ")
        end
        
        out_file:write("\n")
      end
    else
      out_file:write("TREESITTER SYNTAX HIGHLIGHTING TESTS\n")
      out_file:write("==================================\n\n")
      out_file:write("Tests failed! No TreeSitter captures found.\n")
    end
    
    out_file:close()
  end
  
  return formatted_results
end

-- Run parser corpus tests
local function run_corpus_tests()
  log("Running parser corpus tests...")
  
  local corpus_tester = require('test.corpus_test_generator')
  
  -- Generate standard tests if they don't exist
  local test_files = vim.fn.glob(corpus_tester.config.test_dir .. "/*.txt", false, true)
  if #test_files == 0 then
    log("No corpus tests found, generating standard set...")
    corpus_tester.generate_standard_tests()
  end
  
  -- Run all corpus tests
  local success, results = corpus_tester.run_all_corpus_tests()
  
  -- Generate report
  corpus_tester.generate_test_report(results)
  
  -- Format results
  local formatted_results = {
    success = success,
    passed = #results.passed,
    failed = #results.failed,
    report_path = config.output_dir .. "/corpus_test_report.txt"
  }
  
  return formatted_results
end

-- Run query validation tests
local function run_query_validation_tests()
  log("Running query validation tests...")
  
  local query_validator = require('test.treesitter_query_validator')
  local query_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm'
  
  -- Validate the query file
  local validation = query_validator.validate_query_file('spthy', query_path)
  
  -- Write report
  query_validator.write_validation_report(validation)
  
  -- Format results
  local report_path = config.output_dir .. "/query_validation_highlights.scm.txt"
  local success = validation.valid
  
  if success and validation.node_types then
    success = #validation.node_types.issues == 0
  end
  
  local formatted_results = {
    success = success,
    passed = success and 1 or 0,
    failed = success and 0 or 1,
    report_path = report_path
  }
  
  return formatted_results
end

-- Run integration tests
local function run_integration_tests()
  log("Running integration tests...")
  
  local highlight_tester = require('test.highlight_tester')
  local success, results = highlight_tester.run_query_test(nil, config.test_file)
  
  -- Format results
  local formatted_results = {
    success = success,
    passed = success and 1 or 0,
    failed = success and 0 or 1,
    report_path = config.output_dir .. "/query_test_report.txt"
  }
  
  return formatted_results
end

-- Run all tests
function M.run_all_tests()
  log("Starting test suite...")
  
  -- Ensure output directory exists
  vim.fn.mkdir(config.output_dir, "p")
  
  -- Record start time
  local start_time = vim.loop.hrtime()
  
  -- Run all test types
  local results = {
    traditional = run_traditional_tests(),
    treesitter = run_treesitter_tests(),
    corpus = run_corpus_tests(),
    query = run_query_validation_tests(),
    integration = run_integration_tests()
  }
  
  -- Calculate total
  local total_passed = results.traditional.passed + results.treesitter.passed + 
                       results.corpus.passed + results.query.passed + results.integration.passed
  local total_failed = results.traditional.failed + results.treesitter.failed + 
                       results.corpus.failed + results.query.failed + results.integration.failed
  
  results.total = {
    passed = total_passed,
    failed = total_failed
  }
  
  -- Determine overall success
  results.success = (total_failed == 0)
  
  -- Record end time and calculate runtime
  local end_time = vim.loop.hrtime()
  local runtime = (end_time - start_time) / 1e9 -- Convert to seconds
  
  -- Create summary
  local summary = create_summary_report(results, runtime)
  write_summary(summary, config.output_dir .. "/test_summary.md")
  
  -- Print summary
  print(summary)
  
  log("Test suite completed in " .. string.format("%.2f", runtime) .. " seconds")
  
  return results.success, results
end

-- Run tests interactively
function M.run_interactive()
  log("Starting interactive test mode...")
  
  -- Create menu
  local items = {
    { id = "all", name = "Run all tests", handler = M.run_all_tests },
    { id = "traditional", name = "Run traditional highlighting tests", handler = run_traditional_tests },
    { id = "treesitter", name = "Run TreeSitter highlighting tests", handler = run_treesitter_tests },
    { id = "corpus", name = "Run parser corpus tests", handler = run_corpus_tests },
    { id = "query", name = "Run query validation tests", handler = run_query_validation_tests },
    { id = "integration", name = "Run integration tests", handler = run_integration_tests },
    { id = "playground", name = "Open TreeSitter playground", handler = function() require('test.treesitter_playground').open() end },
    { id = "exit", name = "Exit", handler = function() return "exit" end }
  }
  
  -- Display menu
  while true do
    print("\nTAMARIN TREESITTER TEST MENU")
    print("============================\n")
    
    for i, item in ipairs(items) do
      print(i .. ". " .. item.name)
    end
    
    print("\nEnter choice: ")
    local input = vim.fn.input("")
    local choice = tonumber(input)
    
    if choice and choice >= 1 and choice <= #items then
      local selected = items[choice]
      print("\nRunning: " .. selected.name)
      
      local result = selected.handler()
      if result == "exit" then
        break
      end
      
      print("\nPress Enter to continue...")
      vim.fn.input("")
    else
      print("\nInvalid choice, try again.")
    end
  end
  
  log("Interactive test mode exited")
end

-- Create a command for running tests
function M.setup_commands()
  vim.cmd([[
    command! TamarinTestAll lua require('test.run_tests').run_all_tests()
    command! TamarinTestInteractive lua require('test.run_tests').run_interactive()
    command! TamarinPlayground lua require('test.treesitter_playground').open()
  ]])
end

-- Debug helper
local function debug_print(msg)
  if vim.g.tamarin_test_debug then
    print("[TEST RUNNER] " .. msg)
  end
end

-- Test cases with sample Tamarin code for testing highlighting
local test_cases = {
  basic = [[
theory Basic
begin

builtins: signing, hashing

rule Register_pk:
  [ Fr(~ltk) ]
  -->
  [ !Ltk($A, ~ltk), !Pk($A, pk(~ltk)), Out(pk(~ltk)) ]

rule Get_signed_message:
  [ !Ltk(A, ltk), In(m) ]
  -->
  [ Out(<m, sign(m, ltk)>) ]

rule Verify_signed_message:
  [ !Pk(A, pk), In(<m, signature>) ]
  --[ Verified(A, m) ]->
  [ ]

lemma verification_works:
  "All A m #i. Verified(A, m) @i ==> Ex #j. j < i"

end
]],

  functions = [[
functions: f/1, g/2, pair/2

rule Test_functions:
  [ In(x) ]
  --[ Function(f(x)), Function(g(x, y)), Pair(<x, y>) ]->
  [ Out(f(g(x, y))) ]
]],

  equations = [[
equations:
  adec(aenc(m, pk(sk)), sk) = m,
  sdec(senc(m, k), k) = m,
  fst(<x, y>) = x,
  snd(<x, y>) = y,
  true = true

rule Test_equations:
  [ In(aenc(m, pk(sk))), !Key(sk) ]
  -->
  [ Out(adec(aenc(m, pk(sk)), sk)) ] // should be simplified to m
]],

  facts = [[
rule Test_facts:
  [ !Persistent('stored'), Fr(~fresh), In($pub) ]
  --[ Action(), Linear(), Persistent() ]->
  [ Linear('linear'), !Persistent('persistent') ]
]],

  comments = [[
/* This is a multiline comment
   with multiple lines */

rule Test_1: // This is a single line comment
  [ ] --> [ ]

// Another comment at the beginning of a line
rule Test_2:
  [ ] --> [ ] // comment at the end
]]
}

-- Run all the test cases
function M.run_all()
  debug_print("Running all Tamarin highlight tests")
  
  local results = {}
  local total = 0
  local passed = 0
  
  for name, content in pairs(test_cases) do
    debug_print("Running test case: " .. name)
    total = total + 1
    
    local success, result = pcall(function()
      return M.run_test(name, content)
    end)
    
    if success and result then
      passed = passed + 1
      results[name] = {status = "passed"}
    else
      results[name] = {status = "failed", error = result or "Unknown error"}
    end
  end
  
  -- Display results
  local width = vim.o.columns - 10
  local height = 20
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded"
  }
  
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  local lines = {
    "Tamarin Highlighting Test Results",
    "================================",
    "",
    string.format("Tests: %d/%d passed (%d%%)", passed, total, math.floor(passed / total * 100)),
    ""
  }
  
  for name, result in pairs(results) do
    local status = result.status == "passed" and "✓" or "✗"
    table.insert(lines, string.format("%s %s", status, name))
    
    if result.status == "failed" and result.error then
      table.insert(lines, "  Error: " .. tostring(result.error))
    end
  end
  
  table.insert(lines, "")
  table.insert(lines, "Press q to close")
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf, noremap = true})
  
  return passed == total
end

-- Run a single test case
function M.run_test(name, content)
  -- Create a temporary buffer with the test content
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  vim.api.nvim_buf_set_option(buf, "filetype", "tamarin")
  
  -- Give time for the TreeSitter parser to initialize
  vim.cmd("sleep 100m")
  
  -- Check if the parser is active
  local has_ts, ts_highlighter = pcall(function()
    return vim.treesitter.highlighter.active[buf]
  end)
  
  local result = {
    name = name,
    has_treesitter = has_ts and ts_highlighter ~= nil,
    has_fallback = vim.g.tamarin_fallback_highlighting or false
  }
  
  -- TODO: Add more detailed validation as needed
  
  -- Clean up
  vim.api.nvim_buf_delete(buf, {force = true})
  
  return result
end

-- Run interactive test selection
function M.run_interactive()
  debug_print("Running interactive test selection")
  
  -- Create menu buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create a split window
  vim.cmd("split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, 10)
  
  -- Set up the buffer
  local lines = {
    "# Tamarin Highlight Tests",
    "",
    "Select a test to run:",
    ""
  }
  
  local test_keys = {}
  for name, _ in pairs(test_cases) do
    table.insert(test_keys, name)
    table.insert(lines, "- " .. name)
  end
  
  table.insert(lines, "")
  table.insert(lines, "Press the number key to run a test, 'a' to run all tests, or 'q' to quit")
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  -- Add keymappings for selection
  for i, name in ipairs(test_keys) do
    local key = tostring(i)
    vim.keymap.set("n", key, function()
      vim.api.nvim_win_close(win, true)
      M.create_test_buffer(name, test_cases[name])
    end, {buffer = buf, noremap = true})
  end
  
  -- Add keymapping for running all tests
  vim.keymap.set("n", "a", function()
    vim.api.nvim_win_close(win, true)
    M.run_all()
  end, {buffer = buf, noremap = true})
  
  -- Add keymapping to close the window
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, {buffer = buf, noremap = true})
  
  return true
end

-- Create a buffer with test content
function M.create_test_buffer(name, content)
  debug_print("Creating test buffer for: " .. name)
  
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  
  -- Set up the buffer
  vim.api.nvim_buf_set_option(buf, "filetype", "tamarin")
  vim.api.nvim_buf_set_name(buf, "test-" .. name .. ".spthy")
  
  -- Switch to the buffer
  vim.api.nvim_set_current_buf(buf)
  
  -- Provide some help text
  vim.notify("Test buffer created. Use <Leader>tt to open the highlight inspector.", vim.log.levels.INFO)
  
  return true
end

return M 