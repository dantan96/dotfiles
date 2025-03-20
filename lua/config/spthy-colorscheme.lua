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
    redBoldItalic           = { fg = "#FF0000", bold = true, italic = true },
    redBoldUnderlined       = { fg = "#FF0000", bold = true, underline = true },
    royalBlue               = { fg = "#4169E1", italic = false },
    skyBluePlain            = { fg = "#87CEEB", bold = false },
    slateBlue               = { fg = "#6A5ACD", italic = false },
    slateGrayBold           = { fg = "#8899AA", bold = true },
    slateGrayPlain          = { fg = "#8899AA" },
    tomatoItalic            = { fg = "#FF6347", italic = true, bold = false }
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