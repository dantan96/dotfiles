;; Enhanced Tamarin Syntax Highlighting
;; Using validated node types detected through syntax tree analysis

;; Keywords - using direct token identification
[
  "theory"
  "begin"
  "end"
  "rule"
  "lemma"
  "exists-trace"
] @keyword

;; Identifiers - using the ident node type with text predicates for differentiation
;; Theory name
((ident) @type
 (#has-parent? @type theory))

;; Rule identifiers - using parent and position checking
((ident) @function.rule
 (#has-parent? @function.rule simple_rule))

;; Variable identifiers
((ident) @variable
 (#has-parent? @variable msg_var_or_nullary_fun))

;; Function identifiers for In/Out
((ident) @function.builtin
 (#has-parent? @function.builtin linear_fact)
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
(trace_quantifier) @keyword.quantifier

;; Error nodes for debugging
(ERROR) @error 