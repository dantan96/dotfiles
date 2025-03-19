;; Tamarin Syntax Highlighting - Valid Node Types Only
;; This file contains only valid node types from the parser

;; Keywords can be highlighted using the ident capture with any-of?
((ident) @keyword
 (#any-of? @keyword
  "theory" "begin" "end" "rule" "lemma"
  "let" "in" "functions" "equations" "builtins"
  "restriction" "axiom" "if" "then" "else"
  "exists-trace"))

;; Identifiers - directly capturing the ident node type
(ident) @variable

;; Valid fact types
(action_fact) @fact.action

;; Rule components - directly matching the node types
(premise) @premise
(conclusion) @conclusion

;; Quantifiers
(trace_quantifier) @keyword.quantifier

;; Rule types
(simple_rule) @rule.simple

;; Pre-defined symbols
(pre_defined) @constant

;; Special tokens
[
  "--["
  "]->"
  ":"
] @operator

[
  "["
  "]"
  "\""
] @punctuation.delimiter

;; Error nodes - useful for diagnostics
(ERROR) @error 