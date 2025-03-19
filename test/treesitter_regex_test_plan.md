# TreeSitter Regex Test Plan

## Background

We've encountered issues with TreeSitter syntax highlighting in Neovim, specifically related to regex patterns causing stack overflow errors with the error message: "couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!".

Based on our research of the available documentation and community information, we've identified several potential issues:

## Hypotheses

1. **H9: Complex regex patterns in highlights.scm cause Vim's NFA regex engine to stack overflow**
   - TreeSitter uses regex patterns extensively in query files
   - Vim has its own regex engine with NFA (Non-deterministic Finite Automaton) implementation
   - Certain regex patterns may cause this engine to overflow its stack
   
2. **H10: Nested regex quantifiers are particularly problematic**
   - Regex patterns with nested quantifiers (e.g., `(a+)+`) are known to cause issues in many regex engines
   - This may be the specific pattern causing our stack overflow

3. **H11: Case-insensitive matching approaches in TreeSitter can cause issues**
   - TreeSitter doesn't natively support case-insensitive regex
   - The workaround of using character classes for each letter (e.g., `[aA][bB][cC]`) might cause complexity
   
4. **H12: Backreferences in regex patterns might be causing the stack overflow**
   - Backreferences in regex patterns can lead to exponential backtracking

5. **H13: Alternative approaches like using predicates may be more efficient**
   - Using `#match?` with simpler patterns instead of complex regex might avoid stack overflow

## Test Plan

We'll create a series of test files to validate these hypotheses:

1. **Basic Regex Test**
   - Create a basic query file with simple regex patterns
   - Verify that it works without errors

2. **Nested Quantifier Test**
   - Create a query file with nested quantifiers
   - Test if this causes stack overflow

3. **Case Insensitive Test**
   - Compare different approaches to case-insensitive matching
   - Test performance and stability

4. **Backreference Test**
   - Test regex patterns with backreferences
   - Measure impact on performance

5. **Predicate Test**
   - Test using predicates instead of complex regex
   - Compare stability and performance

## Success Criteria

- Identify specific regex patterns that cause stack overflow
- Develop guidelines for writing regex patterns that avoid stack overflow
- Create a simplified, working query file for Tamarin syntax highlighting 