-- spthy-colorscheme.lua
-- Color definitions for Tamarin Protocol Theory syntax highlighting

local M = {}

-- Color and style definitions (alphabetically ordered)
M.colors = {
    -- Base colors (alphabetical by name)
    blueBold                = { fg = "#1E90FF", bold = true },            -- Dodger Blue - vibrant blue for linear facts
    blueBoldUnderlined      = { fg = "#1E90FF", bold = true, underline = true }, -- Same blue with underline for builtin facts
    brownNoStyle            = { fg = "#8B4513" },                         -- SaddleBrown - for numbers
    brownPlain              = { fg = "#8B4513", bold = false },           -- SaddleBrown - for number variables
    deepBlueGreen           = { fg = "#006B5B" },                         -- Deep teal/blue-green for public variables
    deeperPurple            = { fg = "#8877BB", bold = false },           -- Muted purple for preprocessor identifiers
    deepGreen               = { fg = "#006400", bold = false },           -- Deep green for public variables, rich and forest-like
    goldBold                = { fg = "#FFD700", bold = true },            -- Gold - for rule/theory names with bold
    goldBoldUnderlined      = { fg = "#FFD700", bold = true, underline = true }, -- Gold with underline for builtins
    goldItalic              = { fg = "#FFD700", bold = false, italic = true }, -- Gold with italic for theory names
    grayItalic              = { fg = "#777777", italic = true },          -- Gray - for comments
    grayPlain               = { fg = "#888888", bold = false },           -- Gray - for logical operators
    hotPinkBold             = { fg = "#FF1493", bold = true },            -- Deep Pink - for public constants
    hotPinkPlain            = { fg = "#FF69B4", bold = false },           -- Hot Pink - for fresh variables (~k)
    lightPinkPlain          = { fg = "#FFB6C1", bold = false },           -- Light Pink - for action facts
    lilacBold               = { fg = "#D7A0FF", bold = true },            -- Lilac - for keyword quantifiers
    magentaBold             = { fg = "#FF00FF", bold = true },            -- Magenta - for keywords
    mediumMagentaBold       = { fg = "#FF5FFF", bold = true },            -- Medium Magenta - for module keywords
    mediumPurple            = { fg = "#9370DB", italic = false },         -- Medium Purple - for rule structure
    mutedPurple             = { fg = "#9966CC", bold = false },           -- Muted Purple - for preprocessor
    orangeNoStyle           = { fg = "#FF8C00" },                         -- Dark Orange - for regular variables
    orangePlain             = { fg = "#FF8C00", bold = false },           -- Dark Orange - for message variables
    orchidItalic            = { fg = "#DA70D6", italic = true },          -- Orchid - for string constants
    orchidPlain             = { fg = "#DA70D6" },                         -- Orchid - for constants
    pinkPlain               = { fg = "#FFC0CB", italic = false },         -- Pink - for type qualifiers
    purplePlain             = { fg = "#AA88FF" },                         -- Purple - for exponentiation
    redBold                 = { fg = "#FF3030", bold = true },            -- Firebrick Red - for persistent facts (!Ltk)
    redBoldItalic           = { fg = "#FF0000", bold = true, italic = true }, -- Pure Red - with bold and italic
    redBoldUnderlined       = { fg = "#FF0000", bold = true, underline = true }, -- Red with underline - for errors
    royalBlue               = { fg = "#4169E1", italic = false },         -- Royal Blue - for rule conclusions
    skyBluePlain            = { fg = "#00BFFF", bold = false },           -- Deep Sky Blue - for temporal variables (#i)
    slateBlue               = { fg = "#6A5ACD", italic = false },         -- Slate Blue - for rule premises
    slateGrayBold           = { fg = "#708090", bold = true },            -- Slate Gray - for operators with bold
    slateGrayPlain          = { fg = "#708090" },                         -- Slate Gray - for punctuation
    tomatoItalic            = { fg = "#FF6347", italic = true, bold = false } -- Tomato - for functions with italic
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

return M 