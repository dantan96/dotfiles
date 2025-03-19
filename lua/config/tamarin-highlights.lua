-- Tamarin Syntax Highlighting Colors
-- Updated version matching our systematically created highlights.scm

local M = {}

-- Function to set up highlighting
function M.setup()
    -- Define highlight groups with distinct colors
    local highlights = {
    ---------------------------------------------------
    -- KEYWORDS AND STRUCTURE
    ---------------------------------------------------
    -- Keywords (magenta) - includes theory, begin, end, rule, lemma, builtins, etc.
        ["@keyword"] = { fg = "#FF00FF", bold = true },
    -- Quantifiers - lighter purple for 'All' and 'Ex'
    ["@keyword.quantifier"] = { fg = "#D7A0FF", bold = true },
    -- Module-like keywords - like builtins, functions declarations
    ["@keyword.module"] = { fg = "#FF5FFF", bold = true },
    -- Function-like keywords - like rule declarations
    ["@keyword.function"] = { fg = "#FF00FF", bold = true }, -- Now same as regular keywords
    -- Tactic keywords - like 'tactic' itself
    ["@keyword.tactic"] = { fg = "#FF00FF", bold = true },
    -- Tactic values - like 'direct', 'sorry'
    ["@keyword.tactic.value"] = { fg = "#D7A0FF", bold = true },
    -- Preprocessor directives
    ["@preproc"] = { fg = "#9966CC", bold = false }, -- Muted purple for preprocessor
    ["@preproc.identifier"] = { fg = "#8877BB", bold = false }, -- Even more muted for the identifiers
    
    -- Structure elements (gold, using the appropriate styling)
    ["@structure"] = { fg = "#FFD700", bold = true },
    -- Theory names, etc.
    ["@type"] = { fg = "#FFD700", bold = false, italic = true },
    -- Rule/lemma/restriction names
    ["@function.rule"] = { fg = "#FFD700", bold = true, italic = false },
    -- Builtins like diffie-hellman
    ["@type.builtin"] = { fg = "#FFD700", bold = true, underline = true },
    -- Type qualifiers like 'private'
    ["@type.qualifier"] = { fg = "#FFC0CB", italic = false },

    ---------------------------------------------------
    -- VARIABLES
    ---------------------------------------------------
    -- General variables
    ["@variable"] = { fg = "#FFA500" }, -- Changed to a default message variable color
    -- Public variables ($A, A:pub)
    ["@variable.public"] = { fg = "#32CD32", bold = false },
    -- Fresh variables (~k)
    ["@variable.fresh"] = { fg = "#FF69B4", bold = false },
    -- Temporal variables (#i)
    ["@variable.temporal"] = { fg = "#87CEEB", bold = false },
    -- Message variables (no prefix or :msg)
    ["@variable.message"] = { fg = "#FFA500", bold = false },
    -- Number variables/arities (2 in f/2)
    ["@variable.number"] = { fg = "#8B4513", bold = false },

    ---------------------------------------------------
    -- FACTS
    ---------------------------------------------------
    -- Persistent facts (!Ltk) - Red with bold
    ["@fact.persistent"] = { fg = "#FF4040", bold = true },
    -- Linear facts - Blue with bold
    ["@fact.linear"] = { fg = "#00AAFF", bold = true },
    -- Special built-in facts (Fr, In, Out, K)
    ["@fact.builtin"] = { fg = "#00AAFF", bold = true, underline = true },
    -- Action facts - Light pink
    ["@fact.action"] = { fg = "#FFB6C1", bold = false },

    ---------------------------------------------------
    -- FUNCTIONS AND MACROS
    ---------------------------------------------------
    -- Regular functions - Gold with italics
    ["@function"] = { fg = "#FF6347", italic = true, bold = false },
    -- Built-in functions from builtins - Italic with underline
    ["@function.builtin"] = { fg = "#FF6347", italic = true, underline = true, bold = false },
    -- Macro names - Same as functions but can be distinguished
    ["@function.macro"] = { fg = "#FF6347", italic = true, bold = false },
    -- Macro use in code - Same styling as functions
    ["@function.macro.call"] = { fg = "#FF6347", italic = true, bold = false },
    -- Macro keyword - Same as regular keywords
    ["@keyword.macro"] = { fg = "#FF00FF", bold = true },

    ---------------------------------------------------
    -- BRACKETS, PUNCTUATION, OPERATORS
    ---------------------------------------------------
    -- Action brackets (--[ and ]->)
    ["@action.brackets"] = { fg = "#FFB6C1", bold = true },
    -- Regular brackets (consistent neutral color)
    ["@punctuation.bracket"] = { fg = "#8899AA" },
    -- Punctuation (consistent color throughout)
    ["@punctuation.delimiter"] = { fg = "#8899AA" },
    -- Arrows like -->
    ["@punctuation.special"] = { fg = "#8899AA", bold = true },
    -- Exponentiation operator ^
    ["@operator.exponentiation"] = { fg = "#AA88FF" },
    -- General operators
    ["@operator"] = { fg = "#888888" },
    -- Logical operators
    ["@operator.logical"] = { fg = "#888888", bold = false },

    ---------------------------------------------------
    -- NUMBERS, CONSTANTS, STRINGS
    ---------------------------------------------------
    -- Numbers
    ["@number"] = { fg = "#8B4513" },
    -- General constants
    ["@constant"] = { fg = "#DA70D6" },
    -- String constants
    ["@constant.string"] = { fg = "#DA70D6", italic = true },
    -- Public constants in single quotes
    ["@public.constant"] = { fg = "#FF1493", bold = true },
    -- Strings
    ["@string"] = { fg = "#32CD32" },

    ---------------------------------------------------
    -- COMMENTS
    ---------------------------------------------------
    -- Comments
    ["@comment"] = { fg = "#777777", italic = true }
  }

  -- Register event to apply highlights ONLY when tamarin/spthy filetypes are loaded
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "tamarin", "spthy" },
    callback = function()
      -- Apply highlights to ensure they're set for this buffer
      for group, colors in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, colors)
      end

      -- Create custom highlight groups for specific elements
      vim.api.nvim_set_hl(0, "TamarinArityNumber", { fg = "#8B4513", bold = true })
      vim.api.nvim_set_hl(0, "TamarinBuiltinFact", { fg = "#00AAFF", bold = true, underline = true })
      vim.api.nvim_set_hl(0, "TamarinPublicConstant", { fg = "#FF1493", bold = true })
      vim.api.nvim_set_hl(0, "TamarinMacroName", { fg = "#FF6347", italic = true, bold = false })
      vim.api.nvim_set_hl(0, "TamarinMacroCall", { fg = "#FF6347", italic = true, bold = false })
      vim.api.nvim_set_hl(0, "TamarinRuleName", { fg = "#FFD700", bold = true, italic = false })
      vim.api.nvim_set_hl(0, "TamarinBuiltinFunction", { fg = "#FF6347", italic = true, underline = true, bold = false })
      vim.api.nvim_set_hl(0, "TamarinPreprocessor", { fg = "#9966CC", bold = false })
      vim.api.nvim_set_hl(0, "TamarinPreprocessorIdent", { fg = "#8877BB", bold = false })

      -- Apply custom syntax highlighting for elements that TreeSitter might miss
      vim.cmd([[
        " Built-in facts
        syntax keyword tamarinBuiltinFact Fr In Out K
        highlight link tamarinBuiltinFact TamarinBuiltinFact
        
        " Make the ! part of persistent facts the same color
        syntax match tamarinPersistentFactMark /!/ contained containedin=tamarinPersistentFact,@fact.persistent
        highlight link tamarinPersistentFactMark @fact.persistent
        
        " Public constants with special hot pink color
        syntax match tamarinPublicConstant /'[^']\+'/
        highlight link tamarinPublicConstant TamarinPublicConstant
        
        " Built-in functions with underline
        syntax keyword tamarinBuiltinFunction senc sdec mac kdf pk h
        highlight link tamarinBuiltinFunction TamarinBuiltinFunction
        
        " Macro keyword
        syntax keyword tamarinMacroKeyword macro macros
        highlight link tamarinMacroKeyword @keyword.macro
        
        " Macro definition names
        syntax match tamarinMacroName /\<\(macro\|macros\)\s\+\zs[A-Z][A-Z0-9_]*/ 
        highlight link tamarinMacroName TamarinMacroName
        
        " Macro calls - uppercase function names (different from definitions)
        syntax match tamarinMacroCall /\<[A-Z][A-Z0-9_]*\s*(/he=e-1 
        highlight link tamarinMacroCall TamarinMacroCall
        
        " Rule/lemma/restriction names - these should be bold, not italic
        syntax match tamarinRuleName /\<\(rule\|lemma\|restriction\|axiom\)\s\+\zs[A-Za-z0-9_]\+/
        highlight link tamarinRuleName TamarinRuleName
        
        " Preprocessor directives - enhanced for better highlighting
        syntax match tamarinPreprocessor /^\s*\zs#\(ifdef\|endif\|define\|include\)/
        highlight link tamarinPreprocessor TamarinPreprocessor
        
        " Preprocessor identifiers - immediately after preprocessor directive
        syntax match tamarinPreprocessorIdent /^\s*#\(ifdef\|define\)\s\+\zs[A-Z][A-Z0-9_]*/ 
        highlight link tamarinPreprocessorIdent TamarinPreprocessorIdent
        
        " Variables with typing and proper apostrophe handling
        " Public variables with $ prefix or :pub suffix
        syntax match tamarinPublicVar /\$[a-zA-Z][a-zA-Z0-9_]*'\{0,\}\|\<[a-zA-Z][a-zA-Z0-9_]*'\{0,\}:pub/
        highlight link tamarinPublicVar @variable.public
        
        " Fresh variables with ~ prefix or :fresh suffix
        syntax match tamarinFreshVar /\~[a-zA-Z][a-zA-Z0-9_]*'\{0,\}\|\<[a-zA-Z][a-zA-Z0-9_]*'\{0,\}:fresh/
        highlight link tamarinFreshVar @variable.fresh
        
        " Temporal variables with # prefix or :temporal suffix
        syntax match tamarinTemporalVar /#[a-zA-Z][a-zA-Z0-9_]*'\{0,\}\|\<[a-zA-Z][a-zA-Z0-9_]*'\{0,\}:temporal/
        highlight link tamarinTemporalVar @variable.temporal
        
        " Message variables (default case)
        syntax match tamarinMsgVar /\<[a-z][a-zA-Z0-9_]*'\{0,\}\|\<[a-z][a-zA-Z0-9_]*'\{0,\}:msg/
        syntax match tamarinMsgVar /\<[a-z][a-zA-Z0-9_]*'\>/
        highlight link tamarinMsgVar @variable.message
        
        " Enhance built-in function and macro highlighting to include parameters
        syntax region tamarinFunctionParams matchgroup=TamarinBuiltinFunction 
          \ start=/\<\(senc\|sdec\|mac\|kdf\|pk\|h\)\s*(/ end=/)/ contains=ALL keepend
        
        syntax region tamarinMacroParams matchgroup=TamarinMacroCall 
          \ start=/\<[A-Z][A-Z0-9_]*\s*(/ end=/)/ contains=ALL keepend
        
        " Ensure variable highlighting in macro/function parameters takes precedence
        syntax sync minlines=50
        syntax sync fromstart
      ]])

      if vim.g.tamarin_highlight_debug then
        vim.api.nvim_echo({ { "Tamarin highlights applied for " .. vim.bo.filetype, "Normal" } }, false, {})
      end
    end
  })
