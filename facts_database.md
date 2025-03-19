# Facts Database

## TreeSitter Integration Facts

1. **F1**: TreeSitter parsers export language-specific symbols following a naming convention where the symbol name reflects the language name (e.g., `tree_sitter_javascript` for JavaScript).
   - **Source**: [Getting Started](./consumables/Getting%20Started.md) documentation
   - **Relevance**: The Tamarin parser exports `_tree_sitter_spthy` on macOS (with an underscore prefix), which doesn't match the expected filetype (`tamarin`).

2. **F2**: TreeSitter requires explicit language-to-filetype mapping when the language name differs from the filetype.
   - **Source**: TreeSitter documentation and Neovim API analysis
   - **Relevance**: The language name (`spthy`) differs from the filetype (`tamarin`), requiring explicit mapping through `vim.treesitter.language.register`.

3. **F3**: Complex regex patterns in TreeSitter query files are processed by Vim's regex engine, which has limitations.
   - **Source**: [Syntax Highlighting](./consumables/Syntax%20Highlighting.md) documentation
   - **Relevance**: Certain regex patterns, especially those with nested quantifiers or complex character classes, can cause stack overflow errors.

4. **F4**: TreeSitter does not natively support case-insensitive regex flags.
   - **Source**: [Predicates and Directives](./consumables/Predicates%20and%20Directives.md) documentation
   - **Relevance**: Workarounds for case-insensitive matching often involve complex character classes, which can contribute to regex engine issues.

5. **F5**: TreeSitter highlighters must be stored in buffer-local variables to prevent garbage collection.
   - **Source**: Implementation guidelines in TreeSitter documentation
   - **Relevance**: Failure to properly store highlighters can lead to highlighting issues, as the garbage collector might prematurely clean up the highlighter instance.

6. **F6**: TreeSitter query patterns can use predicates and directives to filter and modify matches.
   - **Source**: [Predicates and Directives](./consumables/Predicates%20and%20Directives.md) documentation
   - **Relevance**: Using predicates with simpler patterns can be more efficient than complex regex patterns.

7. **F7**: External scanners can be used to handle tokens that are difficult to describe with regular expressions.
   - **Source**: [External Scanners](./consumables/External%20Scanners.md) documentation
   - **Relevance**: Variables with apostrophes in Tamarin might be better handled using an external scanner.

8. **F8**: Parsing errors can be gracefully handled by returning appropriate error nodes.
   - **Source**: [Using Parsers Syntax](./consumables/Using%20Parsers%20Syntax.md) documentation
   - **Relevance**: The parser can recover from syntax errors by using error nodes, which can be queried in highlights.scm.

9. **F9**: Progressive development of query files is recommended to avoid complexity.
   - **Source**: [Writing the Grammar](./consumables/Writing%20the%20Grammar.md) documentation
   - **Relevance**: Starting with a minimal query file and gradually adding complexity allows for better testing and stability.

10. **F10**: Parsers should be registered before use and can be assigned to language-specific filetypes.
    - **Source**: TreeSitter API documentation
    - **Relevance**: The Tamarin parser needs to be explicitly registered and mapped to the `tamarin` filetype.

11. **F17**: Both Tamarin/Spthy parser files have external scanner functions defined.
    - **Source**: Symbol inspection of parser files
    - **Relevance**: The external scanner might already be designed to handle variables with apostrophes, but might not be properly registered or utilized.

12. **F18**: Simple TreeSitter predicates with single-character patterns avoid stack overflow issues.
    - **Source**: Implementation and testing of various query files
    - **Relevance**: Using predicates like `(#match? @variable "^[a-z]")` provides a reliable way to match variables without complex regex.

13. **F19**: Modular organization of TreeSitter integration code improves maintainability.
    - **Source**: Implementation experience
    - **Relevance**: Separating parser loading, highlighting, and diagnostics into distinct modules makes the code easier to understand and maintain.

14. **F20**: Explicit registration of the parser path helps ensure the parser is properly loaded.
    - **Source**: Implementation testing with `vim.treesitter.language.add` function
    - **Relevance**: Using the `vim.treesitter.language.add` function with an explicit path ensures the parser is found and loaded correctly.

## Neovim-Specific Facts

15. **F11**: Neovim's regex engine uses a Non-deterministic Finite Automaton (NFA) that can overflow its stack with complex patterns.
    - **Source**: Error message analysis and Neovim documentation
    - **Relevance**: The error message "couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!" indicates a stack overflow in the regex engine.

16. **F12**: Neovim's TreeSitter implementation requires proper language registration.
    - **Source**: Neovim API documentation
    - **Relevance**: The parser must be registered using `vim.treesitter.language.register` to establish the language-to-filetype mapping.

17. **F13**: Neovim's TreeSitter highlighter requires buffer-specific setup.
    - **Source**: Neovim API documentation
    - **Relevance**: Highlighters should be created for each buffer using `vim.treesitter.highlighter.new` and stored in buffer-local variables.

18. **F14**: Neovim allows fallback to traditional syntax highlighting when TreeSitter fails.
    - **Source**: Neovim configuration analysis
    - **Relevance**: A fallback mechanism can be implemented to ensure that some form of syntax highlighting is always available.

19. **F21**: Proper error handling with pcall is essential for robust Neovim plugins.
    - **Source**: Implementation experience
    - **Relevance**: Using pcall to safely call functions prevents errors from breaking the entire plugin.

## Tamarin-Specific Facts

20. **F15**: The Tamarin protocol language uses apostrophes in variable names.
    - **Source**: Analysis of Tamarin source files
    - **Relevance**: Variable names like `x'` are common in Tamarin, and their regex patterns need careful handling.

21. **F16**: The Tamarin parser and query files are located in multiple directories with inconsistent naming.
    - **Source**: Directory structure analysis
    - **Relevance**: Standardizing on a consistent directory structure and naming convention is essential for reliable parser loading.

22. **F22**: Using simplified highlighting patterns works effectively for Tamarin files.
    - **Source**: Implementation and testing
    - **Relevance**: Even with simplified highlighting patterns that don't capture every language construct, the result is still usable and stable.


