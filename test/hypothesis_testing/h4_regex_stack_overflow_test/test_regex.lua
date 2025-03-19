-- Test regex patterns for stack overflow issues
-- This script tests various regex patterns from the highlights.scm files

-- Helper function to test a pattern
local function test_pattern(pattern, test_string, name)
  print("\nTesting pattern: " .. name)
  print("Pattern: " .. pattern)
  print("Test string: " .. test_string)
  
  local ok, result = pcall(function()
    local match = string.match(test_string, pattern)
    return match
  end)
  
  if ok then
    print("✓ Pattern processed successfully")
    print("Result: " .. tostring(result))
    return true
  else
    print("✗ Pattern failed with error:")
    print(result)
    return false
  end
end

-- Test patterns from different versions of highlights.scm

-- 1. Simple patterns (should work)
test_pattern("^[A-Z][A-Z0-9_]*$", "ABC123", "Simple uppercase identifier")
test_pattern("^[a-z][a-zA-Z0-9_]*$", "abc123", "Simple lowercase identifier")

-- 2. Patterns with apostrophes (potentially problematic)
test_pattern("^[a-z][a-zA-Z0-9_]*'?$", "abc'", "Variable with apostrophe")
test_pattern("^\\$[a-zA-Z][a-zA-Z0-9_]*'?$", "$abc'", "Public variable with apostrophe")
test_pattern("^~[a-zA-Z][a-zA-Z0-9_]*'?$", "~abc'", "Fresh variable with apostrophe")
test_pattern("^#[a-zA-Z][a-zA-Z0-9_]*'?$", "#abc'", "Temporal variable with apostrophe")

-- 3. Complex OR patterns (potentially problematic)
test_pattern("^(senc|sdec|mac|kdf|pk|h)$", "senc", "Built-in function with OR")
test_pattern("^[a-z][a-zA-Z0-9_]*'?$|^[A-Z][A-Z0-9_]*$", "abc'", "Variable OR uppercase identifier")

-- 4. Patterns with complex quantifiers (potentially problematic)
test_pattern("^[a-zA-Z][a-zA-Z0-9_]*'*$", "abc'''", "Variable with multiple apostrophes")
test_pattern("^([a-z][a-zA-Z0-9_]*'*|[A-Z][A-Z0-9_]*)$", "abc'''", "Complex variable pattern with OR and quantifier")
test_pattern("^(Fr|In|Out|K)$|^[A-Z][A-Z0-9_]*$", "TEST", "Built-in facts OR uppercase identifier")

-- 5. Patterns from highlights.scm.03_apostrophes (known problematic)
test_pattern("^[a-z][a-zA-Z0-9_]*'?$", "variable'", "Variable with apostrophe (from 03)")
test_pattern("^\\$[a-zA-Z][a-zA-Z0-9_]*'?$", "$var'", "Public variable with apostrophe (from 03)")

-- 6. Most complex pattern from highlights.scm.05_or_operators
local complex_pattern = "^[a-z][a-zA-Z0-9_]*'?$|^[A-Z][A-Z0-9_]*$|^(Fr|In|Out|K)$"
test_pattern(complex_pattern, "test'", "Most complex pattern with OR operators")

print("\nAll tests completed") 