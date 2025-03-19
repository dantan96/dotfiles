# Hypothesis Database

## Open Hypotheses

1. **H1**: The main issue with Tamarin syntax highlighting is related to TreeSitter parser loading and integration.
6. **H6**: The simplified parser loading method in simplifying_the_config.md might be sufficient for our needs.
7. **H7**: The symlink between queries/tamarin/highlights.scm and queries/spthy/highlights.scm might be causing issues.
8. **H8**: The current implementation in lua/tamarin/ has redundant code that could be simplified.
9. **H9**: Complex regex patterns in `highlights.scm` cause Vim's NFA regex engine to stack overflow.
10. **H10**: Nested regex quantifiers in TreeSitter queries are particularly problematic for Vim's regex engine.
11. **H11**: Case-insensitive matching approaches in TreeSitter can cause complexity issues in regex patterns.
12. **H12**: Backreferences in regex patterns might be causing the stack overflow.
13. **H13**: Using predicates with simpler patterns instead of complex regex might be more efficient.

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
