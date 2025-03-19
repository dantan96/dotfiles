-- TreeSitter Regex Pattern Tester
-- Tests different regex patterns for stack overflow issues

local function log(msg)
  print("[regex_test] " .. msg)
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

local function extract_patterns(query_content)
  local patterns = {}
  for pattern in query_content:gmatch("%(#match%? @[%w_]+ \"(.-)\"%)") do
    table.insert(patterns, pattern)
  end
  return patterns
end

local function test_pattern(pattern)
  log("Testing pattern: " .. pattern)
  local success, err = pcall(function()
    -- Try to compile the pattern
    vim.regex(pattern)
  end)
  
  if not success then
    log("FAIL: Pattern caused error: " .. err)
    return false, err
  else
    log("PASS: Pattern compiled successfully")
    return true, nil
  end
end

local function run_tests()
  log("Starting regex pattern tests")
  
  -- Read query file
  local query_path = "./consumables/test/test_regex_patterns.scm"
  local query_content = read_file(query_path)
  if not query_content then
    log("ERROR: Could not read query file: " .. query_path)
    return
  end
  
  -- Extract patterns
  local patterns = extract_patterns(query_content)
  log("Found " .. #patterns .. " patterns to test")
  
  -- Test each pattern
  local results = {
    pass = {},
    fail = {}
  }
  
  for i, pattern in ipairs(patterns) do
    local success, err = test_pattern(pattern)
    if success then
      table.insert(results.pass, pattern)
    else
      table.insert(results.fail, { pattern = pattern, error = err })
    end
  end
  
  -- Report results
  log("\nTest Results:")
  log("Patterns tested: " .. #patterns)
  log("Patterns passed: " .. #results.pass)
  log("Patterns failed: " .. #results.fail)
  
  if #results.fail > 0 then
    log("\nFailed patterns:")
    for i, result in ipairs(results.fail) do
      log(i .. ". " .. result.pattern .. " - Error: " .. result.error)
    end
  end
  
  return results
end

-- Run the tests
local results = run_tests()

-- Write results to file
local output = "# TreeSitter Regex Pattern Test Results\n\n"
output = output .. "## Summary\n\n"
output = output .. "- Patterns tested: " .. (#results.pass + #results.fail) .. "\n"
output = output .. "- Patterns passed: " .. #results.pass .. "\n"
output = output .. "- Patterns failed: " .. #results.fail .. "\n\n"

if #results.fail > 0 then
  output = output .. "## Failed Patterns\n\n"
  for i, result in ipairs(results.fail) do
    output = output .. i .. ". `" .. result.pattern .. "` - Error: " .. result.error .. "\n"
  end
end

output = output .. "\n## Safe Patterns\n\n"
for i, pattern in ipairs(results.pass) do
  output = output .. i .. ". `" .. pattern .. "`\n"
end

local output_file = io.open("./consumables/test/regex_test_results.md", "w")
if output_file then
  output_file:write(output)
  output_file:close()
  log("Results written to regex_test_results.md")
else
  log("ERROR: Could not write to output file")
end 