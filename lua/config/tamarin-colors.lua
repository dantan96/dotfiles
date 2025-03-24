-- Tamarin Syntax Highlighting Colors
-- Colors to apply to TreeSitter captures defined in highlights.scm

local M = {}

-- Function to set up highlighting
function M.setup()
  -- Debug message to confirm the function is running
  print("Setting up Tamarin syntax highlighting...")

  -- Load color definitions from colorscheme file
  local colors = require('config.spthy-colorscheme').colors

  -- -- Define highlighting groups specific to Tamarin/spthy
  local highlights = {
    --   ---------------------------------------------------
    --   -- KEYWORDS AND STRUCTURE
    --   ---------------------------------------------------
    --   ["@keyword"]                  = colors.magentaBold,        -- Keywords: theory, begin, end, rule, lemma, builtins, restriction, functions, equations
    --   ["@keyword.trace_quantifier"] = colors.mediumMagentaBold,  -- Quantifiers: All, Ex, ∀, ∃
    --   ["@keyword.quantifier"]       = colors.lilacBold,          -- Quantifiers: "exists-trace", "all-traces"
    --   ["@keyword.module"]           = colors.magentaBold,        -- Module keywords: builtins, functions, predicates, options
    --   ["@keyword.function"]         = colors.magentaBold,        -- Function keywords: rule, lemma, axiom, restriction
    --   ["@keyword.tactic"]           = colors.magentaBold,        -- Tactic keywords: tactic, presort, prio, deprio
    --   ["@keyword.tactic.value"]     = colors.lilacBold,          -- Tactic values: direct, sorry, simplify, solve, contradiction
    --   ["@keyword.macro"]            = colors.magentaBold,        -- Macro keywords: macros, let, in
    --   ["@preproc"]                  = colors.mutedPurple,        -- Preprocessor: #ifdef, #endif, #define, #include
    --   ["@preproc.identifier"]       = colors.deeperPurple,       -- Preprocessor identifiers: PREPROCESSING, DEBUG, etc.
    --
    --
    ["@keyword"]                  = colors.mutedPurple,  -- Keywords: theory, begin, end, rule, lemma, builtins, restriction, functions, equations
    ["@keyword.trace_quantifier"] = colors.mutedPurple,  -- Quantifiers: All, Ex, ∀, ∃
    ["@keyword.quantifier"]       = colors.mutedPurple,  -- Quantifiers: "exists-trace", "all-traces"
    ["@keyword.module"]           = colors.mutedPurple,  -- Module keywords: builtins, functions, predicates, options
    ["@keyword.function"]         = colors.mutedPurple,  -- Function keywords: rule, lemma, axiom, restriction
    ["@keyword.tactic"]           = colors.mutedPurple,  -- Tactic keywords: tactic, presort, prio, deprio
    ["@keyword.tactic.value"]     = colors.lilacBold,    -- Tactic values: direct, sorry, simplify, solve, contradiction
    ["@keyword.macro"]            = colors.mutedPurple,  -- Macro keywords: macros, let, in
    ["@preproc"]                  = colors.mutedPurple,  -- Preprocessor: #ifdef, #endif, #define, #include
    ["@preproc.identifier"]       = colors.deeperPurple, -- Preprocessor identifiers: PREPROCESSING, DEBUG, etc.

    -- ["@structure"]                = colors.goldBold,           -- Structure elements: protocol, for, accounts
    -- ["@type"]                     = colors.goldBold,           -- Theory/type names: name in 'theory <n>'
    -- ["@function.rule"]            = colors.goldBold,           -- Rule/lemma names: name in 'rule <n>:', 'lemma <n>:'
    -- ["@type.builtin"]             = colors.goldBoldUnderlined, -- Builtins: diffie-hellman, hashing, symmetric-encryption, signing, etc.
    -- ["@type.qualifier"]           = colors.pinkPlain,          -- Type qualifiers: private, public, fresh
    --
    --

    ["@structure"]                = colors.orangeBold,           -- Structure elements: protocol, for, accounts
    ["@type"]                     = colors.orangeBold,           -- Theory/type names: name in 'theory <n>'
    ["@function.rule"]            = colors.orangeBold,           -- Rule/lemma names: name in 'rule <n>:', 'lemma <n>:'
    ["@type.builtin"]             = colors.orangeBoldUnderlined, -- Builtins: diffie-hellman, hashing, symmetric-encryption, signing, etc.
    ["@type.qualifier"]           = colors.pinkPlain,            -- Type qualifiers: private, public, fresh

    ---------------------------------------------------
    -- VARIABLES - WITH DISTINCT CONTRASTING COLORS
    ---------------------------------------------------
    ["@variable"]                 = colors.tomatoPlain,  -- Regular variables: general identifiers without special prefix
    ["@variable.public"]          = colors.mediumGreen,  -- Public variables: $A, A:pub - deep forest green as requested
    ["@variable.fresh"]           = colors.hotPinkPlain, -- Fresh variables: ~k, ~id, ~ltk - distinctive hot pink
    ["@variable.temporal"]        = colors.skyBluePlain, -- Temporal variables: #i, #j - vibrant sky blue
    ["@variable.message"]         = colors.tomatoPlain,  -- Message variables: no prefix or :msg - orange shade
    ["@variable.number"]          = colors.brownPlain,   -- Number variables/arities: 2 in f/2 - earthy brown

    ---------------------------------------------------
    -- FACTS - WITH DISTINCT CONTRASTING COLORS
    ---------------------------------------------------
    ["@fact.persistent"]          = colors.red,                  -- Persistent facts: !Ltk, !Pk, !User - bold red as requested
    ["@fact.linear"]              = colors.brightBlue,           -- Linear facts: standard facts without ! prefix - bold blue
    ["@fact.builtin"]             = colors.brightBlueUnderlined, -- Built-in facts: Fr, In, Out, K - same color as linear but underlined
    ["@fact.action"]              = colors.lightPinkPlain,       -- Action facts: inside --[ and ]-> - light pink for contrast

    ---------------------------------------------------
    -- FUNCTIONS AND MACROS
    ---------------------------------------------------
    ["@function"]                 = colors.goldItalic,            -- Regular functions: f(), pk(), h() - tomato with italic
    ["@function.arity"]           = colors.tomatoItalic,          -- Regular functions: f(), pk(), h() - tomato with italic
    ["@function.builtin"]         = colors.goldItalicUnderdotted, -- Regular functions: f(), pk(), h() - tomato with italic
    ["@function.macro"]           = colors.tomatoItalic,          -- Macro names: names defined in macro declarations
    ["@function.macro.call"]      = colors.tomatoItalic,          -- Macro use in code: using a defined macro

    ---------------------------------------------------
    -- BRACKETS, PUNCTUATION, OPERATORS
    ---------------------------------------------------
    ["@operator"]                 = colors.slateGrayBold,  -- Action brackets: --[ and ]->
    ["@operator.assignment"]      = colors.slateGrayPlain, -- Assignment operators: = in let statements
    ["@punctuation.bracket"]      = colors.slateGrayPlain, -- Regular brackets: (), [], <>
    ["@punctuation.delimiter"]    = colors.slateGrayPlain, -- Punctuation: ,.;:
    ["@punctuation.special"]      = colors.slateGrayBold,  -- Special punctuation: -->, ==>
    ["@operator.exponentiation"]  = colors.purplePlain,    -- Exponentiation: ^
    ["@operator.logical"]         = colors.grayPlain,      -- Logical operators: &, |, not, =>
    ["@operator.at"]              = colors.grayPlain,      -- At operator: @

    ---------------------------------------------------
    -- NUMBERS, CONSTANTS, STRINGS
    ---------------------------------------------------
    ["@number"]                   = colors.brownNoStyle, -- Numbers: 1, 2, 3
    ["@constant"]                 = colors.orchidPlain,  -- General constants: constants without decoration
    ["@constant.string"]          = colors.orchidItalic, -- String constants: quoted strings
    ["@public.constant"]          = colors.hotPinkBold,  -- Public constants: 'g', 'pk', etc. (in single quotes)
    ["@string"]                   = colors.deepGreen,    -- Strings: quoted text

    ---------------------------------------------------
    -- COMMENTS
    ---------------------------------------------------
    ["@comment"]                  = colors.grayItalic, -- Comments: // line comments and /* block comments */

    ---------------------------------------------------
    -- RULE STRUCTURE SPECIFIC
    ---------------------------------------------------
    ["@premise"]                  = colors.slateBlue,    -- Rule premises: left side of rule (before --[)
    ["@conclusion"]               = colors.royalBlue,    -- Rule conclusions: right side of rule (after ]->)
    ["@rule.simple"]              = colors.mediumPurple, -- Simple rules: entire rule structure

    ---------------------------------------------------
    -- ERROR HANDLING
    ---------------------------------------------------
    ["@error"]                    = colors
        .redBoldUnderlined -- Error nodes: for invalid syntax or parsing errors
  }

  -- Apply all highlights immediately to the current buffer
  for group, color in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, color)
  end
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
