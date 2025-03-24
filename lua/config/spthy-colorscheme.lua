-- spthy-colorscheme.lua
-- Color definitions for Tamarin Protocol Theory syntax highlighting

local M = {}

-- Color and style definitions (alphabetically ordered)
M.colors = {
  -- Base colors (alphabetical by name)
  blueBold                   = { fg = "#1E90FF", bold = true },                                     -- Dodger Blue - vibrant blue for linear facts
  blueBoldUnderlined         = { fg = "#1E90FF", bold = true, underline = true },                   -- Same blue with underline for builtin facts
  brightBlueBold             = { fg = "#006bff", bold = true },                                     -- Dodger Blue - vibrant blue for linear facts
  brightBlue                 = { fg = "#006bff", bold = false },                                    -- Dodger Blue - vibrant blue for linear facts
  brightBlueUnderlined       = { fg = "#006bff", bold = false, underline = true },                  -- Same blue with underline for builtin facts
  brownPlain                 = { fg = "#8B4513", bold = false },                                    -- SaddleBrown - for number variables
  deepBlueGreen              = { fg = "#006B5B" },                                                  -- Deep teal/blue-green for public variables
  deeperPurple               = { fg = "#8877BB", bold = false },                                    -- Muted purple for preprocessor identifiers
  deepGreen                  = { fg = "#006400", bold = false },                                    -- Deep green for public variables, rich and forest-like
  mediumGreen                = { fg = "#04a12b", bold = false },                                    -- Medium green for public variables, rich and forest-like
  green                      = { fg = "#00cc33", bold = false },                                    -- Bright green for public variables, rich and forest-like
  goldBold                   = { fg = "#FFD700", bold = true },                                     -- Gold - for rule/theory names with bold
  goldBoldUnderlined         = { fg = "#FFD700", bold = true, underline = true },                   -- Gold with underline for builtins
  goldItalic                 = { fg = "#FFD700", bold = false, italic = true },                     -- Gold with italic for theory names
  goldItalicUnderdotted      = { fg = "#FFD700", bold = false, italic = true, underdotted = true }, -- Gold with italic for theory names
  lightGold                  = { fg = "#FFE766", bold = false },                                    -- Gold - for rule/theory names with bold
  lightGoldBold              = { fg = "#FFE766", bold = true },                                     -- Gold - for rule/theory names with bold
  lightGoldBoldUnderlined    = { fg = "#FFE766", bold = true, underline = true },                   -- Gold with underline for builtins
  lightGoldBoldUnderdotted   = { fg = "#FFE766", bold = true, underdotted = true },                 -- Gold with underline for builtins
  lightGoldItalicUnderdotted = { fg = "#FFE766", bold = false, italic = true, underdotted = true }, -- Gold with underline for builtins
  lightGoldItalic            = { fg = "#FFE766", bold = false, italic = true },                     -- Gold with italic for theory names
  grayItalic                 = { fg = "#777777", italic = true },                                   -- Gray - for comments
  grayPlain                  = { fg = "#888888", bold = false },                                    -- Gray - for logical operators
  hotPinkBold                = { fg = "#FF1493", bold = true },                                     -- Deep Pink - for public constants
  hotPinkPlain               = { fg = "#FF69B4", bold = false },                                    -- Hot Pink - for fresh variables (~k)
  lightPinkPlain             = { fg = "#FFB6C1", bold = false },                                    -- Light Pink - for action facts
  lilacBold                  = { fg = "#D7A0FF", bold = true },                                     -- Lilac - for keyword quantifiers
  magentaBold                = { fg = "#FF00FF", bold = true },                                     -- Magenta - for keywords
  mediumMagentaBold          = { fg = "#FF5FFF", bold = true },                                     -- Medium Magenta - for module keywords
  mediumPurple               = { fg = "#9370DB", italic = false },                                  -- Medium Purple - for rule structure
  mutedPurple                = { fg = "#9966CC", bold = false },                                    -- Muted Purple - for preprocessor
  orangeNoStyle              = { fg = "#FF8C00" },                                                  -- Dark Orange - for regular variables
  orangePlain                = { fg = "#FF8C00", bold = false },                                    -- Dark Orange - for message variables
  orangeBold                 = { fg = "#FF8C00", bold = true },                                     -- Dark Orange - for message variables
  orangeItalic               = { fg = "#FF8C00", bold = false, italic = true },                     -- Dark Orange - for message variables
  orangeBoldUnderlined       = { fg = "#FF8C00", bold = true, underline = true },                   -- Dark Orange - for message variables
  orangeItalicUnderlined     = { fg = "#FF8C00", italic = true, underline = true },                 -- Dark Orange - for message variables
  orchidItalic               = { fg = "#DA70D6", italic = true },                                   -- Orchid - for string constants
  orchidPlain                = { fg = "#DA70D6" },                                                  -- Orchid - for constants
  pinkPlain                  = { fg = "#FFC0CB", italic = false },                                  -- Pink - for type qualifiers
  purplePlain                = { fg = "#AA88FF" },                                                  -- Purple - for exponentiation
  red                        = { fg = "#FF3030", bold = false, italic = false },                    -- Pure Red - with bold and italic
  redBold                    = { fg = "#FF3030", bold = true },                                     -- Firebrick Red - for persistent facts (!Ltk)
  redBoldItalic              = { fg = "#FF3030", bold = true, italic = true },                      -- Pure Red - with bold and italic
  redItalic                  = { fg = "#FF3030", bold = false, italic = true },                     -- Pure Red - with bold and italic
  redBoldUnderlined          = { fg = "#FF3030", bold = true, underline = true },                   -- Red with underline - for errors
  redItalicUnderlined        = { fg = "#FF3030", bold = false, italic = true, underline = true },   -- Pure Red - with bold and italic
  royalBlue                  = { fg = "#4169E1", italic = false },                                  -- Royal Blue - for rule conclusions
  royalBlueUnderlined        = { fg = "#4169E1", italic = false, underline = true },                -- Royal Blue - for rule conclusions
  royalBlueItalicUnderlined  = { fg = "#4169E1", italic = true, underline = true },                 -- Royal Blue - for rule conclusions
  skyBluePlain               = { fg = "#00BFFF", bold = false },                                    -- Deep Sky Blue - for temporal variables (#i)
  slateBlue                  = { fg = "#6A5ACD", italic = false },                                  -- Slate Blue - for rule premises
  slateGrayBold              = { fg = "#708090", bold = true },                                     -- Slate Gray - for operators with bold
  slateGrayPlain             = { fg = "#708090" },                                                  -- Slate Gray - for punctuation
  tomatoPlain                = { fg = "#FF6347", bold = false },                                    -- Tomato - for functions with italic
  tomatoItalic               = { fg = "#FF6347", italic = true, bold = false },                     -- Tomato - for functions with italic
  tomatoItalicUnderlined     = { fg = "#FF6347", italic = true, bold = false, underline = true }    -- Tomato - for functions with italic
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

