# Comprehensive Plan to Fix Tamarin TreeSitter Syntax Highlighting

Based on our research and testing, we have identified several issues with the Tamarin TreeSitter syntax highlighting and developed a comprehensive plan to fix them.

## Identified Issues

1. **Parser Symbol Mismatch**: The parser exports `_tree_sitter_spthy` but Neovim expects `tree_sitter_tamarin`.
2. **Language-to-Filetype Mapping**: The language (`spthy`) differs from the filetype (`tamarin`).
3. **Regex Stack Overflow**: Complex regex patterns in the `highlights.scm` file cause Vim's NFA regex engine to overflow its stack.
4. **Directory Structure Confusion**: Multiple parser locations and symlinks causing confusion.
5. **Redundant Code**: The current implementation in `lua/tamarin/` has redundant code that could be simplified.

## Implementation Plan

### 1. Clean up directory structure
- Standardize on the `spthy` name for parser-related files
- Remove redundant parsers (currently, both `parser/spthy/spthy.so` and `parser/tamarin/tamarin.so` exist)
- Ensure consistent file naming across all components

### 2. Use a simplified parser loader
- Implement a clean, minimal parser loader that registers the language properly
- Explicitly map the `spthy` language to the `tamarin` filetype
- Include robust error handling and diagnostic output

### 3. Create a safe, minimal highlights.scm
- Use the ultra-minimal approach with no complex regex patterns
- Focus on node-based captures that don't rely on regex
- For any regex patterns that are necessary, keep them extremely simple
- Avoid patterns with apostrophes, complex quantifiers, OR operators, and backreferences

### 4. Implement proper module architecture
- Create clear, focused modules with well-defined responsibilities
- Include diagnostic utilities to help troubleshoot issues
- Ensure modules are independent and easy to maintain

### 5. Add robust testing
- Create tests for all regex patterns to identify potential issues
- Test the parser loading and highlighting independently
- Include stress tests with complex Tamarin files

## Detailed Implementation Steps

### Step 1: Cleanup and Standardization

1. Back up any files before modifying them:
   ```bash
   mkdir -p ~/.config/nvim/backup/parser
   mkdir -p ~/.config/nvim/backup/queries
   ```

2. Standardize on the `spthy` parser:
   ```bash
   # Remove redundant parser if it exists
   if [ -f ~/.config/nvim/parser/tamarin/tamarin.so ]; then
     mv ~/.config/nvim/parser/tamarin/tamarin.so ~/.config/nvim/backup/parser/
   fi
   ```

3. Ensure proper directory structure:
   ```bash
   mkdir -p ~/.config/nvim/parser/spthy
   mkdir -p ~/.config/nvim/queries/spthy
   ```

### Step 2: Parser Loader Implementation

1. Create a simplified parser loader:
   ```lua
   -- ~/.config/nvim/lua/tamarin/parser.lua
   local M = {}
   
   -- Helper for logging
   local function log(msg, level)
     level = level or vim.log.levels.INFO
     vim.notify("[tamarin.parser] " .. msg, level)
   end
   
   -- Register parser with TreeSitter
   function M.register()
     if not vim.treesitter or not vim.treesitter.language then
       log("TreeSitter not available", vim.log.levels.WARN)
       return false
     end
     
     -- Find parser path
     local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
     if vim.fn.filereadable(parser_path) ~= 1 then
       log("Parser file not found: " .. parser_path, vim.log.levels.WARN)
       return false
     end
     
     -- Register language mapping
     local ok = pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
     if not ok then
       log("Failed to register language mapping", vim.log.levels.WARN)
       return false
     end
     
     -- Add parser (for Neovim 0.9+)
     if vim.treesitter.language.add then
       ok = pcall(vim.treesitter.language.add, 'spthy', { path = parser_path })
       if not ok then
         log("Failed to add parser", vim.log.levels.WARN)
         return false
       end
     end
     
     log("Parser registered successfully")
     return true
   end
   
   return M
   ```

### Step 3: Safe Highlights File Implementation

1. Create a minimal highlights.scm:
   ```scheme
   ;; Minimal Tamarin Syntax Highlighting
   ;; Focused on node-based captures to avoid regex issues
   
   ;; Keywords
   [
     "theory"
     "begin"
     "end"
     "rule"
     "lemma"
   ] @keyword
   
   ;; Comments
   (multi_comment) @comment
   (single_comment) @comment
   
   ;; Basic captures
   (theory
     theory_name: (ident) @type)
   
   (function_untyped) @function
   
   (linear_fact) @constant
   (persistent_fact) @constant
   
   (number) @number
   (string) @string
   ```

2. Save this to the correct location:
   ```bash
   # Write the file to the correct location
   # This would be done in the actual implementation
   ```

### Step 4: Main Module Implementation

1. Create the main Tamarin module:
   ```lua
   -- ~/.config/nvim/lua/tamarin/init.lua
   local M = {}
   
   -- Initialize Tamarin TreeSitter integration
   function M.setup()
     -- Load parser
     local parser = require('tamarin.parser')
     local success = parser.register()
     
     if not success then
       vim.notify("Tamarin TreeSitter parser registration failed", vim.log.levels.WARN)
       return false
     end
     
     -- Set up filetype detection
     vim.filetype.add({
       extension = {
         spthy = "tamarin",
         sapic = "tamarin"
       }
     })
     
     -- Set up autocommands for syntax highlighting
     vim.cmd([[
       augroup TamarinTreeSitter
         autocmd!
         autocmd FileType tamarin TSEnable highlight
       augroup END
     ]])
     
     return true
   end
   
   -- Run diagnostics
   function M.diagnose()
     -- Find parser files
     local parsers = vim.api.nvim_get_runtime_file("parser/*/*.so", true)
     print("Parser files:")
     for _, path in ipairs(parsers) do
       print("  " .. path)
     end
     
     -- Find query files
     local queries = vim.api.nvim_get_runtime_file("queries/*/*.scm", true)
     print("Query files:")
     for _, path in ipairs(queries) do
       print("  " .. path)
     end
     
     -- Test parser loading
     local parser = require('tamarin.parser')
     print("Parser registration: " .. tostring(parser.register()))
   end
   
   return M
   ```

### Step 5: Setup in init.lua

1. Add the setup call to init.lua:
   ```lua
   -- Add to ~/.config/nvim/init.lua
   -- Set up Tamarin TreeSitter integration
   local tamarin_ok, tamarin = pcall(require, 'tamarin')
   if tamarin_ok then
     tamarin.setup()
   else
     vim.notify("Failed to load Tamarin module", vim.log.levels.WARN)
   end
   ```

## Testing and Verification

1. After implementation, verify with a test file:
   ```
   theory Test
   begin
   
   // Test comment
   
   rule Test:
       [ ] --[ ]-> [ ]
   
   lemma test:
       "Test lemma"
   
   end
   ```

2. Check that syntax highlighting works correctly:
   ```
   nvim test.spthy
   ```

3. Run diagnostics if there are issues:
   ```
   :lua require('tamarin').diagnose()
   ```

## Gradual Enhancement

Once the basic implementation is working, we can gradually enhance the highlights.scm file:

1. Start with the ultra-minimal version
2. Add one pattern at a time, testing thoroughly after each addition
3. If a pattern causes issues, refactor it to be simpler or remove it
4. Keep detailed notes on which patterns work and which cause problems

By following this methodical approach, we can create a robust TreeSitter integration for Tamarin that provides good syntax highlighting without stack overflow errors. 