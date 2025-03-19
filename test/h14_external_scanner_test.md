# Test: External Scanner for Apostrophe Variables (H14)

## Hypothesis
External scanner registration might be needed for handling special token cases like variables with apostrophes in Tamarin.

## Background
Tamarin protocol files frequently use variables with apostrophes (e.g., `x'`). These constructs are hard to handle with regular expressions and may be better served with an external scanner. The TreeSitter documentation indicates that external scanners are specifically designed for tokens that are difficult to describe with regular expressions.

## Test Plan

1. **Implement a basic external scanner for Tamarin**
   - Create a C source file (`scanner.c`) that handles variables with apostrophes
   - Add this scanner to the parser compilation process
   - Update the parser registration to use this scanner

2. **Test the scanner with problematic variables**
   - Create a test file with various variables containing apostrophes
   - Verify that the external scanner correctly tokenizes these variables
   - Compare with the previous regex-based approach

3. **Measure performance impact**
   - Compare parser performance with and without the external scanner
   - Look for any reduction in stack overflow errors
   - Ensure the scanner doesn't introduce new issues

## Scanner Implementation

```c
// File: scanner.c
#include <tree_sitter/parser.h>
#include <ctype.h>

enum TokenType {
  VARIABLE_WITH_APOSTROPHE
};

void * tree_sitter_spthy_external_scanner_create() {
  return NULL;  // No state needed
}

void tree_sitter_spthy_external_scanner_destroy(void *payload) {
  // No memory to free
}

unsigned tree_sitter_spthy_external_scanner_serialize(void *payload, char *buffer) {
  return 0;  // No state to serialize
}

void tree_sitter_spthy_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  // No state to deserialize
}

bool tree_sitter_spthy_external_scanner_scan(
  void *payload,
  TSLexer *lexer,
  const bool *valid_symbols
) {
  // Skip whitespace
  while (isspace(lexer->lookahead)) {
    lexer->advance(lexer, true);
  }
  
  // Check if we're looking for a variable with apostrophe
  if (valid_symbols[VARIABLE_WITH_APOSTROPHE]) {
    // First char must be a letter or underscore
    if (isalpha(lexer->lookahead) || lexer->lookahead == '_') {
      lexer->mark_end(lexer);
      lexer->advance(lexer, false);
      
      // Continue consuming identifier characters
      while (isalnum(lexer->lookahead) || lexer->lookahead == '_') {
        lexer->mark_end(lexer);
        lexer->advance(lexer, false);
      }
      
      // Check for apostrophe
      if (lexer->lookahead == '\'') {
        lexer->mark_end(lexer);
        lexer->advance(lexer, false);
        
        // Optionally continue for multiple apostrophes
        while (lexer->lookahead == '\'') {
          lexer->mark_end(lexer);
          lexer->advance(lexer, false);
        }
        
        lexer->result_symbol = VARIABLE_WITH_APOSTROPHE;
        return true;
      }
    }
  }
  
  return false;
}
```

## Grammar Updates

The grammar would need to be updated to use this external scanner:

```js
module.exports = grammar({
  name: 'spthy',
  
  externals: $ => [
    $.variable_with_apostrophe
  ],
  
  rules: {
    // ... existing rules
    
    variable: $ => choice(
      /[a-zA-Z_][a-zA-Z0-9_]*/,
      $.variable_with_apostrophe
    ),
    
    // ... other rules
  }
});
```

## Query File Updates

The query file would need to be updated to capture the external token:

```scheme
;; highlights.scm
(variable_with_apostrophe) @variable.special
```

## Expected Results

If H14 is true:
- The external scanner will successfully handle variables with apostrophes
- Stack overflow errors will be reduced or eliminated
- Syntax highlighting will work correctly for these variables

If H14 is false:
- The external scanner might not provide significant benefits
- Alternative solutions might be more appropriate

## Test Procedure

1. Build the parser with the external scanner
2. Create test files with various variable patterns
3. Test syntax highlighting with and without the external scanner
4. Document the results and update the hypothesis database 