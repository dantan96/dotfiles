-- Tamarin Syntax Initialization Script
-- This script forces the proper setup of syntax highlighting for Tamarin/spthy files

-- Set timeout protection
local start_time = os.time()
local function check_timeout(max_seconds)
  if os.time() - start_time > max_seconds then
    print("ERROR: Script execution timed out after " .. max_seconds .. " seconds")
    os.exit(1)
  end
end

-- Set up debug output
local function debug_print(msg)
  print("[Tamarin Syntax] " .. msg)
end

debug_print("Starting Tamarin syntax initialization...")

-- Disable any interactive prompts
vim.opt.shortmess:append("aoOstTWAIcCqfs")
vim.opt.more = false
vim.opt.confirm = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.api.nvim_set_keymap('n', 'q', '<Nop>', {noremap = true})
vim.api.nvim_set_keymap('n', 'Q', '<Nop>', {noremap = true})

-- Load colorscheme directly with error handling
local colors = {}
local ok, config = pcall(require, 'config.spthy-colorscheme')
if not ok then
  debug_print("Error loading color configuration: " .. tostring(config))
  debug_print("Using fallback colors")
  -- Fallback colors if config can't be loaded
  colors = {
    magentaBold = { fg = "#FF00FF", bold = true },
    deepGreen = { fg = "#006400", bold = false },
    hotPinkPlain = { fg = "#FF69B4", bold = false },
    skyBluePlain = { fg = "#00BFFF", bold = false },
    redBold = { fg = "#FF3030", bold = true },
    blueBoldUnderlined = { fg = "#1E90FF", bold = true, underline = true },
    blueBold = { fg = "#1E90FF", bold = true },
    lightPinkPlain = { fg = "#FFB6C1", bold = false },
    tomatoItalic = { fg = "#FF6347", italic = true, bold = false },
    slateGrayBold = { fg = "#708090", bold = true },
    slateGrayPlain = { fg = "#708090" },
    grayItalic = { fg = "#777777", italic = true },
    hotPinkBold = { fg = "#FF1493", bold = true }
  }
else
  colors = config.colors
end

check_timeout(2)

-- Force syntax highlighting on
vim.cmd("syntax on")
vim.cmd("syntax enable")

-- Set filetype explicitly
vim.bo.filetype = "spthy"

-- Set syntax explicitly
vim.cmd("set syntax=spthy")

-- Define colors for highlight groups directly
local function apply_colors()
  debug_print("Defining color highlight groups...")
  
  -- Keywords
  pcall(function() vim.api.nvim_set_hl(0, "spthyKeyword", colors.magentaBold) end)
  
  -- Variables
  pcall(function() vim.api.nvim_set_hl(0, "spthyPublicVar", colors.deepGreen) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyPublicVarPrefix", colors.deepGreen) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyFreshVar", colors.hotPinkPlain) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyFreshVarPrefix", colors.hotPinkPlain) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyTemporalVar", colors.skyBluePlain) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyTemporalVarPrefix", colors.skyBluePlain) end)
  
  -- Facts
  pcall(function() vim.api.nvim_set_hl(0, "spthyPersistentFact", colors.redBold) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyPersistentFactPrefix", colors.redBold) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyBuiltinFact", colors.blueBoldUnderlined) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyNormalFact", colors.blueBold) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyActionFact", colors.lightPinkPlain) end)
  
  -- Functions
  pcall(function() vim.api.nvim_set_hl(0, "spthyFunction", colors.tomatoItalic) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyBuiltinFunction", colors.blueBoldUnderlined) end)
  
  -- Operators
  pcall(function() vim.api.nvim_set_hl(0, "spthyRuleArrow", colors.slateGrayBold) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyOperator", colors.slateGrayPlain) end)
  pcall(function() vim.api.nvim_set_hl(0, "spthyBracket", colors.slateGrayPlain) end)
  
  -- Comments
  pcall(function() vim.api.nvim_set_hl(0, "spthyComment", colors.grayItalic) end)
  
  -- Constants
  pcall(function() vim.api.nvim_set_hl(0, "spthyConstant", colors.hotPinkBold) end)
  
  debug_print("Color groups defined.")
end

check_timeout(3)

-- Apply syntax patterns
local function apply_syntax()
  debug_print("Setting up syntax patterns...")
  
  -- Use pcall to avoid errors
  ok, err = pcall(function()
    vim.cmd([[
      " Clear any existing syntax
      syntax clear
      
      " Comments
      syntax match spthyComment /\/\/.*$/ contains=@Spell
      syntax region spthyComment start="/\*" end="\*/" fold contains=@Spell
      
      " Keywords
      syntax keyword spthyKeyword theory begin end
      syntax keyword spthyKeyword rule lemma axiom builtins
      syntax keyword spthyKeyword functions equations predicates
      syntax keyword spthyKeyword restrictions let in
      
      " Public variables with '$' prefix
      syntax match spthyPublicVarPrefix /\$/ contained
      syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ contains=spthyPublicVarPrefix containedin=ALL
      
      " Fresh variables with '~' prefix
      syntax match spthyFreshVarPrefix /\~/ contained
      syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ contains=spthyFreshVarPrefix containedin=ALL
      
      " Temporal variables with '#' prefix
      syntax match spthyTemporalVarPrefix /#/ contained
      syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/ contains=spthyTemporalVarPrefix containedin=ALL
      
      " Persistent facts with '!' prefix
      syntax match spthyPersistentFactPrefix /!/ contained
      syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ contains=spthyPersistentFactPrefix
      
      " Built-in facts
      syntax keyword spthyBuiltinFact Fr In Out K
      
      " Action facts
      syntax region spthyActionFact start=/--\[/ end=/\]->/ contains=spthyRuleArrow,spthyFreshVar,spthyPublicVar,spthyTemporalVar,spthyPersistentFact,spthyBuiltinFact,spthyNormalFact
      
      " Regular facts
      syntax match spthyNormalFact /\<[A-Z][A-Za-z0-9_]*\>/ contains=NONE
      
      " Function names
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
    ]])
  end)
  
  if not ok then
    debug_print("Error setting up syntax patterns: " .. tostring(err))
  else
    debug_print("Syntax patterns set up.")
  end
end

check_timeout(5)

-- Main function
local function main()
  -- Apply highlight colors first
  apply_colors()
  
  -- Apply syntax patterns
  apply_syntax()
  
  -- Force re-apply of highlight colors (in case they were overridden)
  apply_colors()
  
  -- Mark this file as handled (to prevent conflicts)
  vim.b.spthy_syntax_loaded = true
  vim.b.current_syntax = "spthy"
  
  -- Clear/disable TreeSitter highlighting if active
  pcall(function()
    if vim.fn.exists(":TSBufDisable") == 1 then
      vim.cmd("TSBufDisable highlight")
    end
  end)
  
  debug_print("Syntax highlighting completed!")
end

-- Run main function with error handling
ok, err = pcall(main)
if not ok then
  debug_print("Error in main function: " .. tostring(err))
  os.exit(1)
end

check_timeout(8)

-- Exit if called directly (not as a module)
if arg ~= nil and #arg > 0 then
  os.exit(0)
end 