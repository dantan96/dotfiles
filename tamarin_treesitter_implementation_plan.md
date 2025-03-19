# Tamarin TreeSitter Integration: Comprehensive Implementation Plan

## The overall context of the project
Neovim uses TreeSitter for advanced syntax highlighting, but the current configuration for Tamarin protocol files is not working correctly. The primary issue is that syntax highlighting fails, particularly for variables containing apostrophes, with the error: "couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!".

Our analysis of the documentation (see `treesitter_documentation_analysis.md`, `facts.md`, and `pitfalls.md`) reveals that we're dealing with multiple issues:
1. Parser symbol mismatch - The parser exports `_tree_sitter_spthy` but Neovim expects `tree_sitter_tamarin`
2. Language-to-filetype mapping issues - The language (`spthy`) differs from the filetype (`tamarin`)
3. Query file issues - Complex regex patterns in `highlights.scm` are causing stack overflows
4. Inconsistent directory structure - Multiple parser locations and symlinks causing confusion

Previous debugging efforts (documented in `curing_my_idiocy.md`) have established that we need a systematic approach rather than ad-hoc fixes.

## The objective of this specific plan
To implement a robust, well-documented solution for TreeSitter syntax highlighting of Tamarin protocol files that:
1. Correctly loads the TreeSitter parser
2. Properly maps the language to the filetype
3. Uses safe, effective highlighting patterns
4. Gracefully handles errors and provides fallbacks
5. Works reliably in all directories, including subdirectories

## The bigger-picture: what's the point of achieving this objective?
Proper syntax highlighting is fundamental for effective code editing. By fixing this issue:
1. Tamarin protocol files will be easier to read and navigate
2. Syntax errors will be more obvious during editing
3. Code structure will be more visually apparent
4. The editing experience will be more consistent with other languages
5. The frustration of dealing with broken highlighting will be eliminated

Beyond the immediate benefits, this solution demonstrates a methodical approach to solving Neovim configuration issues that can be applied to other languages and plugins.

## Detailed step-by-step plan

### Step 1: Clean up and standardize parser locations
- Create a clean, standardized directory structure for parsers and queries
- Eliminate redundant or conflicting parser files
- Ensure consistent naming across related components

#### Mini-steps:
1. **Identify all parser files**
   ```bash
   find ~/.config/nvim/parser -type f -name "*.so"
   ```
   This command lists all TreeSitter parser files in the Neovim configuration.

2. **Check parser symbols**
   ```bash
   nm -gU ~/.config/nvim/parser/spthy/spthy.so | grep tree_sitter
   ```
   This verifies the symbol names exported by the parser (confirmed: `_tree_sitter_spthy`).

3. **Identify all query files**
   ```bash
   find ~/.config/nvim/queries -type f -name "*.scm"
   ```
   This lists all TreeSitter query files in the Neovim configuration.

4. **Create standardized directory structure**
   - Keep the primary parser at `~/.config/nvim/parser/spthy/spthy.so`
   - Keep the primary query file at `~/.config/nvim/queries/spthy/highlights.scm`
   - Remove any redundant parser files (like `~/.config/nvim/parser/tamarin/tamarin.so`)
   - Remove any symlinks that cause confusion

5. **Execute cleanup commands** (if needed)
   ```bash
   # Backup any files before removing
   mkdir -p ~/.config/nvim/backup/parser
   mkdir -p ~/.config/nvim/backup/queries
   
   # Move redundant parsers to backup
   mv ~/.config/nvim/parser/tamarin/tamarin.so ~/.config/nvim/backup/parser/
   
   # Create proper directory structure if needed
   mkdir -p ~/.config/nvim/queries/spthy
   ```

#### Why Step 1 was done
Having a clean, standardized directory structure eliminates confusion about which parser and query files are being used. This addresses a common pitfall identified in `pitfalls.md`: "Having parsers in multiple locations without being aware of which one is being loaded." By standardizing on the `spthy` name for both the parser and query directories, we ensure consistency with the parser's exported symbol (`_tree_sitter_spthy`).

### Step 2: Create a simplified, working query file
- Create a minimal `highlights.scm` that avoids complex regex patterns
- Focus on core language elements first, then expand gradually
- Ensure the query file syntax is valid

