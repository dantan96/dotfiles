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
        ["@operator.assignment"]      = colors.slateGrayPlain,            -- Assignment operators: = in let statements
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

            -- Disable TreeSitter highlighting for specific patterns that we want to handle ourselves
            vim.api.nvim_exec([[
                " First clear any existing syntax to start fresh
                syntax clear

                " Basic elements for spthy files
                " =================================
                " Comments
                syntax match spthyComment /\/\/.*$/ contains=@Spell
                syntax region spthyComment start="/\*" end="\*/" fold contains=@Spell
                highlight link spthyComment @comment

                " Theory structure
                syntax keyword spthyKeyword theory begin end
                syntax keyword spthyKeyword rule lemma axiom builtins
                syntax keyword spthyKeyword functions equations predicates
                syntax keyword spthyKeyword restrictions let in
                highlight link spthyKeyword @keyword

                " Operators and punctuation
                " =================================
                " Equal sign in let statements - neutral color
                syntax match spthyOperator /=/ 
                highlight link spthyOperator @operator.assignment

                " Rule arrows and brackets with the same color
                syntax match spthyRuleArrow /--\[\|\]->/ 
                highlight link spthyRuleArrow @operator

                " Standard brackets and delimiters
                syntax match spthyBracket /(\|)\|\[\|\]\|{\|}\|,\|;\|:/
                highlight link spthyBracket @punctuation.bracket

                " Variables and terms
                " =================================
                " Fresh variables (~)
                syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ 
                highlight link spthyFreshVar @variable.fresh

                " Public variables ($)
                syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ 
                highlight link spthyPublicVar @variable.public

                " Temporal variables (#)
                syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/ 
                highlight link spthyTemporalVar @variable.temporal

                " Variable types (:pub, :fresh, etc)
                syntax match spthyPublicType /[A-Za-z0-9_]\+:pub/ 
                highlight link spthyPublicType @variable.public

                syntax match spthyFreshType /[A-Za-z0-9_]\+:fresh/ 
                highlight link spthyFreshType @variable.fresh

                syntax match spthyTemporalType /[A-Za-z0-9_]\+:temporal/ 
                highlight link spthyTemporalType @variable.temporal

                syntax match spthyMessageType /[A-Za-z0-9_]\+:msg/ 
                highlight link spthyMessageType @variable.message

                " Facts and predicates
                " =================================
                " Persistent facts (!)
                syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ 
                highlight link spthyPersistentFact @fact.persistent
                
                " Built-in facts (Fr, In, Out, K)
                syntax keyword spthyBuiltinFact Fr In Out K
                highlight link spthyBuiltinFact @function.builtin

                " Action facts
                syntax region spthyActionFact start=/--\[/ end=/\]->/ contains=spthyRuleArrow,spthyFreshVar,spthyPublicVar,spthyTemporalVar,spthyPersistentFact,spthyBuiltinFact,spthyNormalFact
                highlight link spthyActionFact @fact.action

                " Regular facts (not caught by others)
                syntax match spthyNormalFact /\<[A-Z][A-Za-z0-9_]*\>/ 
                highlight link spthyNormalFact @fact.linear

                " Functions and constants
                " =================================
                " Function names
                syntax match spthyFunction /\<[a-z][A-Za-z0-9_]*\>(/he=e-1
                highlight link spthyFunction @function

                " Constants in single quotes
                syntax region spthyConstant start=/'/ end=/'/ 
                highlight link spthyConstant @public.constant
                
                " Enable TreeSitter-based highlighting as a fallback
                try
                    if exists(":TSBufEnable")
                        TSBufEnable highlight
                    endif
                catch
                    " Ignore errors if TreeSitter is unavailable
                endtry

                " Always re-apply our most important syntax overrides
                syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ containedin=ALL
                highlight link spthyFreshVar @variable.fresh
                
                syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ containedin=ALL
                highlight link spthyPublicVar @variable.public
                
                syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ containedin=ALL
                highlight link spthyPersistentFact @fact.persistent
                
                syntax keyword spthyBuiltinFact Fr In Out K containedin=ALL
                highlight link spthyBuiltinFact @function.builtin
                
                syntax match spthyOperator /=/ containedin=ALL
                highlight link spthyOperator @operator.assignment
            ]], false)

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
  @operator.assignment - Assignment operators (=)
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