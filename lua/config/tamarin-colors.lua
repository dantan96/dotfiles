-- Tamarin Syntax Highlighting Colors
-- Colors to apply to TreeSitter captures defined in highlights.scm

local M = {}

-- Function to set up highlighting
function M.setup()
    -- Load color definitions from colorscheme file
    local colors = require('config.spthy-colorscheme').colors
    
    -- Define highlighting groups specific to Tamarin/spthy
    local highlights = {
        ---------------------------------------------------
        -- KEYWORDS AND STRUCTURE
        ---------------------------------------------------
        ["@keyword"]                  = colors.magentaBold,               -- Keywords: theory, begin, end, rule, lemma, builtins, restriction, functions, equations
        ["@keyword.quantifier"]       = colors.lilacBold,                 -- Quantifiers: All, Ex, ∀, ∃
        ["@keyword.module"]           = colors.mediumMagentaBold,         -- Module keywords: builtins, functions, predicates, options
        ["@keyword.function"]         = colors.magentaBold,               -- Function keywords: rule, lemma, axiom, restriction
        ["@keyword.tactic"]           = colors.magentaBold,               -- Tactic keywords: tactic, presort, prio, deprio
        ["@keyword.tactic.value"]     = colors.lilacBold,                 -- Tactic values: direct, sorry, simplify, solve, contradiction
        ["@keyword.macro"]            = colors.magentaBold,               -- Macro keywords: macros, let, in
        ["@preproc"]                  = colors.mutedPurple,               -- Preprocessor: #ifdef, #endif, #define, #include
        ["@preproc.identifier"]       = colors.deeperPurple,              -- Preprocessor identifiers: PREPROCESSING, DEBUG, etc.
        
        ["@structure"]                = colors.goldBold,                  -- Structure elements: protocol, for, accounts
        ["@type"]                     = colors.goldItalic,                -- Theory/type names: name in 'theory <name>'
        ["@function.rule"]            = colors.goldBold,                  -- Rule/lemma names: name in 'rule <name>:', 'lemma <name>:'
        ["@type.builtin"]             = colors.goldBoldUnderlined,        -- Builtins: diffie-hellman, hashing, symmetric-encryption, signing, etc.
        ["@type.qualifier"]           = colors.pinkPlain,                 -- Type qualifiers: private, public, fresh

        ---------------------------------------------------
        -- VARIABLES - WITH DISTINCT CONTRASTING COLORS
        ---------------------------------------------------
        ["@variable"]                 = colors.orangeNoStyle,             -- Regular variables: general identifiers without special prefix
        ["@variable.public"]          = colors.deepGreen,                 -- Public variables: $A, A:pub - deep forest green as requested
        ["@variable.fresh"]           = colors.hotPinkPlain,              -- Fresh variables: ~k, ~id, ~ltk - distinctive hot pink
        ["@variable.temporal"]        = colors.skyBluePlain,              -- Temporal variables: #i, #j - vibrant sky blue
        ["@variable.message"]         = colors.orangePlain,               -- Message variables: no prefix or :msg - orange shade
        ["@variable.number"]          = colors.brownPlain,                -- Number variables/arities: 2 in f/2 - earthy brown

        ---------------------------------------------------
        -- FACTS - WITH DISTINCT CONTRASTING COLORS
        ---------------------------------------------------
        ["@fact.persistent"]          = colors.redBold,                   -- Persistent facts: !Ltk, !Pk, !User - bold red as requested
        ["@fact.linear"]              = colors.blueBold,                  -- Linear facts: standard facts without ! prefix - bold blue
        ["@function.builtin"]         = colors.blueBoldUnderlined,        -- Built-in facts: Fr, In, Out, K - same color as linear but underlined
        ["@fact.action"]              = colors.lightPinkPlain,            -- Action facts: inside --[ and ]-> - light pink for contrast

        ---------------------------------------------------
        -- FUNCTIONS AND MACROS
        ---------------------------------------------------
        ["@function"]                 = colors.tomatoItalic,              -- Regular functions: f(), pk(), h() - tomato with italic
        ["@function.macro"]           = colors.tomatoItalic,              -- Macro names: names defined in macro declarations
        ["@function.macro.call"]      = colors.tomatoItalic,              -- Macro use in code: using a defined macro
        
        ---------------------------------------------------
        -- BRACKETS, PUNCTUATION, OPERATORS
        ---------------------------------------------------
        ["@operator"]                 = colors.slateGrayBold,             -- Action brackets: --[ and ]->
        ["@punctuation.bracket"]      = colors.slateGrayPlain,            -- Regular brackets: (), [], <>
        ["@punctuation.delimiter"]    = colors.slateGrayPlain,            -- Punctuation: ,.;:
        ["@punctuation.special"]      = colors.slateGrayBold,             -- Special punctuation: -->, ==>
        ["@operator.exponentiation"]  = colors.purplePlain,               -- Exponentiation: ^
        ["@operator.logical"]         = colors.grayPlain,                 -- Logical operators: &, |, not, =>

        ---------------------------------------------------
        -- NUMBERS, CONSTANTS, STRINGS
        ---------------------------------------------------
        ["@number"]                   = colors.brownNoStyle,              -- Numbers: 1, 2, 3
        ["@constant"]                 = colors.orchidPlain,               -- General constants: constants without decoration
        ["@constant.string"]          = colors.orchidItalic,              -- String constants: quoted strings
        ["@public.constant"]          = colors.hotPinkBold,               -- Public constants: 'g', 'pk', etc. (in single quotes)
        ["@string"]                   = colors.deepGreen,                 -- Strings: quoted text

        ---------------------------------------------------
        -- COMMENTS
        ---------------------------------------------------
        ["@comment"]                  = colors.grayItalic,                -- Comments: // line comments and /* block comments */
        
        ---------------------------------------------------
        -- RULE STRUCTURE SPECIFIC
        ---------------------------------------------------
        ["@premise"]                  = colors.slateBlue,                 -- Rule premises: left side of rule (before --[)
        ["@conclusion"]               = colors.royalBlue,                 -- Rule conclusions: right side of rule (after ]->)
        ["@rule.simple"]              = colors.mediumPurple,              -- Simple rules: entire rule structure
        
        ---------------------------------------------------
        -- ERROR HANDLING
        ---------------------------------------------------
        ["@error"]                    = colors.redBoldUnderlined          -- Error nodes: for invalid syntax or parsing errors
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
                " Custom syntax matching for variable prefixes
                " Dollar sign variables (ensuring prefix has same color)
                syntax match tamarinPublicVar /\$[A-Za-z0-9_]\+/
                highlight link tamarinPublicVar @variable.public
                
                " Tilde variables for fresh values
                syntax match tamarinFreshVar /\~[A-Za-z0-9_]\+/
                highlight link tamarinFreshVar @variable.fresh
                
                " Hash variables for temporal values
                syntax match tamarinTemporalVar /#[A-Za-z0-9_]\+/
                highlight link tamarinTemporalVar @variable.temporal
                
                " Type-annotated variables
                syntax match tamarinPublicVarType /[A-Za-z0-9_]\+:pub/
                highlight link tamarinPublicVarType @variable.public
                
                syntax match tamarinFreshVarType /[A-Za-z0-9_]\+:fresh/
                highlight link tamarinFreshVarType @variable.fresh
                
                syntax match tamarinTemporalVarType /[A-Za-z0-9_]\+:temporal/
                highlight link tamarinTemporalVarType @variable.temporal
                
                syntax match tamarinMsgVarType /[A-Za-z0-9_]\+:msg/
                highlight link tamarinMsgVarType @variable.message
                
                " Built-in facts (underlined but same color)
                syntax keyword tamarinBuiltinFact Fr In Out K
                highlight link tamarinBuiltinFact @function.builtin
                
                " Make the ! part of persistent facts the same color
                syntax match tamarinPersistentFactMark /!/ contained
                highlight link tamarinPersistentFactMark @fact.persistent
                
                syntax match tamarinPersistentFact /![A-Za-z0-9_]\+/ contains=tamarinPersistentFactMark
                highlight link tamarinPersistentFact @fact.persistent
                
                " Public constants with special hot pink color
                syntax match tamarinPublicConstant /'[^']\+'/
                highlight link tamarinPublicConstant @public.constant
                
                " Action fact brackets with the same color
                syntax match tamarinActionBrackets /--\[/ 
                syntax match tamarinActionBracketsEnd /\]->/ 
                highlight link tamarinActionBrackets @operator
                highlight link tamarinActionBracketsEnd @operator
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
  @function.builtin    - Built-in facts (Fr, In, Out, K)
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
  @premise.linear      - Linear facts in premises
  @premise.persistent  - Persistent facts in premises
  @conclusion          - Rule conclusions
  @rule.simple         - Simple rules
  
ERROR HANDLING:
  @error               - Error nodes from the parser
--]]

return M 