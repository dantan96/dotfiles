;; Enhanced Tamarin Syntax Highlighting
;; Using validated node types detected through syntax tree analysis
;; Implementing many of the highlighting groups defined in tamarin-highlights.lua

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

;; Variable identifiers in terms
((ident) @variable.message
 (#has-parent? @variable.message msg_var_or_nullary_fun))

;; Function identifiers for built-in facts
((ident) @function.builtin
 (#has-parent? @function.builtin linear_fact)
 (#any-of? @function.builtin "In" "Out" "Fr" "K"))

;; Function identifiers for crypto operations
((ident) @function.builtin
 (#any-of? @function.builtin "senc" "sdec" "mac" "kdf" "pk" "h"))

;; Facts - with different styles
(action_fact) @fact.action
(linear_fact) @fact.linear

;; Rule structure elements
(premise) @premise
(conclusion) @conclusion
(simple_rule) @rule.simple

;; Special tokens
["--[" "]->"] @operator
[":" "(" ")"] @operator
["[" "]"] @punctuation.delimiter

;; Trace elements
(trace_quantifier) @keyword.quantifier

;; Message components and terms
;; When parent node is exp_term, mul_term, etc.
((ident) @variable.message
 (#has-ancestor? @variable.message mset_term))

;; When ident is inside argument of a linear_fact
((ident) @variable.message
 (#has-ancestor? @variable.message arguments)
 (#has-ancestor? @variable.message linear_fact))

;; Error nodes for debugging
(ERROR) @error 