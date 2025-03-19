;; Simplified Tamarin Syntax Highlighting
;; Based on TreeSitter query patterns that avoid regex stack overflow

;; === Basic keywords ===
[
  "theory"
  "begin"
  "end"
  "rule"
  "let"
  "in"
  "functions"
  "equations"
  "builtins"
  "lemma"
  "axiom"
  "restriction"
  "protocol"
  "property"
  "all"
  "exists"
  "or"
  "and"
  "not"
  "if"
  "then"
  "else"
  "subsection"
  "section"
  "text"
] @keyword

;; === Operators ===
[
  "="
  "=="
  "!="
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

;; === Delimiters ===
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
] @delimiter

;; === Basic types ===
(string) @string
(comment) @comment
(number) @number

;; === Node-based captures ===
;; These don't use regex patterns, which avoids stack overflow issues

;; Theory definitions
(theory
  theory_name: (ident) @type)

;; Functions
(function_untyped) @function

;; Facts
(linear_fact) @constant
(persistent_fact) @constant

;; === Safe predicates ===
;; Single-character predicates that are less likely to cause regex issues

;; Simple variable names (non-apostrophe versions)
((ident) @variable
 (#match? @variable "^[a-z]"))

;; Constants (all uppercase)
((ident) @constant
 (#match? @variable "^[A-Z]"))

;; Protocol name
(theory
  protocol_name: (ident) @namespace) 