-- color-wizard.lua
-- A dynamic color generation tool that converts hex codes to named styles
-- and automatically updates the color scheme file

local M = {}

-- Color name mapping (limited sample)
local color_names = {
    -- Reds
    ["#FF0000"] = "red",
    ["#FF4040"] = "tomato",
    ["#FF1493"] = "deepPink",
    ["#FF69B4"] = "hotPink",
    ["#FFB6C1"] = "lightPink",
    
    -- Oranges/Browns
    ["#FFA500"] = "orange",
    ["#8B4513"] = "brown",
    
    -- Yellows/Golds
    ["#FFD700"] = "gold",
    ["#FFFF00"] = "yellow",
    
    -- Greens
    ["#32CD32"] = "limeGreen",
    ["#00FF00"] = "green",
    
    -- Blues
    ["#00AAFF"] = "azure",
    ["#87CEEB"] = "skyBlue",
    ["#4169E1"] = "royalBlue",
    ["#0000FF"] = "blue",
    
    -- Purples
    ["#FF00FF"] = "magenta",
    ["#D7A0FF"] = "lilac",
    ["#FF5FFF"] = "mediumMagenta",
    ["#9966CC"] = "mutedPurple",
    ["#8877BB"] = "deeperPurple",
    ["#AA88FF"] = "lavender",
    ["#9370DB"] = "mediumPurple",
    ["#6A5ACD"] = "slateBlue",
    
    -- Grays
    ["#777777"] = "gray",
    ["#888888"] = "mediumGray",
    ["#8899AA"] = "slateGray",
    
    -- Other
    ["#DA70D6"] = "orchid",
    ["#FFC0CB"] = "pink",
}

-- Style names
local style_names = {
    ["bold"] = "Bold",
    ["italic"] = "Italic",
    ["underline"] = "Underlined",
    ["undercurl"] = "Undercurled",
    ["strikethrough"] = "Strikethrough"
}

-- Function to find the nearest color name for a hex value
local function get_color_name(hex)
    -- Normalize hex code format
    hex = hex:upper()
    if hex:sub(1, 1) ~= "#" then
        hex = "#" .. hex
    end
    
    -- Direct match?
    if color_names[hex] then
        return color_names[hex]
    end
    
    -- Could implement color distance calculation here for approximate matches
    -- (e.g., using RGB distance or LAB color space)
    
    -- For now, just return the hex if no match
    return hex
end

-- Generate a style name from a hex color and style attributes
local function generate_style_name(hex, styles)
    local color_name = get_color_name(hex)
    
    -- Sort style keys for consistent ordering
    local style_keys = {}
    for k in pairs(styles) do
        table.insert(style_keys, k)
    end
    table.sort(style_keys)
    
    -- Build the style suffix
    local style_suffix = ""
    for _, style in ipairs(style_keys) do
        if styles[style] and style_names[style] then
            style_suffix = style_suffix .. style_names[style]
        end
    end
    
    -- Combine color name and style
    return color_name .. style_suffix
end

