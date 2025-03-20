# Color Wizard for Neovim

A dynamic color style generator that revolutionizes how you define and manage syntax highlighting in Neovim.

## Overview

Color Wizard is a Neovim plugin that allows you to:

1. Select colors visually using a color picker or enter hex codes
2. Apply styling options (bold, italic, underline, etc.)
3. Automatically generate descriptive style names
4. Dynamically update your colorscheme file with new styles
5. Insert the style name at your cursor position

## How It Works

Color Wizard implements your brilliant idea of dynamically generating and managing color styles:

1. **Select a Color**: Use `:ColorWizard` command or `<leader>cw` mapping to open the color selection
2. **Choose Styling**: After picking a color, select styling options (bold, italic, etc.)
3. **Magic Happens**: Color Wizard will:
   - Identify the color name from its hex code
   - Generate a descriptive style name (e.g., `deepPinkBoldItalic`)
   - Update the colorscheme file with the new style
   - Insert the style name at your cursor position

## Usage

### Basic Usage

1. Position your cursor where you want to insert a style name
2. Press `<leader>cw` or run `:ColorWizard`
3. Select a color
4. Choose styling options
5. The style name will be inserted at your cursor

### In Highlight Definitions

```lua
local highlights = {
    -- Position cursor here, then press <leader>cw
    ["@keyword"]                  = _,  -- Will become ["@keyword"] = deepPinkBold,
}
```

## Benefits

- **Descriptive Names**: No more remembering hex codes - use meaningful color names
- **Self-Documenting**: Names like `skyBlueBold` clearly express both color and style
- **Dynamic**: Style definitions are created as needed, keeping the codebase lean
- **Consistent**: Maintains proper alignment and formatting in your colorscheme file
- **Flexible**: Works with any colorscheme with minimal configuration

## Requirements

- Neovim 0.5.0 or later
- A color picker plugin is recommended, but not required

## Color Name Mapping

Color Wizard includes a built-in mapping of hex codes to color names:

```lua
local color_names = {
    ["#FF0000"] = "red",
    ["#FF4040"] = "tomato",
    ["#FF1493"] = "deepPink",
    ["#FF69B4"] = "hotPink",
    -- And many more...
}
```

You can extend this mapping by editing the `color_names` table in `color-wizard.lua`.

## Future Improvements

- Color distance calculation for approximate name matching
- More comprehensive color name database
- Integration with more color picker plugins
- Custom style template options
- Persistent style database separate from colorscheme file

## Implementation Details

The plugin uses regex pattern matching to parse the colorscheme file and insert new style definitions in the appropriate location. It also includes a helper function to combine colors and styles into meaningful names.

The dynamic nature of this approach means you only define the styles you actually use, keeping your colorscheme file efficient and focused. 