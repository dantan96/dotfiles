;; Enhanced Tamarin Syntax Highlighting
;; Using validated node types detected through syntax tree analysis
;; Implementing many of the highlighting groups defined in tamarin-highlights.lua

(single_comment) @comment
(multi_comment) @comment

(pub_name) @public.constant

;; Keywords - using direct token identification
[
  "theory"
  "begin"
  "end"
  "equations"
] @keyword


[
 "builtins"
 "functions"
 "predicates"
 "options"
] @keyword.module

[
 "all-traces"
 "exists-trace"
] @keyword.trace_quantifier


[
 "All"
 "Ex"
 "∀"
 "∃"
] @keyword.quantifier


[
 "rule"
 "lemma"
 "axiom"
 "restriction"
] @keyword.function


[
 "tactic"
 "presort"
 "prio"
 "deprio"
] @keyword.tactic


[
 "sorry"
 "simplify"
 "solve"
 "contradiction"
] @keyword.tactic.value

[
 "macros"
] @keyword.macro


[
 "#ifdef"
 "#endif"
 "#define"
 "#include"
] @preproc

;((ident) @preproc.identifier
; (#has-parent? @preproc 


;; Identifiers - using the ident node type with text predicates for differentiation
;; Theory name
((ident) @type
 (#has-parent? @type theory))

(function_pub function_identifier: (ident)) @function

((ident) @function
 (#has-parent? @function function_pub))

((ident) @function
 (#has-parent? @function function_private))

((natural) @function.arity
 (#has-parent? @function.arity function_pub))

((natural) @function.arity
 (#has-parent? @function.arity function_private))

;; Rule identifiers - using parent and position checking
((ident) @function.rule
 (#has-parent? @function.rule simple_rule))

((ident) @function.rule
 (#has-parent? @function.rule lemma))

((built_in) @function.rule
 (#has-parent? @function.rule built_ins))



;; Variable identifiers in terms
((ident) @variable.message
 (#has-parent? @variable.message msg_var_or_nullary_fun))

(fresh_var variable_identifier: (ident)) @variable.fresh
(pub_var variable_identifier: (ident)) @variable.public
(temporal_var variable_identifier: (ident)) @variable.temporal

;; Function identifiers for built-in facts
((ident) @fact.builtin
 (#has-parent? @fact.builtin linear_fact)
 (#any-of? @fact.builtin "In" "Out" "Fr" "K"))

;; Function identifiers for crypto operations
((ident) @function.builtin
 (#has-parent? @function.builtin nary_app)
 (#any-of? @function.builtin 
  "aenc" 
  "adec" 
  "senc" 
  "sdec" 
  "mac" 
  "kdf" 
  "pk" 
  "h" 
  "verify" 
  "sign" 
  "true"
  "revealSign"
  "revealVerify"
  "getMessage"
  "inv"
  "1"
  "zero"
  "⊕"
  "XOR"
  "zero"
  ))


((ident) @function.builtin
 (#has-parent? @function.builtin function_pub)
 (#any-of? @function.builtin "aenc" "adec" "senc" "sdec" "mac" "kdf" "pk" "h" "verify" "sign" "true" "revealSign" "revealVerify" "getMessage" "inv" "1" "zero" "⊕" "XOR" "zero"))

((ident) @function.builtin
 (#has-parent? @function.builtin function_private)
 (#any-of? @function.builtin "aenc" "adec" "senc" "sdec" "mac" "kdf" "pk" "h" "verify" "sign" "true" "revealSign" "revealVerify" "getMessage" "inv" "1" "zero" "⊕" "XOR" "zero"))

;; Facts - with different styles
(action_fact (linear_fact)) @fact.action

((ident) @fact.linear
 (#has-parent? @fact.linear linear_fact)
 (#not-has-ancestor? @fact.linear action_fact))


((ident) @function.rule
 (#has-parent? @function.rule simple_rule))

((ident) @fact.persistent
(#has-parent? @fact.persistent persistent_fact)
(#not-has-ancestor? @fact.persistent linear_fact)
(#not-has-ancestor? @fact.persistent nary_app)
(#not-has-ancestor? @fact.persistent action_fact))


("!" @fact.persistent
 (#has-parent? @fact.persistent premise))

("!" @fact.persistent
 (#has-parent? @fact.persistent conclusion))


;; Rule structure elements
(premise) @premise
(conclusion) @conclusion
(simple_rule) @rule.simple


;; Special tokens
["--[" "]->"] @operator
["="] @operator.assignment
["^"] @operator.exponentiation
["&" "|" "not" "==>"] @operator.logical
["@"] @operator.at
["[" "]" "<" ">" "(" ")"] @punctuation.bracket
["," ";" ":" "."] @punctuation.delimiter
["-->"] @punctuation.special

;; Trace elements
(trace_quantifier) @keyword.quantifier

;; Message components and terms
;; When parent node is exp_term, mul_term, etc.
;((ident) @variable.message
; (#has-ancestor? @variable.message mset_term))

;; When ident is inside argument of a linear_fact
;((ident) @variable.message
; (#has-ancestor? @variable.message arguments)
; (#has-ancestor? @variable.message linear_fact))

;; Error nodes for debugging
(ERROR) @error 