#### Mini-steps:
1. **Create backup of current query file** (if it exists)
   ```bash
   if [ -f ~/.config/nvim/queries/spthy/highlights.scm ]; then
     cp ~/.config/nvim/queries/spthy/highlights.scm ~/.config/nvim/backup/queries/highlights.scm.bak
   fi
   ```

2. **Create a minimal query file**
   ```bash
   cat > ~/.config/nvim/queries/spthy/highlights.scm << 'EOF'
   ;; Basic Tamarin language elements - minimal version
   
   ;; Keywords
   [
     "theory"
     "begin"
     "end"
     "rule"
     "let"
     "in"
     "functions"
     "equations"
     "builtins"
     "lemma"
     "axiom"
     "restriction"
   ] @keyword
   
   ;; Basic elements
   (string) @string
   (comment) @comment
   
   ;; Functions and variables - simple captures, no complex regex
   (function_declaration name: (identifier) @function)
   (function_call name: (identifier) @function.call)
   (variable) @variable
   EOF
   ```
   This creates a minimal query file with basic syntax elements but avoids complex regex patterns.

3. **Validate query syntax**
   ```lua
   -- In Neovim, run:
   :lua print(vim.treesitter.query.parse('spthy', io.open(vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm', 'r'):read('*all')))
   ```
   This validates that the query file syntax is correct.

#### Why Step 2 was done
As identified in `curing_my_idiocy.md` and `pitfalls.md`, complex regex patterns in queries can cause stack overflows in Neovim's regex engine. Starting with a minimal query file that avoids complex patterns ensures we have a working base to build upon. This follows the advice in `treesitter_documentation_analysis.md` to "avoid regex complexity" in query files.

### Step 3: Create a robust parser loader module
- Implement a Lua module that properly loads and registers the TreeSitter parser
- Include comprehensive error handling
- Check for API availability to ensure compatibility

#### Mini-steps:
1. **Create directory structure for Lua modules**
   ```bash
   mkdir -p ~/.config/nvim/lua/tamarin
   ```

2. **Create parser loader module**
   ```bash
   cat > ~/.config/nvim/lua/tamarin/parser.lua << 'EOF'
   -- Tamarin TreeSitter parser loader
   -- Handles loading and registering the TreeSitter parser for Tamarin/Spthy files
   
   local M = {}
   
   -- Helper function for logging
   local function log(message, level)
     level = level or vim.log.levels.INFO
     vim.notify("[tamarin.parser] " .. message, level)
   end
   
   -- Safely call a function with pcall and return a boolean result
   local function safe_call(fn, ...)
     local ok, result = pcall(fn, ...)
     return ok and result ~= nil
   end
   
   -- Check if the TreeSitter API is available
   function M.has_treesitter()
     return vim.treesitter ~= nil and vim.treesitter.language ~= nil
   end
   
   -- Find the parser file
   function M.find_parser()
     local parser_path = vim.fn.stdpath('config') .. '/parser/spthy/spthy.so'
     if vim.fn.filereadable(parser_path) == 1 then
       return parser_path
     end
     
     local runtime_parsers = vim.api.nvim_get_runtime_file('parser/spthy/spthy.so', false)
     if #runtime_parsers > 0 then
       return runtime_parsers[1]
     end
     
     log("Parser file not found", vim.log.levels.WARN)
     return nil
   end
   
   -- Register the parser with TreeSitter
   function M.register_parser()
     if not M.has_treesitter() then
       log("TreeSitter not available", vim.log.levels.WARN)
       return false
     end
     
     local parser_path = M.find_parser()
     if not parser_path then
       return false
     end
     
     -- Register language to filetype mapping
     local register_ok = safe_call(vim.treesitter.language.register, 'spthy', 'tamarin')
     if not register_ok then
       log("Failed to register language", vim.log.levels.WARN)
       return false
     end
     
     -- Add parser from path (Neovim 0.9+)
     if vim.treesitter.language.add then
       local add_ok = safe_call(vim.treesitter.language.add, 'spthy', { path = parser_path })
       if not add_ok then
         log("Failed to add parser", vim.log.levels.WARN)
       end
     end
     
     log("Parser registered successfully")
     return true
   end
   
   return M
   EOF
   ```
   This creates a robust parser loader module with error handling and compatibility checks.

