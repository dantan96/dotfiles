# Hypothesis Database

## Open Hypotheses

1. **H1**: The main issue with Tamarin syntax highlighting is related to TreeSitter parser loading and integration.
6. **H6**: The simplified parser loading method in simplifying_the_config.md might be sufficient for our needs.
7. **H7**: The symlink between queries/tamarin/highlights.scm and queries/spthy/highlights.scm might be causing issues.
8. **H8**: The current implementation in lua/tamarin/ has redundant code that could be simplified.
14. **H14**: External scanner registration might be needed for handling special token cases like variables with apostrophes.
15. **H15**: TreeSitter query predicates like `#match?` could be causing stack overflow when applied to complex regex patterns.
16. **H16**: Buffer-specific highlighter garbage collection issues might be causing the syntax highlighting to fail.
17. **H17**: Improper language injection handling might be causing conflicts with nested language contexts.

## Falsified Hypotheses


## Supported Hypotheses

2. **H2**: There are multiple parsers (in parser/spthy and parser/tamarin) that might be causing conflicts.
   - **Evidence**: Both parser files (spthy.so and tamarin.so) contain identical symbols, suggesting they are duplicates of each other (see h3_parser_symbol_test).

3. **H3**: The parser exports `_tree_sitter_spthy` symbol but Neovim might be expecting a different symbol name.
   - **Evidence**: Symbol inspection shows that both parsers export `_tree_sitter_spthy` but neither exports `tree_sitter_tamarin`, creating a mismatch with Neovim's expectations (see h3_parser_symbol_test).

4. **H4**: Complex regex patterns in `highlights.scm` are causing stack overflow errors in Neovim's regex engine.
   - **Evidence**: Analysis of different versions of highlights.scm shows that the working ultra-minimal version has no regex patterns, while problematic versions include complex patterns with apostrophes, OR operators, and quantifiers (see h4_regex_stack_overflow_test).
   - **Evidence**: The simplified approach (current highlights.scm) that avoids regex patterns entirely works without errors, suggesting that regex complexity is indeed the issue.

5. **H5**: The language name ('spthy') differs from the filetype ('tamarin'), causing mapping issues.
   - **Evidence**: The parser exports symbols for 'spthy' language, but the files use the 'tamarin' filetype, requiring explicit mapping (see h3_parser_symbol_test).

9. **H9**: Complex regex patterns in `highlights.scm` cause Vim's NFA regex engine to stack overflow.
   - **Evidence**: TreeSitter documentation indicates that certain regex patterns, especially those with nested quantifiers, can cause performance issues.
   - **Evidence**: Testing with different regex patterns in the highlights.scm query file confirms that patterns with apostrophes, OR operators, and nested groups are particularly problematic.

10. **H10**: Nested regex quantifiers in TreeSitter queries are particularly problematic for Vim's regex engine.
    - **Evidence**: According to TreeSitter documentation, regex patterns with nested quantifiers (e.g., `(a+)+`) are known to cause issues in many regex engines.
    - **Evidence**: Tests with query files containing nested quantifiers demonstrate stack overflow errors.

11. **H11**: Case-insensitive matching approaches in TreeSitter can cause complexity issues in regex patterns.
    - **Evidence**: The TreeSitter documentation confirms that it doesn't natively support case-insensitive regex flags, leading to workarounds using character classes (e.g., `[aA][bB][cC]`).
    - **Evidence**: Analysis of Tamarin query files shows complex character class patterns being used for case-insensitive matching.

12. **H12**: Backreferences in regex patterns might be causing the stack overflow.
    - **Evidence**: Pattern analysis of problematic highlights.scm files reveals the use of backreferences, which can lead to exponential backtracking in regex engines.

13. **H13**: Using predicates with simpler patterns instead of complex regex might be more efficient.
    - **Evidence**: TreeSitter documentation recommends using multiple simple predicates instead of a single complex regex pattern.
    - **Evidence**: Tests with simplified query files using predicates confirm better performance and stability.
