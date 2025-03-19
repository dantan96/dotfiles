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
| documentation/treesitter/Grammar DSL.md | [x] | [ ] |
| documentation/treesitter/Highlight Documentation.md | [x] | [ ] |
| documentation/treesitter/Init Config.md | [ ] | [ ] |
| documentation/treesitter/Parse Documentation.md | [ ] | [ ] |
| documentation/treesitter/Predicates and Directives.md | [x] | [ ] |
| documentation/treesitter/Query Documentation.md | [x] | [ ] |
| documentation/treesitter/Static Node Types.md | [ ] | [ ] |
| documentation/treesitter/Syntax Highlighting.md | [x] | [ ] |
| documentation/treesitter/Tree Sitter CLI Version.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Init Documentation.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Playground.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Summary.md | [x] | [ ] |
| documentation/treesitter/Tree Sitter Tags.md | [ ] | [ ] |
| documentation/treesitter/Tree Sitter Test.md | [ ] | [ ] |
| documentation/treesitter/Using Parsers Syntax.md | [ ] | [ ] |
| documentation/treesitter/Walking Trees.md | [ ] | [ ] |
| documentation/treesitter/Writing Tests.md | [ ] | [ ] |
| documentation/treesitter/Writing the Grammar.md | [x] | [ ] |
| documentation/treesitter/highly_relevant_information_for_our_final_attempt.md | [x] | [ ] |
| documentation/treesitter/hypotheses_treesitter_fallback.md | [x] | [ ] |
| documentation/treesitter/manually_adding_a_treesitter_parser_a_guide.md | [x] | [ ] |
| documentation/treesitter/simplifying_the_config.md | [x] | [ ] |
| documentation/treesitter/syntax_highlighting_a_thorough_complete_plan_to_fix_forever_no_matter_what.md | [x] | [ ] |
| documentation/treesitter/treesitter_documentation_analysis.md | [x] | [ ] |
| test/h14_external_scanner_test.md | [x] | [ ] |
| test/h15_predicate_regex_test.md | [x] | [ ] |
| test/h16_highlighter_gc_test.md | [x] | [ ] |
| test/treesitter_fix_plan.md | [x] | [ ] |
| test/treesitter_regex_test_plan.md | [x] | [ ] |

## Reading Progress
- Files partially read: 25/46
- Files completely read: 0/46
- Progress: 54%

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

### Grammar DSL (Grammar DSL.md)
- Provides a powerful language for defining context-free grammars
- Offers various operators for common patterns (repetition, alternatives, etc.)
- Includes precedence and associativity control for resolving ambiguities
- Supports aliases, field names, and external tokens

### Highlight Documentation (Highlight Documentation.md)
- CLI tool for running syntax highlighting on files
- Can output colored text to terminal or HTML
- Provides options for checking capture conformance
- Can use custom query paths for highlighting

### Writing the Grammar (Writing the Grammar.md)
- Grammar should produce an intuitive tree structure
- Should adhere closely to LR(1) grammar principles for efficiency
- Recommends starting with a breadth-first approach to grammar construction
- Provides guidelines for structuring rules and handling precedence

### Highly Relevant Information (highly_relevant_information_for_our_final_attempt.md)
- Details the TreeSitter parser loading process in Neovim
- Explains symbol name handling, especially on macOS (leading underscore)
- Outlines the syntax highlighting setup requirements
- Lists common pitfalls and implementation requirements

### Simplifying the Config (simplifying_the_config.md)
- Proposes simplifying the TreeSitter parser loader implementation
- Identifies the core issues: symbol name mismatch and language-filetype mismatch
- Suggests a minimal solution using just `vim.treesitter.language.register()`
- Provides implementation plans with different robustness levels

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

### Tree Sitter Summary (Tree Sitter Summary.md)
- Provides an overview of the TreeSitter documentation structure
- Organizes content into User Guide and Reference Guide sections
- User Guide covers using parsers, creating parsers, and applications
- Reference Guide covers CLI tools and their options

### TreeSitter Fallback Hypotheses (hypotheses_treesitter_fallback.md)
- Contains detailed hypotheses about why TreeSitter might fall back to traditional highlighting
- Covers issues like parser loading paths, filetype detection, and grammar parsing errors
- Proposes test plans to validate each hypothesis
- Suggests that multiple issues might be contributing to the fallback behavior

### Adding a TreeSitter Parser (manually_adding_a_treesitter_parser_a_guide.md)
- Provides step-by-step instructions for manually adding a TreeSitter parser to Neovim
- Addresses symbol name mismatch problems with various solutions
- Offers code examples for parser loading and language registration
- Includes debugging techniques for parser integration issues

### Comprehensive Fix Plan (syntax_highlighting_a_thorough_complete_plan_to_fix_forever_no_matter_what.md)
- Outlines a phased approach to fixing TreeSitter syntax highlighting
- Includes environment analysis, implementation, testing, validation, and documentation
- Provides code examples for each phase
- Describes fallback mechanisms for robustness

### TreeSitter Documentation Analysis (treesitter_documentation_analysis.md)
- Analyzes core documentation and extracts key findings
- Focuses on parser requirements, language setup, query system, and buffer handling
- Identifies documentation gaps and areas requiring additional research
- Provides implementation recommendations based on documentation findings

### TreeSitter Regex Test Plan (treesitter_regex_test_plan.md)
- Outlines a plan for testing regex patterns in TreeSitter queries
- Addresses specific hypotheses about regex complexity and stack overflow issues
- Proposes tests for nested quantifiers, case-insensitive matching, and other patterns
- Aims to develop guidelines for writing regex patterns that avoid stack overflow

### TreeSitter Fix Plan (treesitter_fix_plan.md)
- Provides a comprehensive plan to fix Tamarin TreeSitter syntax highlighting
- Identifies five main issues: parser symbol mismatch, language-to-filetype mapping, regex stack overflow, directory structure confusion, and redundant code
- Outlines a five-step implementation plan with detailed code examples
- Includes testing and verification procedures to ensure the solution works correctly
