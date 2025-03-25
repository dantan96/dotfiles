;; Enhanced Tamarin Syntax Highlighting
;; Using validated node types detected through syntax tree analysis
;; Implementing many of the highlighting groups defined in tamarin-highlights.lua

(single_comment) @spthycomment
(multi_comment) @spthycomment

(pub_name) @spthypublic.constant

;; Keywords - using direct token identification
[
  "theory"
  "begin"
  "end"
  "equations"
] @spthykeyword


[
 "builtins"
 "functions"
 "predicates"
 "options"
] @spthykeyword.module

[
 "all-traces"
 "exists-trace"
] @spthykeyword.trace_quantifier


[
 "All"
 "Ex"
 "∀"
 "∃"
] @spthykeyword.quantifier


[
 "rule"
 "lemma"
 "axiom"
 "restriction"
] @spthykeyword.function


[
 "tactic"
 "presort"
 "prio"
 "deprio"
] @spthykeyword.tactic


[
 "sorry"
 "simplify"
 "solve"
 "contradiction"
] @spthykeyword.tactic.value

[
 "macros"
 "let"
 "in"
] @spthykeyword.macro


[
 "#ifdef"
 "#endif"
 "#define"
 "#include"
] @spthypreproc

;((ident) @spthypreproc.identifier
; (#has-parent? @spthypreproc 

(tuple_term) @spthytuple

;; Identifiers - using the ident node type with text predicates for differentiation
;; Theory name
((ident) @spthytype
 (#has-parent? @spthytype theory))

(function_untyped function_identifier: (ident)) @spthyfunction

((ident) @spthyfunction
(#has-parent? @spthyfunction function_untyped))

;; ((ident) @spthyfunction
;;  (#has-parent? @spthyfunction function_private))

((natural) @spthyfunction.arity
(#has-parent? @spthyfunction.arity function_untyped))

;; ((natural) @spthyfunction.arity
;;  (#has-parent? @spthyfunction.arity function_private))

;; Rule identifiers - using parent and position checking
((ident) @spthyfunction.rule
 (#has-parent? @spthyfunction.rule simple_rule))

((ident) @spthyfunction.rule
 (#has-parent? @spthyfunction.rule lemma))

((built_in) @spthyfunction.rule
 (#has-parent? @spthyfunction.rule built_ins))



;; Variable identifiers in terms
((ident) @spthyvariable.message
 (#has-parent? @spthyvariable.message msg_var_or_nullary_fun))

(fresh_var variable_identifier: (ident)) @spthyvariable.fresh
(pub_var variable_identifier: (ident)) @spthyvariable.public
(temporal_var variable_identifier: (ident)) @spthyvariable.temporal

;; Function identifiers for built-in facts
((ident) @spthyfact.builtin
 (#has-parent? @spthyfact.builtin linear_fact)
 (#any-of? @spthyfact.builtin "In" "Out" "Fr" "K" "KU" "KD"))

((ident) @spthyfunction
 (#has-parent? @spthyfunction nary_app))

;; Function identifiers for crypto operations
((ident) @spthyfunction.builtin
 (#has-parent? @spthyfunction.builtin nary_app)
 (#any-of? @spthyfunction.builtin 
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


((ident) @spthyfunction.builtin
 (#has-parent? @spthyfunction.builtin function_pub)
 (#any-of? @spthyfunction.builtin "aenc" "adec" "senc" "sdec" "mac" "kdf" "pk" "h" "verify" "sign" "true" "revealSign" "revealVerify" "getMessage" "inv" "1" "zero" "⊕" "XOR" "zero"))

((ident) @spthyfunction.builtin
 (#has-parent? @spthyfunction.builtin function_private)
 (#any-of? @spthyfunction.builtin "aenc" "adec" "senc" "sdec" "mac" "kdf" "pk" "h" "verify" "sign" "true" "revealSign" "revealVerify" "getMessage" "inv" "1" "zero" "⊕" "XOR" "zero"))

;; Facts - with different styles
((ident) @spthyfact.action
(#has-parent? @spthyfact.action linear_fact)
(#has-ancestor? @spthyfact.action action_fact))
;; (action_fact (linear_fact)) @spthyfact.action

((ident) @spthyfact.linear
 (#has-parent? @spthyfact.linear linear_fact)
 (#not-has-ancestor? @spthyfact.linear action_fact))


((ident) @spthyfunction.rule
 (#has-parent? @spthyfunction.rule simple_rule))

((ident) @spthyfact.persistent
(#has-parent? @spthyfact.persistent persistent_fact)
(#not-has-ancestor? @spthyfact.persistent linear_fact)
(#not-has-ancestor? @spthyfact.persistent nary_app)
(#not-has-ancestor? @spthyfact.persistent action_fact))


("!" @spthyfact.persistent
 (#has-parent? @spthyfact.persistent premise))

("!" @spthyfact.persistent
 (#has-parent? @spthyfact.persistent conclusion))


;; Rule structure elements
(premise) @spthypremise
(conclusion) @spthyconclusion
(simple_rule) @spthyrule.simple


;; Special tokens
["--[" "]->"] @spthyoperator
["="] @spthyoperator.assignment
["^"] @spthyoperator.exponentiation
["&" "|" "not" ] @spthyoperator.logical
["==>"] @spthyoperator.implies
["[" "]" "<" ">" "(" ")"] @spthypunctuation.bracket
["[" "]"] @spthypunctuation.square_bracket
["<" ">"] @spthypunctuation.angle_bracket
["(" ")"] @spthypunctuation.round_bracket
["@"] @spthyoperator.at
(["," ";" ":" "."] @spthypunctuation.delimiter
 (#not-has-ancestor? @spthypunctuation.delimiter tuple_term))
(["," ":" ";"] @spthypunctuation.delimiter_sans_period 
 (#not-has-ancestor? @spthypunctuation.delimiter_sans_period tuple_term))
["."] @spthypunctuation.delimiter.period
([","] @spthypunctuation.delimiter.comma
 (#not-has-ancestor? @spthypunctuation.delimiter.comma tuple_term))
[";"] @spthypunctuation.delimiter.semicolon
[":"] @spthypunctuation.delimiter.colon
["-->"] @spthypunctuation.special

;; Trace elements
(trace_quantifier) @spthykeyword.quantifier

;; Message components and terms
;; When parent node is exp_term, mul_term, etc.
;((ident) @spthyvariable.message
; (#has-ancestor? @spthyvariable.message mset_term))

;; When ident is inside argument of a linear_fact
;((ident) @spthyvariable.message
; (#has-ancestor? @spthyvariable.message arguments)
; (#has-ancestor? @spthyvariable.message linear_fact))

;; Error nodes for debugging
(ERROR) @spthyerror 
