;; Minimal Tamarin Protocol Specification Highlighting
;; Only includes basic elements with no regex patterns

;; Core Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "lemma"
  "builtins"
  "functions"
  "equations"
  "predicates"
  "restriction"
  "axiom"
  "diffLemma"
] @keyword

;; Expression keywords
[
  "let"
  "in"
  "new"
  "out"
  "if"
  "then"
  "else"
  "event"
  "insert"
  "delete"
  "lookup"
  "as"
  "lock"
  "unlock"
] @keyword

;; Comments
(multi_comment) @comment
(single_comment) @comment

;; Theory structure
(theory
  theory_name: (ident) @type)

;; Functions
(function_untyped) @function
(function_typed) @function
(nullary_fun) @function

;; Facts
(linear_fact) @fact.linear
(persistent_fact) @fact.persistent
(action_fact) @fact.action

;; Simple variable captures by node type (no regex patterns)
(pub_var) @variable.public
(fresh_var) @variable.fresh
(temporal_var) @variable.temporal
(msg_var_or_nullary_fun) @variable.message
(nat_var) @variable.number

;; Constants and numbers
(natural) @number
(param) @string
(hexcolor) @constant
(pub_name) @public.constant
(fresh_name) @constant.string

;; Punctuation and operators
["(" ")" "[" "]" "<" ">"] @punctuation.bracket
["-->" "-->"] @punctuation.special
["," "." ":" ";"] @punctuation.delimiter
"^" @operator.exponentiation

;; Rule structure
(premise) @structure
(conclusion) @structure
(quantified_formula) @structure
(nested_formula) @structure

;; Logical operators
(imp) @operator.logical
(negation) @operator.logical
(conjunction) @operator.logical
(disjunction) @operator.logical
(iff) @operator.logical

;; Rule parts
(simple_rule 
  rule_identifier: (ident) @function.rule)
(lemma 
  lemma_identifier: (ident) @function.rule)
(restriction
  restriction_identifier: (ident) @function.rule) 