#### Why Step 3 was done
A dedicated parser loader module encapsulates the complexity of loading and registering the TreeSitter parser. By including comprehensive error handling and compatibility checks, it addresses the issues identified in `treesitter_documentation_analysis.md` and `pitfalls.md` regarding parser loading reliability. The module handles the critical task of mapping the `spthy` language to the `tamarin` filetype through `vim.treesitter.language.register`.

### Step 4: Create a highlighter module
- Implement a module for setting up TreeSitter highlighting for Tamarin buffers
- Include buffer-specific setup and garbage collection prevention
- Provide fallback to traditional syntax highlighting

#### Mini-steps:
1. **Create highlighter module**
   ```bash
   cat > ~/.config/nvim/lua/tamarin/highlighter.lua << 'EOF'
   -- Tamarin TreeSitter highlighter
   -- Handles setting up TreeSitter highlighting for Tamarin buffers
   
   local M = {}
   
   -- Helper function for logging
   local function log(message, level)
     level = level or vim.log.levels.INFO
     vim.notify("[tamarin.highlighter] " .. message, level)
   end
   
   -- Safely call a function with pcall
   local function safe_call(fn, ...)
     local status, result = pcall(fn, ...)
     return status, result
   end
   
   -- Set up TreeSitter highlighting for a buffer
   function M.setup_highlighting(bufnr)
     bufnr = bufnr or 0
     
     -- Skip if not a Tamarin buffer
     if vim.bo[bufnr].filetype ~= "tamarin" then
       return false
     end
     
     -- Check if TreeSitter is available
     if not vim.treesitter or not vim.treesitter.highlighter then
       log("TreeSitter highlighter not available", vim.log.levels.WARN)
       return false
     end
     
     -- Get parser
     local parser_ok, parser = safe_call(vim.treesitter.get_parser, bufnr, 'spthy')
     if not parser_ok or not parser then
       log("Failed to get parser", vim.log.levels.WARN)
       return false
     end
     
     -- Create highlighter
     local highlighter_ok, highlighter = safe_call(vim.treesitter.highlighter.new, parser)
     if not highlighter_ok or not highlighter then
       log("Failed to create highlighter", vim.log.levels.WARN)
       return false
     end
     
     -- Store in buffer-local variable to prevent garbage collection
     vim.b[bufnr].tamarin_ts_highlighter = highlighter
     
     log("Highlighting set up for buffer " .. bufnr)
     return true
   end
   
   -- Set up fallback syntax highlighting
   function M.setup_fallback(bufnr)
     bufnr = bufnr or 0
     
     -- Skip if not a Tamarin buffer
     if vim.bo[bufnr].filetype ~= "tamarin" then
       return false
     end
     
     -- Enable regular syntax highlighting
     vim.cmd("syntax enable")
     
     log("Fallback syntax highlighting enabled", vim.log.levels.INFO)
     return true
   end
   
   -- Ensure some form of highlighting is set up
   function M.ensure_highlighting(bufnr)
     -- Try TreeSitter first
     local ts_ok = M.setup_highlighting(bufnr)
     
     -- Fall back to regular syntax if TreeSitter fails
     if not ts_ok then
       return M.setup_fallback(bufnr)
     end
     
     return ts_ok
   end
   
   return M
   EOF
   ```
   This creates a highlighter module that sets up TreeSitter highlighting for Tamarin buffers and falls back to traditional syntax highlighting if needed.

#### Why Step 4 was done
A dedicated highlighter module encapsulates the complexity of setting up TreeSitter highlighting for Tamarin buffers. It addresses the issues identified in `treesitter_documentation_analysis.md` regarding buffer-specific setup and garbage collection prevention. The module provides a fallback to traditional syntax highlighting, ensuring that users always have some form of highlighting even if TreeSitter fails.

### Step 5: Create a debug module
- Implement a module for diagnosing TreeSitter issues
- Include functions for checking parser status, query files, and highlighting
- Provide detailed information for troubleshooting

