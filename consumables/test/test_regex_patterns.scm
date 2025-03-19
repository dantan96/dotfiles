;; TreeSitter Query File with Various Regex Patterns
;; This file contains different regex patterns to test their impact on the TreeSitter parser

;; ===== Simple Patterns =====
;; These should work without issues

;; Simple word match
((identifier) @variable
 (#match? @variable "^simple$"))

;; Simple character class
((identifier) @keyword
 (#match? @keyword "^[a-z]+$"))

;; ===== Potentially Problematic Patterns =====

;; Nested quantifiers - might cause stack overflow
((identifier) @problem1
 (#match? @problem1 "^(a+)+$"))

;; Case insensitive with character classes - might be inefficient
((identifier) @problem2
 (#match? @problem2 "^[vV][aA][rR][iI][aA][bB][lL][eE]$"))

;; Backreferences - might cause exponential backtracking
((identifier) @problem3
 (#match? @problem3 "^([a-z]+)\\1$"))

;; Complex alternation with quantifiers
((identifier) @problem4
 (#match? @problem4 "^(a|b|c)+(x|y|z)+$"))

;; ===== Alternative Approaches =====

;; Multiple simple predicates instead of complex regex
((identifier) @alt1
 (#match? @alt1 "^var")
 (#match? @alt1 "ble$"))

;; Exact matching with eq? predicate
((identifier) @alt2
 (#eq? @alt2 "variable")) 