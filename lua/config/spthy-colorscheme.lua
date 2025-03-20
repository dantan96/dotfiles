-- spthy-colorscheme.lua
-- Color definitions for Tamarin Protocol Theory syntax highlighting

local M = {}

-- Color and style definitions (alphabetically ordered)
M.colors = {
    -- Base colors (alphabetical by name)
    blueBold                = { fg = "#00AAFF", bold = true },
    blueBoldUnderlined      = { fg = "#00AAFF", bold = true, underline = true },
    brownNoStyle            = { fg = "#8B4513" },
    brownPlain              = { fg = "#8B4513", bold = false },
    deeperPurple            = { fg = "#8877BB", bold = false },
    goldBold                = { fg = "#FFD700", bold = true },
    goldBoldUnderlined      = { fg = "#FFD700", bold = true, underline = true },
    goldItalic              = { fg = "#FFD700", bold = false, italic = true },
    grayItalic              = { fg = "#777777", italic = true },
    grayPlain               = { fg = "#888888", bold = false },
    greenNoStyle            = { fg = "#32CD32" },
    greenPlain              = { fg = "#32CD32", bold = false },
    hotPinkBold             = { fg = "#FF1493", bold = true },
    hotPinkPlain            = { fg = "#FF69B4", bold = false },
    lightPinkPlain          = { fg = "#FFB6C1", bold = false },
    lilacBold               = { fg = "#D7A0FF", bold = true },
    magentaBold             = { fg = "#FF00FF", bold = true },
    mediumMagentaBold       = { fg = "#FF5FFF", bold = true },
    mediumPurple            = { fg = "#9370DB", italic = false },
    mutedPurple             = { fg = "#9966CC", bold = false },
    orangeNoStyle           = { fg = "#FFA500" },
    orangePlain             = { fg = "#FFA500", bold = false },
    orchidItalic            = { fg = "#DA70D6", italic = true },
    orchidPlain             = { fg = "#DA70D6" },
    pinkPlain               = { fg = "#FFC0CB", italic = false },
    purplePlain             = { fg = "#AA88FF" },
    redBold                 = { fg = "#FF4040", bold = true },
    redBoldUnderlined       = { fg = "#FF0000", bold = true, underline = true },
    royalBlue               = { fg = "#4169E1", italic = false },
    skyBluePlain            = { fg = "#87CEEB", bold = false },
    slateBlue               = { fg = "#6A5ACD", italic = false },
    slateGrayBold           = { fg = "#8899AA", bold = true },
    slateGrayPlain          = { fg = "#8899AA" },
    tomatoItalic            = { fg = "#FF6347", italic = true, bold = false },
}

-- Optional: provide a function to create a new color style
-- This makes it easier to combine colors with styles
function M.create_style(hex_color, styles)
    styles = styles or {}
    local style = { fg = hex_color }
    
    -- Apply optional styles
    if styles.bold then style.bold = true end
    if styles.italic then style.italic = true end
    if styles.underline then style.underline = true end
    if styles.undercurl then style.undercurl = true end
    if styles.strikethrough then style.strikethrough = true end
    
    return style
end

