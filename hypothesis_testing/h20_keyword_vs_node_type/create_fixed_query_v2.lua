-- Script to create a fixed query file for Tamarin (v2)
-- H20: Keyword vs Node Type Confusion

-- Function to read a file
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    print("Failed to open file: " .. path)
    return nil
  end
  local content = file:read("*all")
  file:close()
  return content
end

-- Function to write a file
local function write_file(path, content)
  local file = io.open(path, "w")
  if not file then
    print("Failed to open file for writing: " .. path)
    return false
  end
  file:write(content)
  file:close()
  return true
end

-- Create a new query file based on patterns from working examples
-- Key insight: We cannot reference node types that don't exist in the TreeSitter grammar
local new_content = [[
;; Tamarin/Spthy syntax highlighting
;; Fixed based on H20 hypothesis (version 2)

;; Theory components
(theory) @type
(theory
  theory_name: (ident) @type)

;; Keywords - Only include the basic, safe keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "let"
  "in"
  "functions"
  "equations"
  "builtins"
  "lemma"
  "axiom"
  "restriction"
] @keyword

;; Comments
(multi_comment) @comment
(single_comment) @comment

;; Basic types
(string) @string
(natural) @number

;; Functions
(function_untyped) @function
(function_typed) @function

;; Facts
(linear_fact) @constant
(persistent_fact) @constant

;; Variables and constants - using simple predicates
;; Constants (all uppercase) - simple single letter check to avoid regex complexity
((ident) @constant
 (#match? @constant "^[A-Z]"))

;; Variables (all lowercase) - simple single letter check to avoid regex complexity
((ident) @variable
 (#match? @variable "^[a-z]"))

;; Operators
(dyadic_op) @operator
(monadic_op) @operator

;; Other node types
(lemma
  name: (ident) @function.special)

(rule
  name: (ident) @function.method)
]]

-- Write the new query file
local new_path = vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm.h20v2'
if write_file(new_path, new_content) then
  print("Successfully created new query file: " .. new_path)
else
  print("Failed to create new query file")
  os.exit(1)
end

print("Query file creation complete")
os.exit(0) 