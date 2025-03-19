## H19 - Invalid Node Types in highlights.scm
- **Status**: Confirmed
- **Hypothesis**: The "protocol" keyword in the highlights.scm query file is being interpreted as a node type rather than a string literal, causing query parsing to fail.
- **Test**: Created a Lua script to validate the original and fixed query files, checking for proper parsing.
- **Results**: Both original and fixed query files fail with the error: "Query error at XX:4. Invalid node type 'protocol'". The issue persists even when placing the protocol keyword in a separate list.
- **Conclusion**: The "protocol" keyword is indeed causing the query to fail, but our fix attempt wasn't successful.

## H20 - Keyword vs Node Type Confusion
- **Status**: Confirmed
- **Hypothesis**: TreeSitter query files distinguish between node types and keywords differently than we assumed. The error isn't about the value "protocol" itself but how we're using it in the query structure.
- **Test**: Created test query files with different patterns based on working examples from other languages, and validated them against the parser.
- **Results**: Multiple node types referenced in our query file don't exist in the Tamarin grammar, including "protocol", "property", and even basic types like "string". The minimal version (commit 96c626a) used fewer node types and worked.
- **Conclusion**: The error occurs because we were referencing node types that don't exist in the Tamarin grammar. We've reverted to a minimal working version while we complete the TreeSitter documentation reading list for a more informed solution. 