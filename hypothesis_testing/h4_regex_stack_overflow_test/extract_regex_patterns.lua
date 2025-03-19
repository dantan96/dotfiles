-- Extract and compare regex patterns from different query files
-- This script extracts patterns from #match directives in query files

-- Helper function to extract regex patterns from a query file
local function extract_patterns(file_path)
  local file = io.open(file_path, "r")
  if not file then
    print("Could not open file: " .. file_path)
    return {}
  end
  
  local content = file:read("*all")
  file:close()
  
  local patterns = {}
  
  -- Look for #match? predicates in the query file
  for pattern in content:gmatch('#match%?%s+@[%w%.]+%s+"([^"]+)"') do
    table.insert(patterns, pattern)
  end
  
  return patterns
end

-- Helper function to get the basename of a file
local function basename(path)
  return path:match("([^/]+)$")
end

-- Configure paths to query files
local config_path = vim.fn.stdpath('config')
local query_files = {
  current = config_path..'/queries/spthy/highlights.scm',
  minimal = config_path..'/queries/spthy/highlights.scm.minimal',
  basic = config_path..'/queries/spthy/highlights.scm.01_basic',
  simple_regex = config_path..'/queries/spthy/highlights.scm.02_simple_regex',
  apostrophes = config_path..'/queries/spthy/highlights.scm.03_apostrophes',
  quantifiers = config_path..'/queries/spthy/highlights.scm.04_quantifiers',
  or_operators = config_path..'/queries/spthy/highlights.scm.05_or_operators'
}

-- Extract patterns from all query files
print("Extracting Regex Patterns from Query Files")
print("=========================================")

local all_patterns = {}

for name, path in pairs(query_files) do
  print("\nExtracting from: " .. basename(path))
  local patterns = extract_patterns(path)
  all_patterns[name] = patterns
  
  print("Found " .. #patterns .. " patterns:")
  for i, pattern in ipairs(patterns) do
    print(i .. ": " .. pattern)
  end
end

-- Compare patterns across different versions
print("\n\nPattern Complexity Analysis")
print("==========================")

-- Count patterns with potentially problematic features
local function analyze_patterns(patterns)
  local results = {
    total = #patterns,
    with_apostrophe = 0,
    with_or = 0,
    with_complex_quantifiers = 0
  }
  
  for _, pattern in ipairs(patterns) do
    if pattern:match("'") then
      results.with_apostrophe = results.with_apostrophe + 1
    end
    
    if pattern:match("|") then
      results.with_or = results.with_or + 1
    end
    
    if pattern:match("[%+%*][%+%*%?]") or pattern:match("%{%d+,") then
      results.with_complex_quantifiers = results.with_complex_quantifiers + 1
    end
  end
  
  return results
end

for name, patterns in pairs(all_patterns) do
  local analysis = analyze_patterns(patterns)
  print("\nAnalysis of " .. name .. " (" .. basename(query_files[name]) .. "):")
  print("  Total patterns: " .. analysis.total)
  print("  With apostrophes: " .. analysis.with_apostrophe)
  print("  With OR operators: " .. analysis.with_or)
  print("  With complex quantifiers: " .. analysis.with_complex_quantifiers)
end

print("\nAnalysis complete") 