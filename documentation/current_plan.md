# Current Plan for Fixing TreeSitter Syntax Highlighting Issues

## Problem Summary

The Neovim configuration for Tamarin syntax highlighting is experiencing the following error:
```
couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!
```

Based on our diagnostics, there are two key issues that need to be addressed:

1. **Parser Registration Issue**: The TreeSitter parsers for tamarin/spthy are not being properly registered with Neovim
2. **Regex Pattern Issue**: Certain regex patterns in the highlights.scm file are causing the Neovim regex parser to fail

## Alignment with Radical New Approach

Our current plan aligns with the principles outlined in `radical_new_approach.md` in the following ways:

1. **Git-Based Version Control**: We're tracking all changes in a git repository and making incremental changes with clear commit messages
2. **Systematic Incremental Testing**: We're testing changes incrementally and documenting results
3. **Diagnostic-Driven Development**: We've created comprehensive logging tools to diagnose issues
4. **Regex Pattern Simplification**: We've verified that a minimal highlights.scm without regex patterns works without errors
5. **Parser/Query Relationship Analysis**: We've documented the relationship between the parser and queries

## Step-by-Step Plan

### Phase 1: Fix Parser Registration (Priority)

1. Create a new file `lua/parser_loader.lua` with a robust parser loading function:
   ```lua
   local M = {}
   
   function M.ensure_parser_loaded()
     -- First try to load from ~/.config/nvim/parser/
     local spthy_parser_path = vim.fn.expand('~/.config/nvim/parser/spthy/spthy.so')
     local tamarin_parser_path = vim.fn.expand('~/.config/nvim/parser/tamarin/tamarin.so')
     
     -- Log which parser we're trying to load
     vim.notify("Trying to load spthy parser from: " .. spthy_parser_path, vim.log.levels.DEBUG)
     
     -- Attempt to add the spthy language
     local spthy_ok = false
     if vim.fn.filereadable(spthy_parser_path) == 1 then
       if vim.treesitter.language.add then
         spthy_ok = pcall(function() 
           vim.treesitter.language.add('spthy', {path = spthy_parser_path})
         end)
       end
     end
     
     -- Log result
     vim.notify("Spthy parser loaded: " .. tostring(spthy_ok), vim.log.levels.DEBUG)
     
     -- Register spthy for tamarin filetype if loaded successfully
     if spthy_ok and vim.treesitter.language.register then
       vim.treesitter.language.register('spthy', 'tamarin')
       vim.notify("Registered spthy parser for tamarin filetype", vim.log.levels.DEBUG)
     end
     
     return spthy_ok
   end
   
   return M
   ```

2. Modify the parser loading section in `init.lua` to use our new function

3. Test with the ultra-minimal highlights.scm to verify parser loading works correctly

### Phase 2: Create Progressive Regex Test Series

1. Create a series of highlights.scm files with progressively more complex regex patterns:
   - `highlights.scm.01_basic`: Just node captures, no regex
   - `highlights.scm.02_simple_regex`: Simple regex patterns without quantifiers
   - `highlights.scm.03_apostrophes`: Add apostrophe support without quantifiers
   - `highlights.scm.04_quantifiers`: Add quantifiers but no OR operators
   - `highlights.scm.05_or_operators`: Add OR operators

2. Test each version systematically to identify which patterns cause issues

3. Document findings in `hypotheses.md`

### Phase 3: Create Optimized highlights.scm

1. Based on test results, create an optimized version of highlights.scm that:
   - Uses only regex patterns that work reliably
   - Splits complex patterns into multiple simpler patterns
   - Avoids problematic combinations of features (apostrophes with quantifiers, etc.)

2. Test thoroughly with real Tamarin files

### Phase 4: Implement Robust Error Handling

1. Add explicit error handling for TreeSitter queries in `init.lua`:
   ```lua
   -- Safely load TreeSitter queries
   function safe_get_query(lang, query_name)
     local ok, query = pcall(vim.treesitter.query.get, lang, query_name)
     if not ok or not query then
       vim.notify("Failed to load " .. query_name .. " query for " .. lang, vim.log.levels.WARN)
       return nil
     end
     return query
   end
   ```

2. Add fallback to traditional syntax highlighting when TreeSitter fails

## Testing Methodology

1. **Parser Loading Tests**: Verify parsers are correctly registered using:
   ```lua
   print(vim.inspect(vim.treesitter.language.get_filetypes('spthy')))
   ```

2. **Query Parsing Tests**: Verify query parsing works using:
   ```lua
   local ok, result = pcall(vim.treesitter.query.parse, 'spthy', query_text)
   ```

3. **Highlighting Tests**: Verify highlighting works on real Tamarin files with apostrophes

4. **Error Handling Tests**: Verify graceful degradation when encountering errors

## Debug Tracking

We'll maintain a `debug_tracker.md` file to track:

1. All debug print statements added
2. All log files created
3. All temporary test files

All diagnostic outputs will be isolated in `/tmp/tamarin-debug/` to keep the repository clean.

## Success Criteria

We'll consider this issue fixed when:

1. Neovim can open Tamarin files with apostrophes without TreeSitter errors
2. Syntax highlighting is applied correctly to variables with apostrophes
3. The solution is robust to different Neovim versions
4. The solution is well-documented for future maintenance 