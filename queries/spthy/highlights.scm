;; Improved Tamarin Syntax Highlighting
;; Using node types and avoiding complex regex patterns

;; Keywords - only including verified keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "lemma"
  "let"
  "in"
  "functions"
  "equations"
  "builtins"
  "restriction"
  "axiom"
  "if"
  "then"
  "else"
  "section"
  "subsection"
  "text"
] @keyword

;; Comments
(multi_comment) @comment
(single_comment) @comment

;; Basic types and identifiers
(theory
  theory_name: (ident) @type)

(rule
  rule_name: (ident) @function.rule)

(lemma
  lemma_name: (ident) @function.rule)
  
(restriction
  restriction_name: (ident) @function.rule)

(builtins
  (ident) @type.builtin)

;; Variables (using node types rather than regex)
(variable) @variable
(message_variable) @variable.message
(fresh_variable) @variable.fresh
(public_variable) @variable.public
(temporal_variable) @variable.temporal

;; Facts
(linear_fact) @fact.linear
(persistent_fact) @fact.persistent
(action_fact) @fact.action

;; Functions
(function_name) @function
(function_untyped) @function

;; Numbers and strings
(number) @number
(natural) @number
(string) @string

;; Operators and delimiters
[
  "="
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "+"
  "-"
  "*"
  "/"
  "^"
] @operator

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  ","
  ";"
  ":"
] @punctuation.delimiter

;; Special syntax for action brackets and arrows
(arrow) @punctuation.special
(action_start) @action.brackets
(action_end) @action.brackets 