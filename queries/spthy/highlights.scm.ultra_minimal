;; Ultra-Minimal Tamarin Highlighting
;; No regex patterns at all

;; Keywords
[
  "theory"
  "begin"
  "end"
  "rule"
  "lemma"
] @keyword

;; Comments
(multi_comment) @comment
(single_comment) @comment

;; Node-based captures only
(theory
  theory_name: (ident) @type)

(function_untyped) @function

(linear_fact) @constant
(persistent_fact) @constant

(natural) @number 