end

--[[
TAMARIN SYNTAX HIGHLIGHTING GROUPS DOCUMENTATION

This is a comprehensive list of all the syntax highlighting groups defined 
for Tamarin Protocol Specification Language.

To use these in your own colorscheme, you can set colors for any of these groups:

KEYWORDS AND STRUCTURE:
  @keyword             - Basic keywords (theory, begin, end, rule, lemma, etc.)
  @keyword.quantifier  - Quantifiers (All, Ex)
  @keyword.module      - Module-like keywords (builtins, functions declarations)
  @keyword.function    - Function-like keywords (rule declarations)
  @keyword.tactic      - Tactic keyword
  @keyword.tactic.value - Tactic values (direct, sorry, etc.)
  @keyword.macro       - Macro keyword
  @preproc             - Preprocessor directives (#ifdef, #endif, etc.)
  @preproc.identifier  - Preprocessor identifiers (PREPROCESSING, etc.)
  @structure           - Structure elements
  @type                - Theory names
  @type.builtin        - Builtins (diffie-hellman, etc.)
  @type.qualifier      - Type qualifiers (private)

VARIABLES:
  @variable            - General variables
  @variable.public     - Public variables ($A, A:pub)
  @variable.fresh      - Fresh variables (~k)
  @variable.temporal   - Temporal variables (#i)
  @variable.message    - Message variables (no prefix or :msg)
  @variable.number     - Number variables/arities

FACTS:
  @fact.persistent     - Persistent facts (!Ltk)
  @fact.linear         - Linear facts
  @fact.builtin        - Built-in facts (Fr, In, Out, K)
  @fact.action         - Action facts

FUNCTIONS AND MACROS:
  @function            - Regular functions
  @function.builtin    - Built-in functions (from builtins)
  @function.macro      - Macro names
  @function.macro.call - Macro calls in code
  @function.rule       - Rule, lemma, and restriction names

BRACKETS, PUNCTUATION, OPERATORS:
  @action.brackets     - Action brackets (--[ and ]->)
  @punctuation.bracket - Regular brackets ((), [], <>)
  @punctuation.delimiter - Punctuation (,.:;)
  @punctuation.special - Special punctuation (-->)
  @operator            - General operators
  @operator.logical    - Logical operators
  @operator.exponentiation - Exponentiation operator (^)

NUMBERS, CONSTANTS, STRINGS:
  @number              - Numbers
  @constant            - General constants
  @constant.string     - String constants
  @public.constant     - Public constants ('g', etc.)
  @string              - Strings

COMMENTS:
  @comment             - Comments (// and /* */)

CUSTOM HIGHLIGHT GROUPS (for traditional syntax):
  TamarinArityNumber       - Function arities
  TamarinBuiltinFact       - Built-in facts
  TamarinPublicConstant    - Public constants
  TamarinMacroName         - Macro names
  TamarinMacroCall         - Macro calls in code (uppercase functions)
  TamarinRuleName          - Rule, lemma, and restriction names
  TamarinBuiltinFunction   - Built-in functions
  TamarinPreprocessor      - Preprocessor directives
  TamarinPreprocessorIdent - Preprocessor identifiers
--]]

return M 
