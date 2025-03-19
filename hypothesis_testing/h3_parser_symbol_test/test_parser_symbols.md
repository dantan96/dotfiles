# Test: Parser Symbol Names (H3)

## Hypothesis
The parser exports `_tree_sitter_spthy` symbol but Neovim might be expecting a different symbol name.

## Test Plan
1. Check the symbols exported by both parser files (spthy.so and tamarin.so)
2. Determine the expected symbol naming convention for Neovim parsers
3. Verify if there's a mismatch between the exported symbols and what Neovim expects

## Execution

### 1. Check exported symbols in parser/spthy/spthy.so

```bash
nm -gU ~/.config/nvim/parser/spthy/spthy.so | grep tree_sitter
```

Output:
```
00000000000013a0 T _tree_sitter_spthy
0000000000012e90 T _tree_sitter_spthy_external_scanner_create
0000000000012ec0 T _tree_sitter_spthy_external_scanner_deserialize
0000000000012ea0 T _tree_sitter_spthy_external_scanner_destroy
0000000000012ed0 T _tree_sitter_spthy_external_scanner_scan
0000000000012eb0 T _tree_sitter_spthy_external_scanner_serialize
```

### 2. Check exported symbols in parser/tamarin/tamarin.so

```bash
nm -gU ~/.config/nvim/parser/tamarin/tamarin.so | grep tree_sitter
```

Output:
```
00000000000013a0 T _tree_sitter_spthy
0000000000012e90 T _tree_sitter_spthy_external_scanner_create
0000000000012ec0 T _tree_sitter_spthy_external_scanner_deserialize
0000000000012ea0 T _tree_sitter_spthy_external_scanner_destroy
0000000000012ed0 T _tree_sitter_spthy_external_scanner_scan
0000000000012eb0 T _tree_sitter_spthy_external_scanner_serialize
```

### 3. Research on Neovim expected symbol naming convention

Based on the Neovim TreeSitter documentation:
- Neovim expects a symbol named `tree_sitter_{language}` 
- For 'spthy' language, it would expect `tree_sitter_spthy`
- For 'tamarin' filetype used as a language, it would expect `tree_sitter_tamarin`

### 4. Platform-specific nuances

On macOS, exported C symbols often have a leading underscore, so:
- `tree_sitter_spthy` becomes `_tree_sitter_spthy`
- `tree_sitter_tamarin` would become `_tree_sitter_tamarin`

## Results

1. Both parser files (spthy.so and tamarin.so) export the same symbols:
   - `_tree_sitter_spthy`
   - Various external scanner functions for spthy

2. Both parsers export `_tree_sitter_spthy` (with leading underscore), which is the macOS convention for `tree_sitter_spthy`.

3. Neither parser exports `_tree_sitter_tamarin` or `tree_sitter_tamarin`.

4. This confirms that there is a symbol mismatch when using the 'tamarin' filetype:
   - The parser provides `_tree_sitter_spthy`
   - Neovim would expect `tree_sitter_tamarin` (or `_tree_sitter_tamarin` on macOS)

## Conclusion

**H3 is confirmed**: There is indeed a symbol mismatch issue. The parser exports `_tree_sitter_spthy` but Neovim would expect `tree_sitter_tamarin` when using the 'tamarin' filetype.

This mismatch explains why TreeSitter cannot automatically load the parser for the 'tamarin' filetype. The solution requires either:

1. Explicitly mapping the 'spthy' language to the 'tamarin' filetype with `vim.treesitter.language.register('spthy', 'tamarin')`, or
2. Creating a parser that exports the `tree_sitter_tamarin` symbol.

The first approach is simpler and aligns with the solution suggested in `simplifying_the_config.md`.

**Additional Finding**: Both parser files (spthy.so and tamarin.so) contain identical symbols, suggesting they are duplicates of each other. This supports hypothesis H2 about redundant parser files causing confusion. 