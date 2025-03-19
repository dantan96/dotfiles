# Facts Log

## 2023-05-20 14:00

- Parser (tamarin.so) is correctly located in the parser directory
- Neovim version is 0.10.4
- The parser is loading successfully
- The TreeSitter module is available
- The highlights.scm file is found in queries/tamarin/
- When trying to load the query, we get: "No method to get query found"
- Current tests show that the `vim.treesitter.query.get_query` function can't be found
- The runtime path includes both the parser and queries directories

## 2023-05-20 14:15

- Found the official Tamarin TreeSitter grammar repository: https://github.com/aeyno/tree-sitter-tamarin
- The aeyno/tree-sitter-tamarin repo has a version 1.6.1 release (April 2021)
- The main Tamarin repository (tamarin-prover/tamarin-prover) doesn't include TreeSitter integration directly
- According to Neovim docs, TreeSitter support in 0.10+ is still marked as "experimental"
- Correct path for query files is: `queries/{language}/highlights.scm`
- TreeSitter queries should follow a lisp-like syntax
- The API function `vim.treesitter.query.get` should be available in Neovim 0.10
- Query validation is possible using `vim.treesitter.query.lint`

## 2023-05-20 14:20

- The official Tamarin prover repository has a TreeSitter grammar in the `tree-sitter/tree-sitter-spthy` directory
- The grammar.js file in the official repo is identical to our parser/tamarin/tamarin-grammar.js file
- The grammar uses the name 'spthy' for the language (not 'tamarin')
- Our parser binary is named tamarin.so and our queries directory is tamarin/
- The official repo doesn't include any highlights.scm or other query files
- Aeyno's unofficial repo (aeyno/tree-sitter-tamarin) does have a highlights.scm file
- Aeyno's highlights.scm is simpler than our current file but may provide useful insights
- There was a conflict issue in the TreeSitter grammar (Issue #685) that was fixed in January 2025
- This issue was related to term precedence, not to query or highlighting issues
- The official TreeSitter query file format uses node names for capture and assigns highlight groups
- Standard Neovim TreeSitter queries for languages like Lua and Vim follow a consistent pattern 