#### Mini-steps:
1. **Create debug module**
   ```bash
   cat > ~/.config/nvim/lua/tamarin/debug.lua << 'EOF'
   -- Tamarin TreeSitter debug utilities
   -- Provides tools for diagnosing TreeSitter issues
   
   local M = {}
   
   -- Helper function for logging
   local function log(message)
     print("[tamarin.debug] " .. message)
   end
   
   -- Check parser locations
   function M.check_parser_locations()
     local result = {
       parsers = vim.api.nvim_get_runtime_file("parser/*/*.so", true),
       spthy_parsers = vim.api.nvim_get_runtime_file("parser/spthy/*.so", true),
       tamarin_parsers = vim.api.nvim_get_runtime_file("parser/tamarin/*.so", true)
     }
     
     log("Parser locations:")
     vim.pretty_print(result)
     
     return result
   end
   
   -- Check query files
   function M.check_query_files()
     local result = {
       query_files = vim.api.nvim_get_runtime_file("queries/*/*.scm", true),
       spthy_queries = vim.api.nvim_get_runtime_file("queries/spthy/*.scm", true),
       tamarin_queries = vim.api.nvim_get_runtime_file("queries/tamarin/*.scm", true)
     }
     
     log("Query files:")
     vim.pretty_print(result)
     
     return result
   end
   
   -- Check TreeSitter status
   function M.check_treesitter_status()
     local result = {
       treesitter_available = vim.treesitter ~= nil,
       language_module = vim.treesitter and vim.treesitter.language ~= nil,
       highlighter_module = vim.treesitter and vim.treesitter.highlighter ~= nil,
       query_module = vim.treesitter and vim.treesitter.query ~= nil
     }
     
     log("TreeSitter status:")
     vim.pretty_print(result)
     
     return result
   end
   
   -- Check parser status
   function M.check_parser_status()
     local parser_ok, parser = pcall(vim.treesitter.get_parser, 0, 'spthy')
     
     local result = {
       parser_get_success = parser_ok,
       parser_object = parser_ok and "Available" or nil,
       language_registered = vim.treesitter.language and 
                            vim.treesitter.language.get and 
                            pcall(vim.treesitter.language.get, 'spthy')
     }
     
     log("Parser status:")
     vim.pretty_print(result)
     
     return result
   end
   
   -- Check highlighting status
   function M.check_highlighting_status()
     local result = {
       current_buffer = vim.api.nvim_get_current_buf(),
       filetype = vim.bo.filetype,
       ts_highlighter_active = vim.treesitter.highlighter and 
                              vim.treesitter.highlighter.active and 
                              vim.treesitter.highlighter.active[0] ~= nil,
       buffer_highlighter = vim.b[0].tamarin_ts_highlighter ~= nil
     }
     
     log("Highlighting status:")
     vim.pretty_print(result)
     
     return result
   end
   
   -- Run all checks
   function M.diagnose()
     log("Running comprehensive diagnostics...")
     M.check_parser_locations()
     M.check_query_files()
     M.check_treesitter_status()
     M.check_parser_status()
     M.check_highlighting_status()
     log("Diagnostics complete")
   end
   
   return M
   EOF
   ```
   This creates a debug module with comprehensive diagnostic functions.

#### Why Step 5 was done
A dedicated debug module provides tools for diagnosing TreeSitter issues, which is essential for troubleshooting and maintenance. This addresses the recommendation in `treesitter_documentation_analysis.md` for robust error handling and diagnostic capabilities. The module helps identify issues with parser locations, query files, and highlighting status, making it easier to debug problems that may arise in the future.

### Step 6: Create the main integration module
- Implement the main module that ties everything together
- Include initialization, setup, and configuration
- Provide a clean API for users

#### Mini-steps:
1. **Create main module**
   ```bash
   cat > ~/.config/nvim/lua/tamarin/init.lua << 'EOF'
   -- Tamarin TreeSitter integration
   -- Main module for Tamarin/Spthy TreeSitter integration
   
   local M = {}
   
   -- Helper function for logging
   local function log(message, level)
     level = level or vim.log.levels.INFO
     vim.notify("[tamarin] " .. message, level)
   end
   
   -- Initialize the module
   function M.setup()
     -- Load parser
     local parser = require('tamarin.parser')
     if not parser.has_treesitter() then
       log("TreeSitter not available, using fallback syntax highlighting", vim.log.levels.WARN)
       return false
     end
     
     -- Register parser
     local parser_ok = parser.register_parser()
     if not parser_ok then
       log("Failed to register parser, using fallback syntax highlighting", vim.log.levels.WARN)
       return false
     end
     
     -- Set up autocommands for buffer highlighting
     vim.cmd([[
       augroup TamarinTreeSitter
         autocmd!
         autocmd FileType tamarin lua require('tamarin.highlighter').ensure_highlighting(0)
       augroup END
     ]])
     
     -- Set up filetype detection
     vim.filetype.add({
       extension = {
         spthy = "tamarin",
         sapic = "tamarin"
       }
     })
     
     log("Tamarin TreeSitter integration initialized successfully")
     return true
   end
   
   -- Ensure highlighting for current buffer
   function M.ensure_highlighting()
     local highlighter = require('tamarin.highlighter')
     return highlighter.ensure_highlighting(0)
   end
   
   -- Run diagnostics
   function M.diagnose()
     local debug = require('tamarin.debug')
     return debug.diagnose()
   end
   
   return M
   EOF
   ```
   This creates the main integration module that ties everything together.

