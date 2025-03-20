-- Tamarin Syntax Highlighting Colors
-- Colors to apply to TreeSitter captures defined in highlights.scm

local M = {}

-- Function to set up highlighting
function M.setup()
    -- Load color definitions from the separate colorscheme file
    local colorscheme = require('config.spthy-colorscheme')
    local highlights = colorscheme.get_highlights()

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