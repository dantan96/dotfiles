;; Test version of highlights.scm for syntax validation only
;; Using only node types common across most TreeSitter parsers

;; String literals
(string) @string

;; Numbers
(number) @number

;; Basic syntax elements
(identifier) @variable
(function_call) @function
(comment) @comment

;; Basic predicates
((identifier) @function.special
  (#match? @function.special "^special_"))

((identifier) @constant
  (#match? @constant "^[A-Z][A-Z0-9_]*$"))

;; Keywords
[
  "if"
  "else"
  "return"
  "function"
] @keyword

;; The structure that caused problems in the original file
;; Simplified to use only common node types
(call_expression 
  function: (identifier) @function
  arguments: (arguments (identifier) @variable))

;; Testing nested predicates with common constructs
((string) @string.special
  (#match? @string.special "^special"))

;; Testing apostrophe handling in regex patterns
((identifier) @variable.parameter
  (#match? @variable.parameter "^[a-z][a-zA-Z0-9_]*'*$"))

;; Operators and delimiters - these should be valid in any language
["+" "-" "*" "/"] @operator
["," "." ":" ";"] @punctuation.delimiter
["(" ")" "[" "]" "{" "}"] @punctuation.bracket 