#### Why Step 6 was done
The main integration module provides a clean, centralized entry point for the Tamarin TreeSitter integration. It coordinates the various components (parser loader, highlighter, debug) and provides a simple API for users. This addresses the recommendations in `syntax_highlighting_a_thorough_complete_plan_to_fix_forever_no_matter_what.md` for a modular, maintainable design with clear separation of concerns.

### Step 7: Update the highlights.scm file with progressively more complex patterns
- Gradually add more complex highlighting patterns
- Test each addition for regex stack overflow issues
- Ensure comprehensive language coverage

#### Mini-steps:
1. **Create an expanded query file**
   ```bash
   cat > ~/.config/nvim/queries/spthy/highlights.scm << 'EOF'
   ;; Tamarin/Spthy syntax highlighting
   
   ;; Keywords
   [
     "theory"
     "begin"
     "end"
     "rule"
     "let"
     "in"
     "functions"
     "equations"
     "builtins"
     "lemma"
     "axiom"
     "restriction"
     "protocol"
     "property"
     "all"
     "exists"
     "or"
     "and"
     "not"
     "if"
     "then"
     "else"
   ] @keyword
   
   ;; Basic types
   (string) @string
   (comment) @comment
   (number) @number
   
   ;; Functions and variables - simple captures without complex regex
   (function_declaration name: (identifier) @function)
   (function_call name: (identifier) @function.call)
   (variable) @variable
   
   ;; Operators
   [
     "="
     "=="
     "!="
     "<"
     ">"
     "<="
     ">="
     "+"
     "-"
     "*"
     "/"
     "^"
   ] @operator
   
   ;; Delimiters
   [
     "("
     ")"
     "["
     "]"
     "{"
     "}"
     ","
     ";"
     ":"
   ] @delimiter
   
   ;; Special identifiers - safe pattern matching
   ((identifier) @constant
    (#match? @constant "^[A-Z][A-Z0-9_]*$"))
   
   ;; Add more patterns here as they are confirmed safe
   EOF
   ```
   This creates an expanded query file with more complex patterns, but still avoids the problematic regex patterns that caused stack overflows.

2. **Test the expanded query file**
   ```lua
   -- In Neovim, run:
   :lua print(vim.treesitter.query.parse('spthy', io.open(vim.fn.stdpath('config') .. '/queries/spthy/highlights.scm', 'r'):read('*all')))
   ```
   This validates that the expanded query file syntax is correct.

3. **Gradually add more complex patterns** 
   - Test each new pattern with actual Tamarin files
   - Verify that no regex stack overflow errors occur
   - Document pattern complexity and potential issues

#### Why Step 7 was done
Gradually expanding the query file with more complex patterns allows us to provide comprehensive syntax highlighting while avoiding the regex stack overflow issues that plagued the previous implementation. This follows the recommendation in `curing_my_idiocy.md` to adopt a "progressive approach" to query file development, starting with simple patterns and gradually adding complexity.

### Step 8: Set up integration in init.lua
- Update the main Neovim configuration to use our new modules
- Ensure proper initialization
- Include error handling

#### Mini-steps:
1. **Edit init.lua**
   ```bash
   # Backup current init.lua
   cp ~/.config/nvim/init.lua ~/.config/nvim/init.lua.bak
   
   # Add our integration code - append to init.lua
   cat >> ~/.config/nvim/init.lua << 'EOF'
   
   -- Tamarin TreeSitter integration
   local tamarin_ok, tamarin = pcall(require, 'tamarin')
   if tamarin_ok then
     tamarin.setup()
   else
     vim.notify("Failed to load Tamarin TreeSitter integration", vim.log.levels.WARN)
   end
   EOF
   ```
   This adds our integration code to the main Neovim configuration.

