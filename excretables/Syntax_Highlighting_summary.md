# TreeSitter Syntax Highlighting System Summary

## Overview

TreeSitter's syntax highlighting system is based on tree queries that pattern-match against syntax trees. The system uses three main types of query files:

1. **Highlights Query (`highlights.scm`)**: Assigns arbitrary highlight names to different nodes in the tree, which can then be mapped to colors.
2. **Local Variable Query (`locals.scm`)**: Tracks local scopes and variables to ensure consistent coloring across references.
3. **Injection Query (`injections.scm`)**: Defines where other languages can be embedded within a file.

## Key Components

### Highlight Queries

- Use capture names to assign highlight names to syntax nodes 
- Examples: `@keyword`, `@function`, `@string`, `@variable`
- Names can be dot-separated like `@function.builtin`
- The actual colors are defined in a separate theme configuration

### Predicates

Predicates are special expressions that filter matches based on conditions:

- **`#eq?`**: Checks for exact text matches (`#eq? @variable "self"`)
- **`#match?`**: Uses regex patterns (`#match? @constant "^[A-Z][A-Z_]+"`)
- **`#any-of?`**: Matches against a list of strings
- **`#is?`**: Checks for properties on a node

Negations are possible with `#not-eq?` and `#not-match?`

### Common Issues with Regex in TreeSitter

1. **Stack Overflows**: Complex regex patterns can cause Vim's NFA regex engine to overflow
2. **No Case-Insensitive Flag**: TreeSitter doesn't support case-insensitive regex flags like `/i`, requiring workarounds with character classes
3. **Nested Quantifiers**: Patterns like `(a+)+` are particularly problematic
4. **Backreferences**: Can lead to exponential backtracking

### Best Practices

1. Use simple patterns with predicates instead of complex regex
2. Break complex patterns into multiple simpler ones
3. Avoid nested quantifiers and backreferences
4. Use `#match?` with caution, keeping patterns as simple as possible
5. Test each pattern incrementally

## Example: Avoiding Complex Regex

**Problematic:**
```scheme
((identifier) @variable
 (#match? @variable "^[a-z][a-zA-Z0-9_]*(\'*)$"))
```

**Better:**
```scheme
((identifier) @variable
 (#match? @variable "^[a-z]"))
```

## Query File Validation

The query files must be valid for TreeSitter to parse them. Common errors include:
- Invalid node types that don't exist in the grammar
- Syntax errors in the query expressions
- Regex pattern errors

When debugging, you can use TreeSitter's query parsing functionality to validate query files. 