-- Parse existing colors file
local function parse_colors_file(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    local colors = {}
    for name, hex, styles in content:gmatch("local%s+([%w_]+)%s*=%s*{%s*fg%s*=%s*\"(#[%x]+)\"%s*,%s*(.-)%s*}") do
        local style_table = {}
        for style, value in styles:gmatch("([%w_]+)%s*=%s*([%w]+)") do
            if value == "true" then
                style_table[style] = true
            end
        end
        colors[name] = { hex = hex, styles = style_table }
    end
    
    return colors
end

-- Generate style definition code
local function generate_style_code(style_name, hex, styles)
    local parts = { string.format("local %-28s = { fg = %q", style_name, hex) }
    
    local style_items = {}
    if styles.bold then table.insert(style_items, "bold = true") end
    if styles.italic then table.insert(style_items, "italic = true") end
    if styles.underline then table.insert(style_items, "underline = true") end
    if styles.undercurl then table.insert(style_items, "undercurl = true") end
    if styles.strikethrough then table.insert(style_items, "strikethrough = true") end
    
    if #style_items > 0 then
        parts[1] = parts[1] .. ", " .. table.concat(style_items, ", ")
    end
    
    parts[1] = parts[1] .. " }"
    return parts[1]
end

-- Add a new color to the colorscheme
function M.add_style(hex, styles)
    -- Calculate style name
    local style_name = generate_style_name(hex, styles)
    
    -- Generate code for the style
    local style_code = generate_style_code(style_name, hex, styles)
    
    -- Target file (colorscheme)
    local file_path = vim.fn.stdpath("config") .. "/lua/config/spthy-colorscheme.lua"
    
    -- Parse existing file
    local existing_colors = parse_colors_file(file_path)
    
    -- Check if this style already exists
    if existing_colors[style_name] then
        vim.notify("Style '" .. style_name .. "' already exists!", vim.log.levels.WARN)
        return style_name
    end
    
    -- Read the file content
    local file = io.open(file_path, "r")
    if not file then
        vim.notify("Could not open colorscheme file: " .. file_path, vim.log.levels.ERROR)
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Find the insertion point (after the colors table declaration)
    local colors_section_start = content:find("M%.colors%s*=%s*{")
    if not colors_section_start then
        vim.notify("Could not find colors table in colorscheme file", vim.log.levels.ERROR)
        return nil
    end
    
    -- Find the next line after the first color definition
    local insertion_point = content:find("\n%s*%-%-%s*Base%s*colors", colors_section_start)
    if not insertion_point then
        -- Fallback: Find the first color definition
        insertion_point = content:find("\n%s*[%w_]+%s*=%s*{%s*fg%s*=", colors_section_start)
    end
    
    if not insertion_point then
        vim.notify("Could not find insertion point in colorscheme file", vim.log.levels.ERROR)
        return nil
    end
    
    -- Insert the new style
    local before = content:sub(1, insertion_point)
    local after = content:sub(insertion_point + 1)
    
    -- Write the updated content
    local file = io.open(file_path, "w")
    if not file then
        vim.notify("Could not write to colorscheme file: " .. file_path, vim.log.levels.ERROR)
        return nil
    end
    
    file:write(before .. "\n    " .. style_code .. after)
    file:close()
    
    vim.notify("Added new style: " .. style_name, vim.log.levels.INFO)
    return style_name
end

-- The main entry point - select a color and create a style
function M.pick_color()
    -- Check if a color picker plugin is available
    local has_color_picker, color_picker = pcall(require, "color-picker")
    
    if has_color_picker then
        -- Use the color picker plugin
        color_picker.pick(function(hex)
            if not hex then return end
            
            -- Ask for styles
            vim.ui.select(
                { "None", "Bold", "Italic", "Bold+Italic", "Underlined", "Bold+Underlined" },
                { prompt = "Select style:" },
                function(choice)
                    if not choice then return end
                    
                    local styles = {}
                    if choice:find("Bold") then styles.bold = true end
                    if choice:find("Italic") then styles.italic = true end
                    if choice:find("Underlined") then styles.underline = true end
                    
                    local style_name = M.add_style(hex, styles)
                    if style_name then
                        -- Insert the style name at cursor
                        local pos = vim.api.nvim_win_get_cursor(0)
                        vim.api.nvim_buf_set_text(0, pos[1]-1, pos[2], pos[1]-1, pos[2], { style_name })
                    end
                end
            )
        end)
    else
        -- Fallback to manual input
        vim.ui.input({ prompt = "Enter color hex code (e.g. #FF0000): " }, function(hex)
            if not hex or hex == "" then return end
            
            vim.ui.select(
                { "None", "Bold", "Italic", "Bold+Italic", "Underlined", "Bold+Underlined" },
                { prompt = "Select style:" },
                function(choice)
                    if not choice then return end
                    
                    local styles = {}
                    if choice:find("Bold") then styles.bold = true end
                    if choice:find("Italic") then styles.italic = true end
                    if choice:find("Underlined") then styles.underline = true end
                    
                    local style_name = M.add_style(hex, styles)
                    if style_name then
                        -- Insert the style name at cursor
                        local pos = vim.api.nvim_win_get_cursor(0)
                        vim.api.nvim_buf_set_text(0, pos[1]-1, pos[2], pos[1]-1, pos[2], { style_name })
                    end
                end
            )
        end)
    end
end

-- Setup keymaps
function M.setup()
    -- Create a user command
    vim.api.nvim_create_user_command("ColorWizard", function()
        M.pick_color()
    end, {})
    
    -- Add a keymap (optional)
    vim.keymap.set("n", "<leader>cw", function() M.pick_color() end, 
                 { desc = "Open Color Wizard to pick a color style" })
    
    vim.notify("Color Wizard initialized! Use :ColorWizard or <leader>cw to pick colors.", vim.log.levels.INFO)
end

return M 