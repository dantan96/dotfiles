;; Enhanced Tamarin Syntax Highlighting
;; Modified to use valid node types and safely handle variables with apostrophes

;; Keywords - Using string literals in lists instead of node type 'protocol'
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
  "protocol"  ;; Now correctly as a string literal in a list, not a node type
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