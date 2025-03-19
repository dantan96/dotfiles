-- Tamarin Syntax Highlighting Colors
-- Colors to apply to TreeSitter captures defined in highlights.scm

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
    ["@function.builtin"] = { fg = "#00AAFF", bold = true, underline = true },
    -- Action facts - Light pink
    ["@fact.action"] = { fg = "#FFB6C1", bold = false },

    ---------------------------------------------------
    -- FUNCTIONS AND MACROS
    ---------------------------------------------------
    -- Regular functions - Gold with italics
    ["@function"] = { fg = "#FF6347", italic = true, bold = false },
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
    ["@operator"] = { fg = "#8899AA", bold = true },
    -- Regular brackets (consistent neutral color)
    ["@punctuation.bracket"] = { fg = "#8899AA" },
    -- Punctuation (consistent color throughout)
    ["@punctuation.delimiter"] = { fg = "#8899AA" },
    -- Arrows like -->
    ["@punctuation.special"] = { fg = "#8899AA", bold = true },
    -- Exponentiation operator ^
    ["@operator.exponentiation"] = { fg = "#AA88FF" },
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
    ["@comment"] = { fg = "#777777", italic = true },
    
    ---------------------------------------------------
    -- RULE STRUCTURE SPECIFIC
    ---------------------------------------------------
    -- Rule premises
    ["@premise"] = { fg = "#6A5ACD", italic = false },
    -- Rule conclusions
    ["@conclusion"] = { fg = "#4169E1", italic = false },
    -- Simple rules
    ["@rule.simple"] = { fg = "#9370DB", italic = false },
    
    ---------------------------------------------------
    -- ERROR HANDLING
    ---------------------------------------------------
    -- Error nodes for debugging
    ["@error"] = { fg = "#FF0000", bold = true, underline = true }
  }

  -- Register event to apply highlights ONLY when tamarin/spthy filetypes are loaded
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "tamarin", "spthy" },
    callback = function()
      -- Apply highlights to ensure they're set for this buffer
      for group, colors in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, colors)
      end

      -- Apply custom syntax highlighting for elements that TreeSitter might miss
      vim.cmd([[
        " Built-in facts
        syntax keyword tamarinBuiltinFact Fr In Out K
        highlight link tamarinBuiltinFact @function.builtin
        
        " Make the ! part of persistent facts the same color
        syntax match tamarinPersistentFactMark /!/ contained containedin=@fact.persistent
        highlight link tamarinPersistentFactMark @fact.persistent
        
        " Public constants with special hot pink color
        syntax match tamarinPublicConstant /'[^']\+'/
        highlight link tamarinPublicConstant @public.constant
      ]])

      if vim.g.tamarin_highlight_debug then
        vim.api.nvim_echo({ { "Tamarin colors applied for " .. vim.bo.filetype, "Normal" } }, false, {})
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
  @operator            - General operators
  @punctuation.bracket - Regular brackets ((), [], <>)
  @punctuation.delimiter - Punctuation (,.:;)
  @punctuation.special - Special punctuation (-->)
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

RULE STRUCTURE:
  @premise             - Rule premises
  @conclusion          - Rule conclusions
  @rule.simple         - Simple rules
  
ERROR HANDLING:
  @error               - Error nodes from the parser
--]]

return M 