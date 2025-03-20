" ftplugin for Spthy files
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Set comment string for Spthy files
setlocal commentstring=/*%s*/
setlocal comments=s1:/*,mb:*,ex:*/

" Set formatting options
setlocal formatoptions+=ro
setlocal formatoptions-=t

" Enable folding by syntax
setlocal foldmethod=syntax
setlocal foldlevel=99

" -----------------------------------
" SYNTAX HIGHLIGHTING CONFIGURATION
" -----------------------------------

" Enable explicit Spthy syntax highlighting - DO NOT COMMENT THIS LINE
set syntax=spthy

" IMPORTANT: Use ONE AND ONLY ONE of the options below

" OPTION 1: Lua-based syntax highlighting (UNCOMMENT to use)
let b:spthy_syntax_loaded = 1
lua require('config.tamarin-colors').setup()

" OPTION 2: Traditional Vim syntax highlighting (COMMENT OPTION 1 if using this)
" let b:current_syntax = ""

" OPTION 3: Pure TreeSitter highlighting (COMMENT OPTION 1 if using this)
" lua vim.treesitter.start(0, 'spthy')

" Disable the automatic TreeSitter setup at the end, since it conflicts with Option 1
" if exists('g:loaded_nvim_treesitter')
"   lua pcall(function() vim.treesitter.start(0, 'spthy') end)
" endif 