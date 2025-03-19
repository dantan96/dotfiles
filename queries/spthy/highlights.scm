;; ==============================
;; Tamarin Protocol Specification Highlighting
;; ==============================
;; This file follows a modular approach with clear sectioning
;; and progressive complexity (simple patterns first).

;; ==============================
;; Core Keywords
;; ==============================

;; Theory structure keywords
[
  "theory"
  "begin"
  "end"
] @keyword

;; Statement keywords
[
  "builtins"
  "functions"
  "equations"
  "predicates"
  "restriction"
  "axiom"
  "lemma"
  "diffLemma"
  "rule"
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

;; ==============================
;; Special Keywords
;; ==============================

;; Tactic keyword
"tactic" @keyword.tactic

;; Tactic values (recognized by match predicate)
((ident) @keyword.tactic.value
  (#match? @keyword.tactic.value "^(direct|sorry|induction)$"))

;; Macro keyword (recognized by match predicate)
((ident) @keyword.macro
  (#match? @keyword.macro "^(macro|macros)$"))

;; Quantifiers
[
  "All" "Ex" "∀" "∃"
] @keyword.quantifier

;; ==============================
;; Preprocessor Directives
;; ==============================

;; Simple preprocessor directives
"#ifdef" @preproc
"#endif" @preproc
"#define" @preproc
"#include" @preproc

;; Complex preprocessor node
(preprocessor) @preproc

;; Preprocessor identifiers (inside ifdef)
(ifdef 
  (ident) @preproc.identifier)

;; ==============================
;; Comments
;; ==============================

(multi_comment) @comment
(single_comment) @comment

;; ==============================
;; Theory and Module Structure
;; ==============================

;; Theory name identifier
(theory
  theory_name: (ident) @type)

;; Builtins and modules
(built_in) @type.builtin
(built_ins) @keyword.module
(functions) @keyword.module

;; ==============================
;; Functions and Definitions
;; ==============================

;; Function declarations
(function_untyped) @function

;; Function arities
(function_untyped
  (natural) @variable.number)

;; Function identifiers in various contexts
(function_untyped
  function_identifier: (ident) @function)

(function_typed
  function_identifier: (ident) @function
  function_type: (ident) @type)

(nary_app
  function_identifier: (ident) @function)

;; Built-in functions with special highlighting
((ident) @function.builtin
  (#match? @function.builtin "^(senc|sdec|mac|kdf|pk|h)$"))

;; Nullary functions
(nullary_fun) @function

;; ==============================
;; Macros
;; ==============================

;; Macro definitions
(macro
  macro_identifier: (ident) @function.macro)

;; Macro calls (uppercase identifiers)
((ident) @function.macro.call
  (#match? @function.macro.call "^[A-Z][A-Z0-9_]*$")
  (#not-match? @function.macro.call "^(Fr|In|Out|K)$"))

;; ==============================
;; Function Attributes
;; ==============================

;; Function attribute keywords
[
  "private"
  "destructor"
] @type.qualifier

;; General function attributes
(function_attribute) @type.qualifier

;; ==============================
;; Facts
;; ==============================

;; Different fact types
(linear_fact) @fact.linear
(persistent_fact) @fact.persistent
(action_fact) @fact.action

;; Action fact contents
(action_fact
  (linear_fact) @fact.action)

;; Built-in facts
((linear_fact
  (ident) @fact.builtin)
  (#match? @fact.builtin "^(Fr|In|Out|K)$"))

;; Special markers for facts
"--[" @action.brackets
"]->" @action.brackets
"!" @fact.persistent

;; ==============================
;; Punctuation and Operators
;; ==============================

;; Brackets
["(" ")" "[" "]" "<" ">"] @punctuation.bracket

;; Arrows and special punctuation
["-->"] @punctuation.special

;; Delimiters
["," "." ":" ";"] @punctuation.delimiter

;; Operators
"^" @operator.exponentiation

;; ==============================
;; Variables
;; ==============================

;; Variable types identified by node type
(pub_var) @variable.public
(fresh_var) @variable.fresh
(temporal_var) @variable.temporal
(msg_var_or_nullary_fun) @variable.message
(nat_var) @variable.number

;; ==============================
;; Variables with Type Annotations
;; ==============================

;; Public variables - using simplified regex patterns
((ident) @variable.public
  (#match? @variable.public "^\\$[a-zA-Z][a-zA-Z0-9_]*$"))

((ident) @variable.public
  (#match? @variable.public "^\\$[a-zA-Z][a-zA-Z0-9_]*'$"))

((ident) @variable.public
  (#match? @variable.public "^[a-zA-Z][a-zA-Z0-9_]*:pub$"))

;; Fresh variables - using simplified regex patterns
((ident) @variable.fresh
  (#match? @variable.fresh "^~[a-zA-Z][a-zA-Z0-9_]*$"))

((ident) @variable.fresh
  (#match? @variable.fresh "^~[a-zA-Z][a-zA-Z0-9_]*'$"))

((ident) @variable.fresh
  (#match? @variable.fresh "^[a-zA-Z][a-zA-Z0-9_]*:fresh$"))

;; Temporal variables - using simplified regex patterns
((ident) @variable.temporal
  (#match? @variable.temporal "^#[a-zA-Z][a-zA-Z0-9_]*$"))

((ident) @variable.temporal
  (#match? @variable.temporal "^#[a-zA-Z][a-zA-Z0-9_]*'$"))

((ident) @variable.temporal
  (#match? @variable.temporal "^[a-zA-Z][a-zA-Z0-9_]*:temporal$"))

;; Message variables - using simplified regex patterns
((ident) @variable.message
  (#match? @variable.message "^[a-z][a-zA-Z0-9_]*$")
  (#not-match? @variable.message "^[A-Z][A-Z0-9_]*$")
  (#not-match? @variable.message "^(Fr|In|Out|K)$"))

((ident) @variable.message
  (#match? @variable.message "^[a-z][a-zA-Z0-9_]*'$"))

((ident) @variable.message
  (#match? @variable.message "^[a-zA-Z][a-zA-Z0-9_]*:msg$"))

;; Variables with pattern matching for suffixes instead of regex OR operator
((ident) @variable.message
  (#not-match? @variable.message ":pub$"))

((ident) @variable.message
  (#not-match? @variable.message ":fresh$"))

((ident) @variable.message
  (#not-match? @variable.message ":temporal$"))

((ident) @variable.message
  (#not-match? @variable.message ":msg$"))

;; ==============================
;; Names and Constants
;; ==============================

;; Public and fresh names
(pub_name) @public.constant
(fresh_name) @constant.string

;; Numbers
(natural) @number

;; Parameters and strings
(param) @string

;; Special constants
(hexcolor) @constant

;; String literals (using single quotes)
((ident) @public.constant
  (#match? @public.constant "^'[^']*'$"))

;; ==============================
;; Rules, Lemmas, and Restrictions
;; ==============================

;; Rule keyword
(rule) @keyword.function

;; Rule names
(simple_rule 
  rule_identifier: (ident) @function.rule)

;; Lemma names
(lemma 
  lemma_identifier: (ident) @function.rule)

;; Restriction names
(restriction
  restriction_identifier: (ident) @function.rule)

;; ==============================
;; Rule Structure
;; ==============================

;; Rule parts
(premise) @structure
(conclusion) @structure

;; ==============================
;; Logical Operators
;; ==============================

;; Logical operators
(imp) @operator.logical
(negation) @operator.logical
(conjunction) @operator.logical
(disjunction) @operator.logical
(iff) @operator.logical

;; ==============================
;; Logical Formulas
;; ==============================

;; Formula structures
(quantified_formula) @structure
(nested_formula) @structure

;; ==============================
;; Actions and Terms
;; ==============================

;; Action constraints
(action_constraint) @operator

;; Term types
(mset_term) @variable
(arguments) @variable
(nat_term) @variable
(xor_term) @variable
(mul_term) @variable
(exp_term) @variable
