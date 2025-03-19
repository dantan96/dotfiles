# Hypothesis Database

## Open Hypotheses

1. **H1**: The main issue with Tamarin syntax highlighting is related to TreeSitter parser loading and integration.
4. **H4**: Complex regex patterns in `highlights.scm` are causing stack overflow errors in Neovim's regex engine.
6. **H6**: The simplified parser loading method in simplifying_the_config.md might be sufficient for our needs.
7. **H7**: The symlink between queries/tamarin/highlights.scm and queries/spthy/highlights.scm might be causing issues.
8. **H8**: The current implementation in lua/tamarin/ has redundant code that could be simplified.

## Falsified Hypotheses


## Supported Hypotheses

2. **H2**: There are multiple parsers (in parser/spthy and parser/tamarin) that might be causing conflicts.
   - **Evidence**: Both parser files (spthy.so and tamarin.so) contain identical symbols, suggesting they are duplicates of each other (see h3_parser_symbol_test).

3. **H3**: The parser exports `_tree_sitter_spthy` symbol but Neovim might be expecting a different symbol name.
   - **Evidence**: Symbol inspection shows that both parsers export `_tree_sitter_spthy` but neither exports `tree_sitter_tamarin`, creating a mismatch with Neovim's expectations (see h3_parser_symbol_test).

5. **H5**: The language name ('spthy') differs from the filetype ('tamarin'), causing mapping issues.
   - **Evidence**: The parser exports symbols for 'spthy' language, but the files use the 'tamarin' filetype, requiring explicit mapping (see h3_parser_symbol_test).
