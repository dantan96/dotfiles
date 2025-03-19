# TreeSitter Mandatory Reading List

This document tracks the reading progress of TreeSitter documentation files. No changes to TreeSitter files (especially highlights.scm) should be made until all documentation has been thoroughly reviewed.

| File | Partial Reading | Complete Reading |
|------|:--------------:|:----------------:|
| documentation/treesitter/2 Operators.md | [x] | [ ] |
| documentation/treesitter/4 API.md | [x] | [ ] |
| documentation/treesitter/5 Implementation.md | [x] | [ ] |
| documentation/treesitter/6 Publishing.md | [x] | [ ] |
| documentation/treesitter/7 Playground.md | [x] | [ ] |
| documentation/treesitter/Advanced Parsing.md | [x] | [ ] |
| documentation/treesitter/Basic Parsing.md | [x] | [ ] |
| documentation/treesitter/Build Documentation.md | [ ] | [ ] |
| documentation/treesitter/Code Navigation.md | [ ] | [ ] |
| documentation/treesitter/Complete Documentation.md | [ ] | [ ] |
| documentation/treesitter/Contributing Guide.md | [ ] | [ ] |
| documentation/treesitter/External Scanners.md | [x] | [ ] |
| documentation/treesitter/Fuzz Documentation.md | [ ] | [ ] |
| documentation/treesitter/Generate CLI Documentation.md | [ ] | [ ] |
| documentation/treesitter/Getting Started (1).md | [ ] | [ ] |
| documentation/treesitter/Getting Started.md | [ ] | [ ] |
| documentation/treesitter/Grammar DSL.md | [ ] | [ ] |
| documentation/treesitter/Highlight Documentation.md | [ ] | [ ] |
| documentation/treesitter/Init Config.md | [ ] | [ ] |
| documentation/treesitter/Parse Documentation.md | [ ] | [ ] |
| documentation/treesitter/Predicates and Directives.md | [x] | [ ] |
| documentation/treesitter/Query Documentation.md | [x] | [ ] |
| documentation/treesitter/Static Node Types.md | [ ] | [ ] |
| documentation/treesitter/Syntax Highlighting.md | [x] | [ ] |
| documentation/treesitter/Tree Sitter CLI Version.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Init Documentation.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Playground.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Summary.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Tags.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Test.md | [ ] | [ ] |
| documentation/treesitter/Using Parsers Syntax.md | [ ] | [ ] |
| documentation/treesitter/Walking Trees.md | [ ] | [ ] |
| documentation/treesitter/Writing Tests.md | [ ] | [ ] |
| documentation/treesitter/Writing the Grammar.md | [ ] | [ ] |
| documentation/treesitter/highly_relevant_information_for_our_final_attempt.md | [ ] | [ ] |
| documentation/treesitter/hypotheses_treesitter_fallback.md | [ ] | [ ] |
| documentation/treesitter/manually_adding_a_treesitter_parser_a_guide.md | [ ] | [ ] |
| documentation/treesitter/simplifying_the_config.md | [ ] | [ ] |
| documentation/treesitter/syntax_highlighting_a_thorough_complete_plan_to_fix_forever_no_matter_what.md | [ ] | [ ] |
| documentation/treesitter/treesitter_documentation_analysis.md | [ ] | [ ] |
| test/h14_external_scanner_test.md | [x] | [ ] |
| test/h15_predicate_regex_test.md | [x] | [ ] |
| test/h16_highlighter_gc_test.md | [x] | [ ] |
| test/treesitter_fix_plan.md | [ ] | [ ] |
| test/treesitter_regex_test_plan.md | [ ] | [ ] |

## Reading Progress
- Files partially read: 14/46
- Files completely read: 0/46
- Progress: 30%

## Notes
- Files will be marked as "partially read" when they've been skimmed for key information
- Files will be marked as "completely read" only when they've been thoroughly studied and fully understood

## Initial Notes and Hypotheses from Reading

### TreeSitter Operators (2 Operators.md)
- TreeSitter query language has powerful capturing capabilities using the `@` syntax
- Quantification operators (`+`, `*`, `?`) allow matching repeating patterns
- Alternations (`[]`) provide a way to match multiple patterns or tokens
- The anchor operator (`.`) is useful for constraining matches

### TreeSitter API (4 API.md)
- TreeSitter provides a C API for creating and executing queries
- Query errors are classified into different types (syntax, node type, field, capture)
- Results are provided as matches with captures

### Implementation Details (5 Implementation.md)
- TreeSitter has two main components: C library and CLI tool
- The CLI generates parsers from grammars defined in JavaScript
- Grammars are transformed into syntax and lexical grammars

### Publishing Grammars (6 Publishing.md)
- TreeSitter grammars should follow semantic versioning
- Multiple publishing targets are recommended (GitHub, npm, crates.io, PyPI)

### Advanced Parsing (Advanced Parsing.md)
- TreeSitter supports incremental parsing with efficient tree editing
- Multi-language documents are supported through included ranges
- Thread safety is achieved through inexpensive tree copying

### Basic Parsing (Basic Parsing.md)
- Custom data structures can be used for source code storage
- DOM-style interface for tree traversal
- Distinction between named and anonymous nodes
- Field names provide meaningful access to specific child nodes

### Predicates and Directives (Predicates and Directives.md)
- Predicates allow additional conditions to be attached to tree patterns
- The `#match?` predicate is particularly useful for regex matching
- Complex regex patterns in predicates can cause stack overflows
- Multiple simple predicates can be used instead of one complex pattern
- Directives can associate metadata with patterns

### Syntax Highlighting (Syntax Highlighting.md)
- TreeSitter provides a comprehensive syntax highlighting system
- Syntax highlighting is configured through query files
- Captures in the query file are mapped to highlight groups
- Local variable tracking helps ensure consistent highlighting

### External Scanners (External Scanners.md)
- Used for tokens that are difficult to describe with regular expressions
- Implemented as C functions with specific naming conventions
- The scanner needs to handle creation, destruction, serialization, and deserialization
- The `scan` function is the core of the external scanner that recognizes tokens

### Test: TreeSitter Predicates with Complex Regex Patterns (h15_predicate_regex_test.md)
- Complex regex patterns in TreeSitter predicates can cause stack overflows
- The Vim regex engine has limitations with certain pattern types
- Breaking down complex patterns into multiple simpler predicates is more reliable
- Apostrophes in patterns are particularly problematic for the Tamarin language

### Test: External Scanner for Apostrophe Variables (h14_external_scanner_test.md)
- External scanners can handle special tokens like variables with apostrophes
- The implementation requires C programming and specific TreeSitter integration
- Grammar and query files need to be updated to work with the external scanner
- This approach may resolve the stack overflow issues with complex regex patterns

### Test: TreeSitter Highlighter Garbage Collection (h16_highlighter_gc_test.md)
- Highlighter objects must be stored in buffer-local variables to prevent garbage collection
- Premature garbage collection can cause syntax highlighting to fail
- Proper storage and reference management is crucial for persistent highlighting
- GC issues can explain why highlighting sometimes works initially but fails later
