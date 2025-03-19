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

# Hypotheses Tracker for Tamarin TreeSitter Issues

This document tracks our hypotheses about what might be causing the TreeSitter issues with Tamarin syntax highlighting, especially the error: `couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!`.

Each hypothesis is categorized as:
- **ACTIVE**: Currently being investigated
- **SUPPORTED**: Evidence supports this hypothesis
- **PARTIALLY SUPPORTED**: Some evidence supports this hypothesis
- **REFUTED**: Evidence contradicts this hypothesis
- **RESOLVED**: Issue has been resolved

## Parser Loading Issues

### Hypothesis PL1: Parser Binary Symbol Name Mismatch

**Status**: RESOLVED

**Description**: The compiled TreeSitter parser for Tamarin exports symbols with names that don't match what Neovim expects (e.g., `_tree_sitter_spthy` instead of `tree_sitter_tamarin`).

**Evidence**:
- Running `nm -gU parser/tamarin/tamarin.so | grep tree_sitter` shows symbol `_tree_sitter_spthy` but no `tree_sitter_tamarin`
- Error log shows: `Failed to load parser: uv_dlsym: dlsym(0x457d1130, tree_sitter_tamarin): symbol not found`
- When we investigate the logs, we see Neovim is looking for `tree_sitter_tamarin` but the library exports `_tree_sitter_spthy`

**Actions**:
- Created symlinks between parser files to handle naming inconsistencies
- Implemented `register_language_directly` function to map the parsers correctly
- Added more comprehensive symbol inspection to the parser loader

**Resolution**:
- Implemented direct language registration with `vim.treesitter.language.register('spthy', 'tamarin')`
- Added symlink creation for platforms/versions where direct registration is not available
- Our updated module now successfully loads the parser, as confirmed by our test scripts

### Hypothesis PL2: Parser File Path Issues

**Status**: RESOLVED

**Description**: The TreeSitter parser files are not in locations where Neovim can find them or are incorrect.

**Evidence**:
- Found multiple parser files in different locations: `/Users/dan/.config/nvim/parser/spthy/spthy.so` and `/Users/dan/.config/nvim/parser/tamarin/tamarin.so`
- Neovim might be finding one parser but not the other

**Actions**:
- Used `vim.api.nvim_get_runtime_file` to check what parser files Neovim can find
- Implemented a more robust parser loader that checks multiple locations

**Resolution**:
- Our parser loader now checks for parsers in multiple locations and creates appropriate symlinks
- Testing confirms it successfully finds and loads the parser

### Hypothesis PL3: Missing Parser Registration

**Status**: RESOLVED

**Description**: The parser is not being properly registered with Neovim's TreeSitter subsystem.

**Evidence**:
- Debug logs show that language registration was failing
- Parser files exist but Neovim doesn't recognize them for the tamarin filetype

**Actions**:
- Created a custom parser loader that explicitly registers languages
- Added logging to track the registration process

**Resolution**:
- Our updated module uses direct language registration via `vim.treesitter.language.register`
- Testing with `/tmp/test-tamarin/test_script.lua` confirms registration succeeds

## Query File Issues

### Hypothesis QF1: Complex Regex Patterns in Highlights.scm

**Status**: ACTIVE

**Description**: The highlights.scm file contains regex patterns that are too complex for Neovim's NFA-based regex engine.

**Evidence**:
- Error message explicitly mentions regex: `couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!`
- An ultra-minimal highlights.scm without regex patterns eliminates the error
- Progressive testing with more complex patterns might identify problematic ones

**Actions**:
- Created a series of highlights.scm files with increasing complexity:
  - 01_basic: Just node captures, no regex
  - 02_simple_regex: Simple regex patterns without apostrophes
  - 03_apostrophes: Added apostrophe support without quantifiers
  - 04_quantifiers: Added quantifiers but no OR operators
  - 05_or_operators: Added complex OR operations
- Developed test script to methodically test each variant

**Next Steps**:
- Continue testing simplified regex patterns to identify exactly which constructs cause issues
- Develop a highlights.scm that avoids problematic patterns

