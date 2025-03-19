;; Enhanced Tamarin Syntax Highlighting
;; Using validated node types detected through syntax tree analysis

;; Keywords - using direct token identification
[
  "theory"
  "begin"
  "end"
  "rule"
  "lemma"
] @keyword

;; Identifiers - using the ident node type with text predicates for differentiation
;; Theory names
((theory
   (ident) @type))

;; Rule identifiers - without using invalid field name
((simple_rule
   (rule)
   (ident) @function.rule))

;; Variable identifiers
((msg_var_or_nullary_fun
   (ident) @variable))

;; Function identifiers for In/Out
((linear_fact
   (ident) @function.builtin)
 (#any-of? @function.builtin "In" "Out" "Fr" "K"))

;; Facts
(action_fact) @fact.action
(linear_fact) @fact.linear

;; Rule structure
(premise) @premise
(conclusion) @conclusion
(simple_rule) @rule.simple

;; Special tokens
["--[" "]->"] @operator
[":" "(" ")"] @operator
["[" "]"] @punctuation.delimiter

;; Trace elements
(exists-trace) @keyword.quantifier
(trace_quantifier) @keyword.quantifier

;; Error nodes for debugging
(ERROR) @error 