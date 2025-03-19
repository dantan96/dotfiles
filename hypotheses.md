# Hypotheses Log

## 2023-05-20 14:00

1. **API Mismatch**: The `vim.treesitter.query.get_query` function might not be available in Neovim 0.10.4, or it might have a different path than what we're using.
   - Test: Investigate the TreeSitter API structure in Neovim 0.10.4
   - Status: Active

2. **Headless Mode Limitations**: The query loading functionality might be restricted in headless mode.
   - Test: Check if the behavior is different in non-headless mode
   - Status: Active

3. **Syntax Error in Query File**: The highlights.scm file might have syntax errors preventing it from loading.
   - Test: Validate the syntax of the highlights.scm file
   - Status: Active

4. **Parser/Query Version Mismatch**: The parser might be a different version than what the query file expects.
   - Test: Compare the parser with the official Tamarin repository's parser
   - Status: Active

## 2023-05-20 14:15

1. **Correct API Name**: The function might be `vim.treesitter.query.get` instead of `vim.treesitter.query.get_query`
   - Test: Try using `vim.treesitter.query.get` in our script
   - Status: New

2. **Query File Validation**: The highlights.scm file might have syntax errors or invalid node types
   - Test: Use `vim.treesitter.query.lint` to check the query file
   - Status: New

3. **Missing Plugin Dependency**: The query functionality might require the nvim-treesitter plugin
   - Test: Check if this functionality works in a default Neovim 0.10 without plugins
   - Status: New

4. **Runtime Path Issues**: The `queries` directory might not be correctly included in the runtime path
   - Test: Explicitly add the queries directory to the runtime path
   - Status: New

5. **TreeSitter Grammar Source**: We might need to use the grammar.js from aeyno/tree-sitter-tamarin
   - Test: Compare our grammar.js with the one from aeyno/tree-sitter-tamarin
   - Status: New

## 2023-05-20 14:25

1. **Language Name Mismatch**: The grammar name in the grammar.js is 'spthy', but our parser and queries directory are named 'tamarin', which might be causing a mismatch.
   - Test: Create symlinks or rename directories to match 'spthy' and see if it works
   - Status: Likely

2. **Query File Syntax Issue**: Our highlights.scm file may have syntax errors or be using incorrect node names.
   - Test: Validate against Aeyno's simpler highlights.scm or use a minimal version for testing
   - Status: Likely

3. **TreeSitter API Version Mismatch**: The error "No method to get query found" might be due to trying to use a function that doesn't exist in our Neovim version.
   - Test: Use vim.treesitter.query.get instead of vim.treesitter.query.get_query
   - Status: Likely

4. **Neovim Configuration Issue**: There might be something in our Neovim configuration affecting TreeSitter.
   - Test: Try with a minimal Neovim config using only the necessary settings
   - Status: Possible

5. **Headless Mode Limitations**: TreeSitter queries might work differently in headless mode.
   - Test: Try using a non-headless Neovim instance for testing
   - Status: Possible

# Hypotheses for Tamarin TreeSitter Issues

## Core Issue
We need to identify why Neovim is showing the error:
```
couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!
```

## Current Hypotheses

### H1: Parser Registration Failure
**Description**: The TreeSitter parsers for tamarin/spthy are not being correctly registered with Neovim.  
**Evidence For**: 
- Debug logs show `Registered: false` for both tamarin and spthy languages
- Error message: `no parser for 'spthy' language, see :help treesitter-parsers`

**Evidence Against**: 
- Parser files exist in the correct locations
- init.lua has code for registering the parsers

**Status**: ✅ LIKELY - The parsers exist but aren't being registered correctly

### H2: Complex Regex Patterns Causing Errors
**Description**: The regex patterns in highlights.scm, particularly those with apostrophes and quantifiers, are triggering Neovim's regex parser to fail.  
**Evidence For**: 
- Ultra-minimal highlights.scm with no regex patterns works without errors
- Error message specifically mentions "couldn't parse regex"
- The patterns that use `'*` (apostrophe with quantifier) could cause deep recursion

**Evidence Against**: 
- Our test versions of highlights.scm with simplified regex patterns still worked

**Status**: ✅ LIKELY - The regex errors only appear with the full set of patterns

### H3: Multiple TreeSitter Parsers Conflict
**Description**: Having multiple parsers (one in .config/nvim and one in .local/share/nvim) is causing conflicts.  
**Evidence For**: 
- Two parsers exist in different locations
- nvim-treesitter plugin may be trying to load its version of the parser

**Evidence Against**: 
- Debug logs don't show any attempt to load the nvim-treesitter version
- Debug shows nvim-treesitter plugin is not loaded during testing

**Status**: ❓ UNCERTAIN - Need to investigate parser loading order

### H4: Parser for 'tamarin' vs 'spthy' Confusion
**Description**: The system is confused about whether to use 'tamarin' or 'spthy' as the language name.  
**Evidence For**: 
- Two different language names for the same format
- Symlinks between tamarin and spthy
- Registration code in init.lua tries to register 'spthy' for 'tamarin'

**Evidence Against**: 
- init.lua has explicit code to handle this relationship

**Status**: ✅ LIKELY - The language registration may not be working correctly

### H5: Neovim Version Compatibility Issues
**Description**: Neovim 0.10.4 may have TreeSitter API changes that affect the regex handling.  
**Evidence For**: 
- TreeSitter integration in Neovim has evolved rapidly
- Some API calls may be deprecated or changed

**Evidence Against**: 
- Basic TreeSitter functionality works for other languages
- Ultra-minimal highlights.scm works fine

**Status**: ❓ UNCERTAIN - Need to check API compatibility

### H6: Malformed Pattern in highlights.scm
**Description**: There could be a specific pattern in highlights.scm that is malformed and crashes the regex parser.  
**Evidence For**: 
- Error specifically mentions regex parser failure
- Ultra-minimal highlights.scm with no regex patterns works

**Evidence Against**: 
- We tested several variations of the patterns without identifying the specific issue

**Status**: ✅ LIKELY - One or more patterns in the full highlights.scm are causing the issue

### H7: TreeSitter Highlighter Not Properly Initialized
**Description**: The TreeSitter highlighter isn't being properly initialized for tamarin files.  
**Evidence For**: 
- Debug logs show `TreeSitter highlighter active: false`
- No errors with the ultra-minimal version even though the parser isn't registered

**Evidence Against**: 
- If this were the only issue, we wouldn't see regex errors at all

**Status**: ✅ LIKELY - The highlighter isn't being initialized, but this may be a symptom not the cause

## Action Items

1. Fix parser registration to ensure both tamarin and spthy parsers are properly loaded
2. Test with a progressive series of highlights.scm files to identify problematic patterns
3. Check Neovim documentation for proper parser and language registration procedures
4. Examine TreeSitter initialization in init.lua to ensure proper loading sequence 