2. **Test the integration**
   ```bash
   # Start Neovim
   nvim
   
   # In Neovim, run:
   :lua require('tamarin').diagnose()
   ```
   This tests that our integration is working properly.

#### Why Step 8 was done
Updating the main Neovim configuration ensures that our integration is automatically loaded and initialized when Neovim starts. The use of `pcall` ensures that any errors in our integration don't crash Neovim. This follows the recommendation in `treesitter_documentation_analysis.md` for robust error handling and graceful degradation.

### Step 9: Create a test file for verification
- Create a test file with various Tamarin syntax constructs
- Use it to verify that syntax highlighting is working
- Include edge cases that previously caused problems

#### Mini-steps:
1. **Create test directory**
   ```bash
   mkdir -p ~/tamarin-test
   ```

2. **Create test file**
   ```bash
   cat > ~/tamarin-test/test.spthy << 'EOF'
   theory Test
   begin
   
   // Basic keywords and constructs
   builtins: symmetric-encryption, hashing
   functions: f/1, g/2
   equations: f(x) = g(x, x)
   
   // Rules
   rule Simple:
       [ ] --[ ]-> [ ]
   
   rule WithVariables:
       let x = 'foo'
       let y = 'bar'
       in
       [ In(x) ] --[ Processed(x, y) ]-> [ Out(y) ]
   
   // Variables with apostrophes (previously problematic)
   rule Apostrophes:
       let x' = 'foo'
       let y' = 'bar'
       in
       [ In(x') ] --[ Processed(x', y') ]-> [ Out(y') ]
   
   // Lemmas
   lemma secrecy:
       "∀ x #i. Secret(x) @ i ⟹ ¬(∃ #j. K(x) @ j)"
   
   end
   EOF
   ```
   This creates a test file with various Tamarin syntax constructs, including variables with apostrophes that previously caused problems.

3. **Test with Neovim**
   ```bash
   # Start Neovim with the test file
   nvim ~/tamarin-test/test.spthy
   
   # In Neovim, run diagnostics
   :lua require('tamarin').diagnose()
   ```
   This tests that our integration properly handles the test file.

#### Why Step 9 was done
Creating a test file with various Tamarin syntax constructs allows us to verify that our integration is working properly. Including edge cases that previously caused problems ensures that we've addressed the specific issues that motivated this project. This follows the recommendation in `syntax_highlighting_a_thorough_complete_plan_to_fix_forever_no_matter_what.md` for comprehensive testing.

### Step 10: Document the solution
- Create documentation for users
- Include installation instructions, configuration options, and troubleshooting
- Provide a README for future maintainers

#### Mini-steps:
1. **Create documentation directory**
   ```bash
   mkdir -p ~/.config/nvim/doc/tamarin
   ```

2. **Create user documentation**
   ```bash
   cat > ~/.config/nvim/doc/tamarin/README.md << 'EOF'
   # Tamarin TreeSitter Integration for Neovim
   
   This module provides TreeSitter-based syntax highlighting for Tamarin protocol verification files (*.spthy, *.sapic).
   
   ## Features
   
   - TreeSitter-based syntax highlighting for Tamarin files
   - Robust parser loading and registration
   - Automatic fallback to traditional syntax highlighting if TreeSitter fails
   - Comprehensive diagnostics for troubleshooting
   
   ## Requirements
   
   - Neovim 0.9 or later
   - TreeSitter support in Neovim
   
   ## Installation
   
   The module is included in the Neovim configuration and should work automatically for Tamarin files.
   
   ## Usage
   
   Opening a Tamarin file (*.spthy, *.sapic) should automatically trigger TreeSitter syntax highlighting.
   
   If you experience issues, you can run diagnostics:
   
   ```lua
   :lua require('tamarin').diagnose()
   ```
   
   To manually ensure highlighting for the current buffer:
   
   ```lua
   :lua require('tamarin').ensure_highlighting()
   ```
   
   ## Troubleshooting
   
   If syntax highlighting isn't working:
   
   1. Run diagnostics: `:lua require('tamarin').diagnose()`
   2. Check that the parser is found and registered
   3. Verify that TreeSitter is available in your Neovim build
   4. Ensure the buffer's filetype is set to "tamarin"
   
   ## Architecture
   
   The integration consists of several modules:
   
   - `tamarin/init.lua`: Main entry point and API
   - `tamarin/parser.lua`: Parser loading and registration
   - `tamarin/highlighter.lua`: Syntax highlighting setup
   - `tamarin/debug.lua`: Diagnostic utilities
   
   TreeSitter queries are defined in:
   
   - `queries/spthy/highlights.scm`: Syntax highlighting patterns
   
   ## Known Limitations
   
   - Complex regex patterns in variables may still cause issues
   - Some advanced Tamarin constructs may not be highlighted optimally
   EOF
   ```
   This creates user documentation for the Tamarin TreeSitter integration.

