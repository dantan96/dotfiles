# H20: Keyword vs Node Type Confusion in TreeSitter Queries

## Hypothesis
TreeSitter query files distinguish between node types and keywords differently than we assumed. The error isn't about the value "protocol" itself but how we're using it in the query structure.

## Rationale
After multiple attempts to fix the H19 issue (invalid node type "protocol"), we've observed that:

1. Simply placing "protocol" in a list of string literals doesn't solve the problem
2. Splitting the keyword list into multiple smaller lists doesn't solve the problem
3. The error message consistently identifies "protocol" as an invalid node type, not as an invalid keyword

This suggests a deeper misunderstanding of how TreeSitter distinguishes between:
- String literals used for pattern matching (keywords)
- Node types that reference the grammar structure

## Approach

1. Examine working TreeSitter query files from other languages
2. Identify how they handle keywords vs. node types
3. Apply those patterns to our tamarin query file
4. Validate the modified query file

## Test Design

1. Find examples of valid query files in the Neovim runtime
2. Analyze their structure, particularly how they handle keywords
3. Create a test variant of our query file based on these examples
4. Run our validation test against this new variant

## Success Criteria
A valid query file that:
1. Successfully parses without errors
2. Correctly handles all tamarin language elements
3. Can be used as a basis for proper syntax highlighting 