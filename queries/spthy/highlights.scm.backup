;; Enhanced Tamarin Syntax Highlighting
;; Safely handles variables with apostrophes using simple patterns

;; Keywords
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
  "protocol"
  "property"
  "all"
  "exists"
  "or"
  "and"
  "not"
  "if"
  "then"
  "else"
] @keyword

;; Comments
(multi_comment) @comment
(single_comment) @comment

;; Basic types
(string) @string
(natural) @number

;; Theory components
(theory
  theory_name: (ident) @type)

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