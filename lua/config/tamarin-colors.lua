-- Tamarin Syntax Highlighting Colors
-- Colors to apply to TreeSitter captures defined in highlights.scm

local M = {}

-- Function to set up highlighting
function M.setup()
    -- Debug message to confirm the function is running
    print("Setting up Tamarin syntax highlighting...")
    
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
        ["@type"]                     = colors.goldItalic,                -- Theory/type names: name in 'theory <n>'
        ["@function.rule"]            = colors.goldBold,                  -- Rule/lemma names: name in 'rule <n>:', 'lemma <n>:'
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

    -- Apply all highlights immediately to the current buffer
    for group, colors in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, colors)
    end
    
    -- Force syntax on
    vim.cmd("syntax on")
    vim.cmd("syntax enable")
    
    -- Apply the VimScript syntax highlighting
    vim.api.nvim_exec([[
        " First clear any existing syntax to start fresh
        syntax clear
        
        " Comments - HIGHEST PRIORITY
        syntax match spthyComment /\/\/.*$/ contains=@Spell containedin=ALL
        syntax region spthyComment start="/\*" end="\*/" fold contains=@Spell containedin=ALL
        
        " Theory structure keywords
        syntax keyword spthyKeyword theory begin end
        syntax keyword spthyKeyword rule lemma axiom builtins
        syntax keyword spthyKeyword functions equations predicates
        syntax keyword spthyKeyword restrictions let in
        
        " Public variables with '$' prefix - HIGHEST PRIORITY
        syntax match spthyPublicVarPrefix /\$/ contained
        syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ contains=spthyPublicVarPrefix containedin=ALL
        
        " Fresh variables with '~' prefix - HIGHEST PRIORITY
        syntax match spthyFreshVarPrefix /\~/ contained
        syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ contains=spthyFreshVarPrefix containedin=ALL
        
        " Temporal variables with '#' prefix - HIGHEST PRIORITY
        syntax match spthyTemporalVarPrefix /#/ contained
        syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/ contains=spthyTemporalVarPrefix containedin=ALL
        
        " Variable types with explicit priority
        syntax match spthyPublicType /[A-Za-z0-9_]\+:pub/ containedin=ALL
        syntax match spthyFreshType /[A-Za-z0-9_]\+:fresh/ containedin=ALL
        syntax match spthyTemporalType /[A-Za-z0-9_]\+:temporal/ containedin=ALL
        syntax match spthyMessageType /[A-Za-z0-9_]\+:msg/ containedin=ALL
        
        " =============================================
        " FACTS - EXPLICITLY COLORED WITH PROPER PRIORITY
        " =============================================
        
        " Persistent fact prefix - specifically colored red
        syntax match spthyPersistentFactPrefix /!/ contained
        highlight link spthyPersistentFactPrefix @fact.persistent
        
        " Persistent facts - RED, with contained variables
        syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ contains=spthyPersistentFactPrefix
        
        " Built-in facts with highest priority after variables
        syntax keyword spthyBuiltinFact Fr In Out K
        
        " Action facts - force LIGHT PINK color
        syntax region spthyActionFact start=/--\[/ end=/\]->/ contains=spthyRuleArrow,spthyFreshVar,spthyPublicVar,spthyTemporalVar,spthyPersistentFact,spthyBuiltinFact,spthyNormalFact
        
        " Regular facts - explicit BLUE color
        syntax match spthyNormalFact /\<[A-Z][A-Za-z0-9_]*\>/ contains=NONE
        
        " =============================================
        " FUNCTIONS, OPERATORS AND PUNCTUATION
        " =============================================
        
        " Function names - TOMATO color
        syntax match spthyFunction /\<[a-z][A-Za-z0-9_]*\>(/he=e-1
        
        " Builtin function names 
        syntax keyword spthyBuiltinFunction h pk sign verify senc sdec aenc adec mac verify
        
        " Rule arrows and symbols
        syntax match spthyRuleArrow /--\[\|\]->/ 
        
        " Equal sign in let statements
        syntax match spthyOperator /=/ 
        
        " Standard brackets and delimiters
        syntax match spthyBracket /(\|)\|\[\|\]\|{\|}\|,\|;\|:/
        
        " Constants in single quotes
        syntax region spthyConstant start=/'/ end=/'/ 
        
        " =============================================
        " EXPLICIT COLOR LINKING WITH PRIORITIES
        " =============================================
        
        " Comments
        highlight def link spthyComment @comment
        
        " Keywords and structure
        highlight def link spthyKeyword @keyword
        
        " Variables - enforced colors regardless of container
        highlight def link spthyPublicVar @variable.public
        highlight def link spthyPublicVarPrefix @variable.public
        highlight def link spthyFreshVar @variable.fresh
        highlight def link spthyFreshVarPrefix @variable.fresh
        highlight def link spthyTemporalVar @variable.temporal
        highlight def link spthyTemporalVarPrefix @variable.temporal
        
        highlight def link spthyPublicType @variable.public
        highlight def link spthyFreshType @variable.fresh
        highlight def link spthyTemporalType @variable.temporal
        highlight def link spthyMessageType @variable.message
        
        " Facts - must be properly colored
        highlight def link spthyPersistentFact @fact.persistent
        highlight def link spthyBuiltinFact @function.builtin
        highlight def link spthyActionFact @fact.action
        highlight def link spthyNormalFact @fact.linear
        
        " Functions
        highlight def link spthyFunction @function
        highlight def link spthyBuiltinFunction @function.builtin
        
        " Operators and punctuation
        highlight def link spthyRuleArrow @operator
        highlight def link spthyOperator @operator.assignment
        highlight def link spthyBracket @punctuation.bracket
        
        " Constants
        highlight def link spthyConstant @public.constant
        
        " Run a custom event to force highlight update
        doautocmd User TamarinSyntaxApplied
    ]], false)
    
    -- Debug message showing setup completion
    print("Tamarin syntax highlighting setup complete")

    -- Register event to apply highlights ONLY when tamarin/spthy filetypes are loaded
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "spthy" },
        callback = function()
            -- Apply highlights to ensure they're set for this buffer
            for group, colors in pairs(highlights) do
                vim.api.nvim_set_hl(0, group, colors)
            end

            -- Temporarily disable TreeSitter highlighting entirely for this buffer
            if vim.fn.exists(":TSBufDisable") == 1 then
                vim.cmd("TSBufDisable highlight")
            end

            -- Apply pure VimScript syntax highlighting with careful priorities
            vim.api.nvim_exec([[
                " First clear any existing syntax to start fresh
                syntax clear

                " =============================================
                " BASIC SYNTAX ELEMENTS WITH PRIORITY CONTROL
                " =============================================
                
                " Comments - HIGHEST PRIORITY
                syntax match spthyComment /\/\/.*$/ contains=@Spell containedin=ALL
                syntax region spthyComment start="/\*" end="\*/" fold contains=@Spell containedin=ALL
                
                " Theory structure keywords
                syntax keyword spthyKeyword theory begin end
                syntax keyword spthyKeyword rule lemma axiom builtins
                syntax keyword spthyKeyword functions equations predicates
                syntax keyword spthyKeyword restrictions let in
                
                " =============================================
                " VARIABLES - ABSOLUTE HIGHEST PRIORITY
                " =============================================
                
                " Public variables with '$' prefix - HIGHEST PRIORITY
                syntax match spthyPublicVarPrefix /\$/ contained
                syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ contains=spthyPublicVarPrefix containedin=ALL
                
                " Fresh variables with '~' prefix - HIGHEST PRIORITY
                syntax match spthyFreshVarPrefix /\~/ contained
                syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ contains=spthyFreshVarPrefix containedin=ALL
                
                " Temporal variables with '#' prefix - HIGHEST PRIORITY
                syntax match spthyTemporalVarPrefix /#/ contained
                syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/ contains=spthyTemporalVarPrefix containedin=ALL
                
                " Variable types with explicit priority
                syntax match spthyPublicType /[A-Za-z0-9_]\+:pub/ containedin=ALL
                syntax match spthyFreshType /[A-Za-z0-9_]\+:fresh/ containedin=ALL
                syntax match spthyTemporalType /[A-Za-z0-9_]\+:temporal/ containedin=ALL
                syntax match spthyMessageType /[A-Za-z0-9_]\+:msg/ containedin=ALL
                
                " =============================================
                " FACTS - EXPLICITLY COLORED WITH PROPER PRIORITY
                " =============================================
                
                " Persistent fact prefix - specifically colored red
                syntax match spthyPersistentFactPrefix /!/ contained
                highlight link spthyPersistentFactPrefix @fact.persistent
                
                " Persistent facts - RED, with contained variables
                syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ contains=spthyPersistentFactPrefix
                
                " Built-in facts with highest priority after variables
                syntax keyword spthyBuiltinFact Fr In Out K
                
                " Action facts - force LIGHT PINK color
                syntax region spthyActionFact start=/--\[/ end=/\]->/ contains=spthyRuleArrow,spthyFreshVar,spthyPublicVar,spthyTemporalVar,spthyPersistentFact,spthyBuiltinFact,spthyNormalFact
                
                " Regular facts - explicit BLUE color
                syntax match spthyNormalFact /\<[A-Z][A-Za-z0-9_]*\>/ contains=NONE
                
                " =============================================
                " FUNCTIONS, OPERATORS AND PUNCTUATION
                " =============================================
                
                " Function names - TOMATO color
                syntax match spthyFunction /\<[a-z][A-Za-z0-9_]*\>(/he=e-1
                
                " Builtin function names 
                syntax keyword spthyBuiltinFunction h pk sign verify senc sdec aenc adec mac verify
                
                " Rule arrows and symbols
                syntax match spthyRuleArrow /--\[\|\]->/ 
                
                " Equal sign in let statements
                syntax match spthyOperator /=/ 
                
                " Standard brackets and delimiters
                syntax match spthyBracket /(\|)\|\[\|\]\|{\|}\|,\|;\|:/
                
                " Constants in single quotes
                syntax region spthyConstant start=/'/ end=/'/ 
                
                " =============================================
                " EXPLICIT COLOR LINKING WITH PRIORITIES
                " =============================================
                
                " Comments
                highlight def link spthyComment @comment
                
                " Keywords and structure
                highlight def link spthyKeyword @keyword
                
                " Variables - enforced colors regardless of container
                highlight def link spthyPublicVar @variable.public
                highlight def link spthyPublicVarPrefix @variable.public
                highlight def link spthyFreshVar @variable.fresh
                highlight def link spthyFreshVarPrefix @variable.fresh
                highlight def link spthyTemporalVar @variable.temporal
                highlight def link spthyTemporalVarPrefix @variable.temporal
                
                highlight def link spthyPublicType @variable.public
                highlight def link spthyFreshType @variable.fresh
                highlight def link spthyTemporalType @variable.temporal
                highlight def link spthyMessageType @variable.message
                
                " Facts - must be properly colored
                highlight def link spthyPersistentFact @fact.persistent
                highlight def link spthyBuiltinFact @function.builtin
                highlight def link spthyActionFact @fact.action
                highlight def link spthyNormalFact @fact.linear
                
                " Functions
                highlight def link spthyFunction @function
                highlight def link spthyBuiltinFunction @function.builtin
                
                " Operators and punctuation
                highlight def link spthyRuleArrow @operator
                highlight def link spthyOperator @operator.assignment
                highlight def link spthyBracket @punctuation.bracket
                
                " Constants
                highlight def link spthyConstant @public.constant
                
                " Run a custom event to force highlight update
                doautocmd User TamarinSyntaxApplied
            ]], false)

            -- Set a debug message if wanted
            if vim.g.tamarin_highlight_debug then
                vim.api.nvim_echo({ { "Tamarin colors applied with aggressive priority rules", "Normal" } }, false, {})
            end
            
            -- Create an autocmd to reapply these highlights after color scheme changes
            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "*",
                callback = function()
                    if vim.bo.filetype == "spthy" then
                        -- Reapply our highlights
                        for group, colors in pairs(highlights) do
                            vim.api.nvim_set_hl(0, group, colors)
                        end
                        -- Run our custom event
                        vim.cmd("doautocmd User TamarinSyntaxApplied")
                    end
                end
            })
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