-- Function to get all styles for highlighting
function M.get_highlights()
    local c = M.colors
    
    return {
        ---------------------------------------------------
        -- KEYWORDS AND STRUCTURE
        ---------------------------------------------------
        ["@keyword"]                  = c.magentaBold,               -- Keywords: theory, begin, end, rule, lemma, builtins, restriction, functions, equations
        ["@keyword.quantifier"]       = c.lilacBold,                 -- Quantifiers: All, Ex, ∀, ∃
        ["@keyword.module"]           = c.mediumMagentaBold,         -- Module keywords: builtins, functions, predicates, options
        ["@keyword.function"]         = c.magentaBold,               -- Function keywords: rule, lemma, axiom, restriction
        ["@keyword.tactic"]           = c.magentaBold,               -- Tactic keywords: tactic, presort, prio, deprio
        ["@keyword.tactic.value"]     = c.lilacBold,                 -- Tactic values: direct, sorry, simplify, solve, contradiction
        ["@keyword.macro"]            = c.magentaBold,               -- Macro keywords: macros, let, in
        ["@preproc"]                  = c.mutedPurple,               -- Preprocessor: #ifdef, #endif, #define, #include
        ["@preproc.identifier"]       = c.deeperPurple,              -- Preprocessor identifiers: PREPROCESSING, DEBUG, etc.
        
        ["@structure"]                = c.goldBold,                  -- Structure elements: protocol, for, accounts
        ["@type"]                     = c.goldItalic,                -- Theory/type names: name in 'theory <name>'
        ["@function.rule"]            = c.goldBold,                  -- Rule/lemma names: name in 'rule <name>:', 'lemma <name>:'
        ["@type.builtin"]             = c.goldBoldUnderlined,        -- Builtins: diffie-hellman, hashing, symmetric-encryption, signing, etc.
        ["@type.qualifier"]           = c.pinkPlain,                 -- Type qualifiers: private, public, fresh

        ---------------------------------------------------
        -- VARIABLES
        ---------------------------------------------------
        ["@variable"]                 = c.orangeNoStyle,             -- General variables: any identifier without special prefix
        ["@variable.public"]          = c.greenPlain,                -- Public variables: $A, A:pub
        ["@variable.fresh"]           = c.hotPinkPlain,              -- Fresh variables: ~k, ~id, ~ltk
        ["@variable.temporal"]        = c.skyBluePlain,              -- Temporal variables: #i, #j
        ["@variable.message"]         = c.orangePlain,               -- Message variables: no prefix or :msg
        ["@variable.number"]          = c.brownPlain,                -- Number variables/arities: 2 in f/2

        ---------------------------------------------------
        -- FACTS
        ---------------------------------------------------
        ["@fact.persistent"]          = c.redBold,                   -- Persistent facts: !Ltk, !Pk, !User
        ["@fact.linear"]              = c.blueBold,                  -- Linear facts: standard facts without ! prefix
        ["@function.builtin"]         = c.blueBoldUnderlined,        -- Built-in facts: Fr, In, Out, K
        ["@fact.action"]              = c.lightPinkPlain,            -- Action facts: inside --[ and ]->

        ---------------------------------------------------
        -- FUNCTIONS AND MACROS
        ---------------------------------------------------
        ["@function"]                 = c.tomatoItalic,              -- Regular functions: f(), pk(), h()
        ["@function.macro"]           = c.tomatoItalic,              -- Macro names: names defined in macro declarations
        ["@function.macro.call"]      = c.tomatoItalic,              -- Macro use in code: using a defined macro
        
        ---------------------------------------------------
        -- BRACKETS, PUNCTUATION, OPERATORS
        ---------------------------------------------------
        ["@operator"]                 = c.slateGrayBold,             -- Action brackets: --[ and ]->
        ["@punctuation.bracket"]      = c.slateGrayPlain,            -- Regular brackets: (), [], <>
        ["@punctuation.delimiter"]    = c.slateGrayPlain,            -- Punctuation: ,.;:
        ["@punctuation.special"]      = c.slateGrayBold,             -- Special punctuation: -->, ==>
        ["@operator.exponentiation"]  = c.purplePlain,               -- Exponentiation: ^
        ["@operator.logical"]         = c.grayPlain,                 -- Logical operators: &, |, not, =>

        ---------------------------------------------------
        -- NUMBERS, CONSTANTS, STRINGS
        ---------------------------------------------------
        ["@number"]                   = c.brownNoStyle,              -- Numbers: 1, 2, 3
        ["@constant"]                 = c.orchidPlain,               -- General constants: constants without decoration
        ["@constant.string"]          = c.orchidItalic,              -- String constants: quoted strings
        ["@public.constant"]          = c.hotPinkBold,               -- Public constants: 'g', 'pk', etc. (in single quotes)
        ["@string"]                   = c.greenNoStyle,              -- Strings: quoted text

        ---------------------------------------------------
        -- COMMENTS
        ---------------------------------------------------
        ["@comment"]                  = c.grayItalic,                -- Comments: // line comments and /* block comments */
        
        ---------------------------------------------------
        -- RULE STRUCTURE SPECIFIC
        ---------------------------------------------------
        ["@premise"]                  = c.slateBlue,                 -- Rule premises: left side of rule (before --[)
        ["@conclusion"]               = c.royalBlue,                 -- Rule conclusions: right side of rule (after ]->)
        ["@rule.simple"]              = c.mediumPurple,              -- Simple rules: entire rule structure
        
        ---------------------------------------------------
        -- ERROR HANDLING
        ---------------------------------------------------
        ["@error"]                    = c.redBoldUnderlined          -- Error nodes: for invalid syntax or parsing errors
    }
end

return M 