3. **Create developer documentation**
   ```bash
   cat > ~/.config/nvim/doc/tamarin/DEVELOPMENT.md << 'EOF'
   # Tamarin TreeSitter Integration: Developer Documentation
   
   This document provides information for developers maintaining or extending the Tamarin TreeSitter integration.
   
   ## Architecture
   
   ### Component Overview
   
   - `tamarin/init.lua`: Main entry point and API
   - `tamarin/parser.lua`: Parser loading and registration
   - `tamarin/highlighter.lua`: Syntax highlighting setup
   - `tamarin/debug.lua`: Diagnostic utilities
   - `queries/spthy/highlights.scm`: Syntax highlighting patterns
   
   ### Parser Loading
   
   The parser is loaded from `parser/spthy/spthy.so` and registered for the "tamarin" filetype using `vim.treesitter.language.register`.
   
   Key considerations:
   - The parser exports the symbol `_tree_sitter_spthy` (note the underscore prefix on macOS)
   - The language name is "spthy"
   - The filetype is "tamarin"
   
   ### Highlighting
   
   TreeSitter highlighting is set up for each buffer using `vim.treesitter.highlighter.new`.
   
   Key considerations:
   - The highlighter must be stored in a buffer-local variable to prevent garbage collection
   - Fallback to traditional syntax highlighting is provided if TreeSitter fails
   
   ## Query File Development
   
   When modifying the `highlights.scm` file:
   
   1. Start with simple patterns and gradually add complexity
   2. Test each pattern before committing
   3. Avoid complex regex patterns that could cause stack overflows
   4. Validate the query syntax using `vim.treesitter.query.parse`
   
   ## Known Issues
   
   ### Regex Stack Overflow
   
   Neovim's regex engine can overflow its stack with complex patterns. Symptoms:
   - Error: "couldn't parse regex: Vim:E874: (NFA) Could not pop the stack!"
   - Highlighting stops working
   
   Solution: Simplify regex patterns, especially those with nested quantifiers, alternations, or backreferences.
   
   ### Parser Symbol Mismatch
   
   The parser exports `_tree_sitter_spthy` but Neovim might expect a different symbol.
   
   Solution: The `register_parser` function handles this by explicitly registering the language.
   
   ## Testing
   
   To test changes:
   
   1. Create a test file with relevant syntax constructs
   2. Open it in Neovim
   3. Run diagnostics: `require('tamarin').diagnose()`
   4. Verify that highlighting works as expected
   
   ## Debugging
   
   The `tamarin.debug` module provides tools for diagnosing issues:
   
   - `check_parser_locations`: Identifies all parser files
   - `check_query_files`: Identifies all query files
   - `check_treesitter_status`: Verifies TreeSitter availability
   - `check_parser_status`: Checks parser loading status
   - `check_highlighting_status`: Checks highlighting status
   - `diagnose`: Runs all checks
   
   ## References
   
   - [Neovim TreeSitter Documentation](https://neovim.io/doc/user/treesitter.html)
   - [TreeSitter Documentation](https://tree-sitter.github.io/tree-sitter/)
   - Project documentation: `treesitter_documentation_analysis.md`, `facts.md`, `pitfalls.md`
   EOF
   ```
   This creates developer documentation for future maintainers.

#### Why Step 10 was done
Comprehensive documentation is essential for both users and future maintainers. User documentation helps users understand how to use the integration and troubleshoot issues. Developer documentation helps future maintainers understand the architecture, known issues, and best practices for extending the integration. This follows the recommendation in `syntax_highlighting_a_thorough_complete_plan_to_fix_forever_no_matter_what.md` for thorough documentation. 