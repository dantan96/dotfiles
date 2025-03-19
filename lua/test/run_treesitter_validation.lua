-- run_treesitter_validation.lua
-- This script executes the query validator against all TreeSitter query files

-- Load the validator module
local validator = require('test.treesitter_query_validator')

-- Parse command line arguments
local target_file = arg[1]
local target_lang = arg[2]

-- Banner
print("\n" .. string.rep("=", 80))
print("TreeSitter Query Validator")
print(string.rep("=", 80))

-- Run validation based on arguments
local has_errors = false

if target_file then
  -- Validate a specific file
  print("\nValidating specific file: " .. target_file)
  has_errors = not validator.run_file_validation(target_file)
elseif target_lang then
  -- Validate all queries for a specific language
  print("\nValidating all queries for language: " .. target_lang)
  local results = validator.validate_language_queries(target_lang)
  has_errors = validator.print_validation_results({[target_lang] = results})
else
  -- Validate all queries for all languages
  print("\nValidating all TreeSitter queries...")
  local results = validator.validate_all_queries()
  has_errors = validator.print_validation_results(results)
end

-- Print summary and exit with appropriate code
print("\n" .. string.rep("=", 80))
if has_errors then
  print("❌ Validation FAILED - errors were found in TreeSitter queries")
  print("Please fix the errors and run validation again")
  os.exit(1)
else
  print("✅ Validation PASSED - all TreeSitter queries are valid")
  os.exit(0)
end 