### Hypothesis QF2: Apostrophes in Variable Names Causing Regex Issues

**Status**: ACTIVE

**Description**: Regex patterns matching variables with apostrophes (e.g., `~k'`) are causing the NFA stack overflow.

**Evidence**:
- The error occurs specifically with files containing apostrophes in variable names
- Non-apostrophe variable highlighting seems to work correctly

**Actions**:
- Created test cases with various apostrophe usage patterns
- Tested simplified regex patterns for apostrophe handling

**Next Steps**:
- Isolate the specific regex pattern causing issues
- Split complex apostrophe-handling patterns into multiple simpler patterns

## TreeSitter Integration Issues

### Hypothesis TI1: Version Incompatibilities

**Status**: PARTIALLY SUPPORTED

**Description**: There might be incompatibilities between Neovim's TreeSitter integration, the TreeSitter library version, and the parser version.

**Evidence**:
- Similar errors have been reported with other TreeSitter parsers in different Neovim versions
- Web searches reveal similar symbol mismatch issues with other languages
- Our testing shows that the approach needed varies by Neovim version

**Actions**:
- Researched known TreeSitter issues with symbol naming
- Created a robust parser loader that handles different Neovim versions

**Next Steps**:
- Test on multiple Neovim versions to ensure cross-version compatibility
- Document version-specific requirements

### Hypothesis TI2: Parser Compilation Issues

**Status**: RESOLVED

**Description**: The TreeSitter parser was compiled with options that make it incompatible with Neovim's expectations.

**Evidence**:
- Symbol names have unexpected prefixes (`_tree_sitter_spthy` instead of `tree_sitter_tamarin`)
- The leading underscore in symbol names is a common macOS compiler behavior

**Actions**:
- Examined symbol table of compiled parsers
- Added more detailed symbol inspection to the parser loader

**Resolution**:
- Our approach now handles the symbol naming differences, creating symlinks when needed
- We also directly register the language with the correct mapping between language and filetype

## Query Parsing Issues

### Hypothesis QP1: Mix of Filetype and Language Issues

**Status**: RESOLVED

**Description**: Confusion between the 'tamarin' filetype and the 'spthy' language for TreeSitter is causing query loading issues.

**Evidence**:
- Symbolic links exist between `queries/tamarin/highlights.scm` and `queries/spthy/highlights.scm`
- Parsing logs show queries being loaded for the wrong language

**Actions**:
- Made both query locations contain valid query files
- Implemented proper language-to-filetype mappings

**Resolution**:
- Our implementation now properly handles the relationship between the 'spthy' language and 'tamarin' filetype
- The parser is properly registered for the tamarin filetype

## Parsing Issues

### Hypothesis PI1: Grammar Cannot Parse Tamarin Files

**Status**: NEW

**Description**: The Tamarin TreeSitter grammar may have issues parsing Tamarin protocol files correctly.

**Evidence**:
- Our tests show that while the parser loads successfully, it returns an ERROR node as the root
- This suggests the grammar itself might not be correctly parsing Tamarin syntax

**Actions**:
- Confirmed the parser is loading properly
- Verified that the ERROR node is coming from parsing, not from loading

**Next Steps**:
- Examine the grammar definition
- Check for any mismatches between the grammar and actual Tamarin syntax
- Test with progressively simpler Tamarin files to isolate syntax that causes parsing errors

## Summary of Latest Findings

Our latest findings confirm that we've successfully resolved the parser loading and registration issues. The parser is now properly registered for the tamarin filetype and is being loaded correctly. However, the parser may still have issues correctly parsing Tamarin files, as evidenced by the ERROR root node.

We've implemented several solutions:
1. Direct language registration via `vim.treesitter.language.register('spthy', 'tamarin')`
2. Symlink creation to handle symbol name mismatches
3. Robust error handling throughout the parser loading process
4. Better logging for diagnosing issues

Our next focus should be on:
1. Understanding why the parser returns ERROR nodes for Tamarin files
2. Identifying and fixing problematic regex patterns in the highlights.scm file
3. Testing with a variety of Tamarin files to ensure robustness 