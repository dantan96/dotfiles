-- Tamarin Syntax Highlighting Colors
-- Colors to apply to TreeSitter captures defined in highlights.scm

local M = {}

-- Function to set up highlighting
function M.setup()
    ---------------------------------------------------
    -- COLORS AND STYLES (Alphabetically ordered)
    ---------------------------------------------------
    local blueBold                = { fg = "#00AAFF", bold = true }
    local blueBoldUnderlined      = { fg = "#00AAFF", bold = true, underline = true }
    local brownNoStyle            = { fg = "#8B4513" }
    local brownPlain              = { fg = "#8B4513", bold = false }
    local deeperPurple            = { fg = "#8877BB", bold = false }
    local goldBold                = { fg = "#FFD700", bold = true }
    local goldBoldUnderlined      = { fg = "#FFD700", bold = true, underline = true }
    local goldItalic              = { fg = "#FFD700", bold = false, italic = true }
    local grayItalic              = { fg = "#777777", italic = true }
    local grayPlain               = { fg = "#888888", bold = false }
    local greenNoStyle            = { fg = "#32CD32" }
    local greenPlain              = { fg = "#32CD32", bold = false }
    local hotPinkBold             = { fg = "#FF1493", bold = true }
    local hotPinkPlain            = { fg = "#FF69B4", bold = false }
    local lightPinkPlain          = { fg = "#FFB6C1", bold = false }
    local lilacBold               = { fg = "#D7A0FF", bold = true }
    local magentaBold             = { fg = "#FF00FF", bold = true }
    local mediumMagentaBold       = { fg = "#FF5FFF", bold = true }
    local mediumPurple            = { fg = "#9370DB", italic = false }
    local mutedPurple             = { fg = "#9966CC", bold = false }
    local orangeNoStyle           = { fg = "#FFA500" }
    local orangePlain             = { fg = "#FFA500", bold = false }
    local orchidItalic            = { fg = "#DA70D6", italic = true }
    local orchidPlain             = { fg = "#DA70D6" }
    local pinkPlain               = { fg = "#FFC0CB", italic = false }
    local purplePlain             = { fg = "#AA88FF" }
    local redBold                 = { fg = "#FF4040", bold = true }
    local redBoldUnderlined       = { fg = "#FF0000", bold = true, underline = true }
    local royalBlue               = { fg = "#4169E1", italic = false }
    local skyBluePlain            = { fg = "#87CEEB", bold = false }
    local slateBlue               = { fg = "#6A5ACD", italic = false }
    local slateGrayBold           = { fg = "#8899AA", bold = true }
    local slateGrayPlain          = { fg = "#8899AA" }
    local tomatoItalic            = { fg = "#FF6347", italic = true, bold = false }

    local highlights = {
    ---------------------------------------------------
    -- KEYWORDS AND STRUCTURE
    ---------------------------------------------------
    ["@keyword"]                  = magentaBold,               -- Keywords: theory, begin, end, rule, lemma, builtins, restriction, functions, equations
    ["@keyword.quantifier"]       = lilacBold,                 -- Quantifiers: All, Ex, ∀, ∃
    ["@keyword.module"]           = mediumMagentaBold,         -- Module keywords: builtins, functions, predicates, options
    ["@keyword.function"]         = magentaBold,               -- Function keywords: rule, lemma, axiom, restriction
    ["@keyword.tactic"]           = magentaBold,               -- Tactic keywords: tactic, presort, prio, deprio
    ["@keyword.tactic.value"]     = lilacBold,                 -- Tactic values: direct, sorry, simplify, solve, contradiction
    ["@keyword.macro"]            = magentaBold,               -- Macro keywords: macros, let, in
    ["@preproc"]                  = mutedPurple,               -- Preprocessor: #ifdef, #endif, #define, #include
    ["@preproc.identifier"]       = deeperPurple,              -- Preprocessor identifiers: PREPROCESSING, DEBUG, etc.
    
    ["@structure"]                = goldBold,                  -- Structure elements: protocol, for, accounts
    ["@type"]                     = goldItalic,                -- Theory/type names: name in 'theory <name>'
    ["@function.rule"]            = goldBold,                  -- Rule/lemma names: name in 'rule <name>:', 'lemma <name>:'
    ["@type.builtin"]             = goldBoldUnderlined,        -- Builtins: diffie-hellman, hashing, symmetric-encryption, signing, etc.
    ["@type.qualifier"]           = pinkPlain,                 -- Type qualifiers: private, public, fresh

    ---------------------------------------------------
    -- VARIABLES
    ---------------------------------------------------
    ["@variable"]                 = orangeNoStyle,             -- General variables: any identifier without special prefix
    ["@variable.public"]          = greenPlain,                -- Public variables: $A, A:pub
    ["@variable.fresh"]           = hotPinkPlain,              -- Fresh variables: ~k, ~id, ~ltk
    ["@variable.temporal"]        = skyBluePlain,              -- Temporal variables: #i, #j
    ["@variable.message"]         = orangePlain,               -- Message variables: no prefix or :msg
    ["@variable.number"]          = brownPlain,                -- Number variables/arities: 2 in f/2

    ---------------------------------------------------
    -- FACTS
    ---------------------------------------------------
    ["@fact.persistent"]          = redBold,                   -- Persistent facts: !Ltk, !Pk, !User
    ["@fact.linear"]              = blueBold,                  -- Linear facts: standard facts without ! prefix
    ["@function.builtin"]         = blueBoldUnderlined,        -- Built-in facts: Fr, In, Out, K
    ["@fact.action"]              = lightPinkPlain,            -- Action facts: inside --[ and ]->

    ---------------------------------------------------
    -- FUNCTIONS AND MACROS
    ---------------------------------------------------
    ["@function"]                 = tomatoItalic,              -- Regular functions: f(), pk(), h()
    ["@function.macro"]           = tomatoItalic,              -- Macro names: names defined in macro declarations
    ["@function.macro.call"]      = tomatoItalic,              -- Macro use in code: using a defined macro
    
    ---------------------------------------------------
    -- BRACKETS, PUNCTUATION, OPERATORS
    ---------------------------------------------------
    ["@operator"]                 = slateGrayBold,             -- Action brackets: --[ and ]->
    ["@punctuation.bracket"]      = slateGrayPlain,            -- Regular brackets: (), [], <>
    ["@punctuation.delimiter"]    = slateGrayPlain,            -- Punctuation: ,.;:
    ["@punctuation.special"]      = slateGrayBold,             -- Special punctuation: -->, ==>
    ["@operator.exponentiation"]  = purplePlain,               -- Exponentiation: ^
    ["@operator.logical"]         = grayPlain,                 -- Logical operators: &, |, not, =>

    ---------------------------------------------------
    -- NUMBERS, CONSTANTS, STRINGS
    ---------------------------------------------------
    ["@number"]                   = brownNoStyle,              -- Numbers: 1, 2, 3
    ["@constant"]                 = orchidPlain,               -- General constants: constants without decoration
    ["@constant.string"]          = orchidItalic,              -- String constants: quoted strings
    ["@public.constant"]          = hotPinkBold,               -- Public constants: 'g', 'pk', etc. (in single quotes)
    ["@string"]                   = greenNoStyle,              -- Strings: quoted text

    ---------------------------------------------------
    -- COMMENTS
    ---------------------------------------------------
    ["@comment"]                  = grayItalic,                -- Comments: // line comments and /* block comments */
    
    ---------------------------------------------------
    -- RULE STRUCTURE SPECIFIC
    ---------------------------------------------------
    ["@premise"]                  = slateBlue,                 -- Rule premises: left side of rule (before --[)
    ["@conclusion"]               = royalBlue,                 -- Rule conclusions: right side of rule (after ]->)
    ["@rule.simple"]              = mediumPurple,              -- Simple rules: entire rule structure
    
    ---------------------------------------------------
    -- ERROR HANDLING
    ---------------------------------------------------
    ["@error"]                    = redBoldUnderlined          -- Error nodes: for invalid syntax or parsing errors
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