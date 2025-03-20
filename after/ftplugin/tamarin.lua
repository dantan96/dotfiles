-- Tamarin Protocol Prover filetype plugin
vim.bo.commentstring = '/* %s */'

-- Ensure basic settings
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.iskeyword = vim.bo.iskeyword .. ",',$,~,#,%"  
vim.opt_local.spell = false

-- Set up runtime paths if needed
local nvim_config_path = vim.fn.stdpath('config')
local tamarin_queries_path = nvim_config_path .. '/queries'
if not vim.tbl_contains(vim.opt.runtimepath:get(), tamarin_queries_path) then
    vim.opt.runtimepath:append(tamarin_queries_path)
end

-- Check if TreeSitter is active for this buffer
local ts_active = false
pcall(function()
    ts_active = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
end)

-- Log info to the Tamarin debug log
local function log_debug(msg)
    local log_file = vim.fn.stdpath("cache") .. "/tamarin_init.log"
    local f = io.open(log_file, "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " - [ftplugin] " .. msg .. "\n")
        f:close()
    end
end

log_debug("Loading ftplugin for buffer " .. vim.api.nvim_get_current_buf())
log_debug("TreeSitter active: " .. tostring(ts_active))

-- Force enable syntax highlighting regardless of TreeSitter
vim.cmd("syntax enable")

-- Apply traditional syntax highlighting when needed
if not ts_active then
    log_debug("Using traditional syntax highlighting")
    
    -- Hack: Set a global flag to indicate we're providing fallback highlighting
    vim.g.tamarin_using_fallback = true
    
    vim.cmd([[
        " Keywords
        syntax keyword tamarinKeyword theory begin end rule lemma restriction functions builtins let in tactic process
        syntax keyword tamarinKeyword axiom all exists configuration export
        highlight link tamarinKeyword Keyword
        
        " Preprocessor directives
        syntax match tamarinPreproc /^\s*#\(ifdef\|endif\|define\|include\)/
        highlight link tamarinPreproc PreProc
        
        " Macro definitions
        syntax match tamarinMacro /\<macro\>\|\<macros\>:/
        highlight link tamarinMacro Define
        
        " Macro names - uppercase identifiers followed by parenthesis
        syntax match tamarinMacroName /\<[A-Z][A-Z0-9_]*\s*(/he=e-1
        highlight link tamarinMacroName Function
        
        " Comments
        syntax region tamarinComment start="/\*" end="\*/" contains=@Spell
        syntax match tamarinComment "//.*$" contains=@Spell
        highlight link tamarinComment Comment
        
        " Variables with prefixes
        syntax match tamarinPublicVar /\$[A-Za-z][A-Za-z0-9_']*/
        highlight tamarinPublicVar ctermfg=22 guifg=#006400 gui=bold cterm=bold
        
        syntax match tamarinFreshVar /\~[A-Za-z][A-Za-z0-9_']*/
        highlight link tamarinFreshVar Special
        
        " Variables with apostrophes
        syntax match tamarinApostropheVar /\<[A-Za-z][A-Za-z0-9_]*'/
        highlight link tamarinApostropheVar Identifier
        
        " Important facts
        syntax keyword tamarinFact Fr In Out K
        highlight tamarinFact ctermfg=33 guifg=#00AAFF gui=bold,underline cterm=bold,underline
        
        " Persistent facts with ! marker
        syntax match tamarinPersistentFact /![A-Za-z][A-Za-z0-9_]*\s*(/he=e-1
        syntax match tamarinPersistentFactMark /!/ contained containedin=tamarinPersistentFact
        highlight tamarinPersistentFact ctermfg=196 guifg=#FF4040 gui=bold cterm=bold
        highlight tamarinPersistentFactMark ctermfg=196 guifg=#FF4040 gui=bold cterm=bold
        
        " Linear and action facts
        syntax match tamarinLinearFact /\<[A-Z][A-Za-z0-9_]*\s*(/he=e-1
        highlight tamarinLinearFact ctermfg=33 guifg=#00AAFF gui=bold cterm=bold
        
        " Action facts and rules with arrows
        syntax match tamarinArrow /-->/
        syntax match tamarinArrow /==>/
        highlight link tamarinArrow Operator
        
        " Action facts inside the --[ and ]-> markers with light pink brackets
        syntax region tamarinActionFact matchgroup=tamarinActionBrackets start=/--\[/ end=/\]->/ contains=ALL
        syntax match tamarinActionFactName /\<[A-Z][A-Za-z0-9_]*\s*(/he=e-1 contained containedin=tamarinActionFact
        highlight tamarinActionFactName ctermfg=208 guifg=#FF8C00 gui=bold cterm=bold
        highlight tamarinActionBrackets ctermfg=218 guifg=#FFB6C1 gui=bold cterm=bold
        
        " Logical operators
        syntax keyword tamarinLogical All Ex all exists not
        highlight link tamarinLogical Operator
        
        " Special built-in functions
        syntax keyword tamarinBuiltin mac kdf pk h senc sdec
        highlight tamarinBuiltin ctermfg=214 guifg=#FFA500 gui=italic cterm=italic
        
        " Function and macro names with italics
        highlight tamarinMacroName ctermfg=220 guifg=#FFD700 gui=italic cterm=italic
        
        " Special constants
        syntax match tamarinSpecialConst /'g'/
        highlight tamarinSpecialConst ctermfg=199 guifg=#FF1493 gui=bold cterm=bold
        
        " Regular brackets and punctuation with consistent colors
        syntax match tamarinBracket /[\(\)\[\]<>]/
        highlight tamarinBracket ctermfg=245 guifg=#888888
        
        syntax match tamarinPunctuation /[,.:;]/
        highlight tamarinPunctuation ctermfg=110 guifg=#8899AA
        
        " Exponentiation operator
        syntax match tamarinExponentiation /\^/
        highlight tamarinExponentiation ctermfg=141 guifg=#AA88FF
    ]])
    
    -- Apply custom colors from config.tamarin-highlights if available
    pcall(function()
        log_debug("Applying custom syntax colors from tamarin-colors")
        require('config.tamarin-colors').setup()
    end)
else
    log_debug("Using TreeSitter syntax highlighting")
    -- Make sure TreeSitter colors are applied
    pcall(function()
        require('config.tamarin-colors').setup()
    end)
end

-- Add a debug command
vim.api.nvim_buf_create_user_command(0, "TamarinHighlightInfo", function()
    print("Tamarin Syntax Highlighting Information:")
    
    -- Check if TreeSitter is active now (might have changed)
    local has_ts = false
    pcall(function()
        has_ts = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
    end)
    
    print("TreeSitter highlighting active: " .. tostring(has_ts))
    print("Fallback syntax highlighting active: " .. tostring(vim.g.tamarin_using_fallback or false))
    
    -- Try to get the parser
    local parser_ok, parser = pcall(function() 
        return vim.treesitter.get_parser(0, "spthy") 
    end)
    print("TreeSitter parser available (spthy): " .. tostring(parser_ok))
    
    local parser_tamarin_ok, parser_tamarin = pcall(function() 
        return vim.treesitter.get_parser(0, "tamarin") 
    end)
    print("TreeSitter parser available (tamarin): " .. tostring(parser_tamarin_ok))
    
    -- Check query existence and validity
    local query_path = vim.api.nvim_get_runtime_file("queries/spthy/highlights.scm", false)[1]
    print("Query path: " .. (query_path or "Not found"))
    
    if query_path then
        local query_ok, query = pcall(vim.treesitter.query.parse, "spthy", io.open(query_path):read("*all"))
        print("Query validity: " .. tostring(query_ok))
    end
    
    -- Get node at cursor
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1 -- Convert to 0-indexed
    
    -- Get syntax info
    local syntax_id = vim.fn.synID(row + 1, col + 1, 1)
    local syntax_name = vim.fn.synIDattr(syntax_id, 'name')
    print("\nAt cursor position:")
    print("  Syntax group: " .. (syntax_name ~= "" and syntax_name or "None"))
    
    -- Get TreeSitter captures if available
    if parser_ok then
        pcall(function()
            local captures = vim.treesitter.get_captures_at_pos(0, row, col)
            if #captures > 0 then
                print("  TreeSitter captures:")
                for _, capture in ipairs(captures) do
                    print("    - " .. capture.capture .. " (node: " .. capture.node:type() .. ")")
                end
            else
                print("  TreeSitter captures: None")
            end
        end)
    end
    
    -- Enable debug mode and run debugger if available
    vim.g.tamarin_highlight_debug = true
    print("\nDebug mode enabled. Reload buffer to see highlight application messages.")
    print("\nRun :TamarinDebug for a full highlighting analysis.")
end, {})

log_debug("Tamarin ftplugin loaded successfully")

-- Print welcome message only in normal mode
if not vim.g.tamarin_loaded and not vim.g.headless then
    vim.g.tamarin_loaded = 1
end 