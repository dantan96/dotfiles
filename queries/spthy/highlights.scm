;; Tamarin Syntax Highlighting - Valid Node Types Only
;; This file contains only valid node types from the parser

;; Keywords can be highlighted using the ident capture with any-of?
((ident) @keyword
 (#any-of? @keyword
  "theory" "begin" "end" "rule" "lemma"
  "let" "in" "functions" "equations" "builtins"
  "restriction" "axiom" "if" "then" "else"))

;; Basic tree structure elements
(theory
  theory_name: (ident) @type)

(rule
  rule_name: (ident) @function.rule)

(lemma
  lemma_name: (ident) @function.lemma)

;; Valid fact types
(action_fact) @fact.action

;; Rule components
(premise) @premise
(conclusion) @conclusion

;; Quantifiers
(trace_quantifier) @keyword.quantifier
(exists-trace) @keyword.quantifier

;; Rule types
(simple_rule) @rule.simple

;; Pre-defined symbols
(pre_defined) @constant

;; Symbol tokens - only using verified tokens
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