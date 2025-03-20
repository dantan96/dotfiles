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

" Mark that we're handling syntax highlighting from tamarin-colors.lua
let b:spthy_syntax_loaded = 1

" Load the Tamarin colors setup which handles all syntax highlighting
lua require('config.tamarin-colors').setup()

" Set up TreeSitter if available
if exists('g:loaded_nvim_treesitter')
  " Try to start TreeSitter
  lua pcall(function() vim.treesitter.start(0, 'spthy') end)
endif 