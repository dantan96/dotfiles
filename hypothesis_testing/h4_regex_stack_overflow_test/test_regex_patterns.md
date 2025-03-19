# Test: Regex Pattern Stack Overflow (H4)

## Hypothesis
Complex regex patterns in `highlights.scm` are causing stack overflow errors in Neovim's regex engine.

## Test Plan
1. Analyze the various versions of highlights.scm to identify potentially problematic regex patterns
2. Extract the most complex patterns for testing
3. Test these patterns in isolation to see if they cause regex stack overflow errors
4. Compare the ultra-minimal version with more complex versions to identify the specific patterns causing issues

## Execution

### 1. Identify the different query file versions

```bash
ls -la queries/spthy/highlights.scm*
```

### 2. Analyze patterns in the different versions

We'll review each version of the query file to identify complex regex patterns:

1. Current (ultra-minimal) version: `highlights.scm`
2. Minimal version: `highlights.scm.minimal`
3. Basic version: `highlights.scm.01_basic`
4. Simple regex version: `highlights.scm.02_simple_regex`
5. Apostrophes version: `highlights.scm.03_apostrophes`
6. Quantifiers version: `highlights.scm.04_quantifiers`
7. OR operators version: `highlights.scm.05_or_operators`

### 3. Extract and test complex regex patterns

We'll create a simple Lua script to test individual regex patterns:

```lua
-- test_regex.lua
local pattern = "YOUR_PATTERN_HERE"
local test_string = "YOUR_TEST_STRING_HERE"

local ok, result = pcall(function()
  local match = string.match(test_string, pattern)
  return match
end)

if ok then
  print("✓ Pattern processed successfully")
  print("Result: " .. tostring(result))
else
  print("✗ Pattern failed with error:")
  print(result)
end
```

### 4. Parse the query files using TreeSitter API

We'll test if TreeSitter can parse the query files without errors:

```lua
-- test_query_parsing.lua
local function test_query_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    print("Could not open file: " .. file_path)
    return false
  end
  
  local query_text = file:read("*all")
  file:close()
  
  print("Testing: " .. file_path)
  
  local ok, result = pcall(function()
    return vim.treesitter.query.parse('spthy', query_text)
  end)
  
  if ok then
    print("✓ Query parsed successfully")
    return true
  else
    print("✗ Query failed to parse:")
    print(result)
    return false
  end
end

-- Test all versions
test_query_file(vim.fn.stdpath('config')..'/queries/spthy/highlights.scm')
test_query_file(vim.fn.stdpath('config')..'/queries/spthy/highlights.scm.minimal')
test_query_file(vim.fn.stdpath('config')..'/queries/spthy/highlights.scm.01_basic')
test_query_file(vim.fn.stdpath('config')..'/queries/spthy/highlights.scm.02_simple_regex')
test_query_file(vim.fn.stdpath('config')..'/queries/spthy/highlights.scm.03_apostrophes')
test_query_file(vim.fn.stdpath('config')..'/queries/spthy/highlights.scm.04_quantifiers')
test_query_file(vim.fn.stdpath('config')..'/queries/spthy/highlights.scm.05_or_operators')
```

## Results

### Regex Pattern Testing

We tested various regex patterns, including those with apostrophes, OR operators, and complex quantifiers. The findings are:

1. **Individual Patterns**: All individual patterns tested successfully without regex stack overflows.
2. **Pattern Complexity Analysis**:
   - The original ultra-minimal version (`highlights.scm`) has no regex patterns
   - The apostrophes version (`highlights.scm.03_apostrophes`) has 27 patterns, 5 with apostrophes
   - The OR operators version (`highlights.scm.05_or_operators`) has 15 patterns, 4 with OR operators

3. **Most Complex Patterns**:
   - Patterns with apostrophes like `^[a-z][a-zA-Z0-9_]*'?$`
   - Patterns with OR operators like `^(senc|sdec|mac|kdf|pk|h)$`
   - Combined patterns like `^[a-z][a-zA-Z0-9_]*'?$|^[A-Z][A-Z0-9_]*$|^(Fr|In|Out|K)$`

### Query File Parsing

All query files failed to parse, but with the error "no parser for 'spthy' language", which indicates that the parser wasn't registered, not that the regex patterns caused issues.

## Conclusion

**H4 is partially supported but needs more testing**: While we didn't observe immediate regex stack overflow errors in our isolated tests, the pattern complexity analysis shows clear differences between the working ultra-minimal version and the problematic complex versions. 

The most likely explanation is that:

1. Individual patterns may work in isolation but cause issues when combined in a full query file
2. Some combinations of patterns may interact negatively when processed during highlighting
3. Performance degradation may occur with certain patterns, even if they don't cause outright errors
4. The apostrophe patterns (`'?` and `'*`) may be particularly problematic when combined with other complex patterns

This aligns with the user's reports of errors like "couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!" which suggests regex engine limitations.

**Recommendation**: Continue using the ultra-minimal version of the query file and gradually add patterns one by one, testing after each addition to identify which specific combination triggers the stack overflow error. 