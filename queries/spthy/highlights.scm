;; Enhanced Tamarin Syntax Highlighting
;; Using node types and avoiding complex regex patterns
;; Utilizing Neovim-specific predicates for better performance

;; Keywords using the optimized any-of? predicate
((ident) @keyword
 (#any-of? @keyword
  "theory" "begin" "end" "rule" "lemma"
  "let" "in" "functions" "equations" "builtins"
  "restriction" "axiom" "if" "then" "else"
  "section" "subsection" "text"
  "modulo" "multiset" "node" "public" "exists"
  "all" "Fr" "In" "Out" "Choose"))

;; Comments
(multi_comment) @comment
(single_comment) @comment

;; Basic types and identifiers
(theory
  theory_name: (ident) @type)

(rule
  rule_name: (ident) @function.rule)

(lemma
  lemma_name: (ident) @function.lemma)
  
(restriction
  restriction_name: (ident) @function.restriction)

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
(function_decl name: (ident) @function.declaration)

;; Protocol steps - frequently used in Tamarin
(protocol_step
  number: (number) @number.step
  name: (ident) @function.step)

;; Numbers and strings
(number) @number
(natural) @number
(string) @string

;; Operators and delimiters
((ident) @operator
 (#any-of? @operator "==" "!="))

[
  "="
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

;; Formula elements like quantifiers (verified as actual node types)
(exists_quantifier) @keyword.quantifier
(forall_quantifier) @keyword.quantifier

;; Terms and message components
(tuple) @structure
(xor) @operator.xor
(chain) @operator.chain

;; Equations and term equality
(equation left: (_) @variable.left right: (_) @variable.right) 

;; Formulas and properties
(formula) @structure.formula
(property) @structure.property 