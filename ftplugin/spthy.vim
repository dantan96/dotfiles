" ftplugin for Tamarin spthy files
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Set up TreeSitter if available
if exists('g:loaded_nvim_treesitter')
  " Try to start TreeSitter
  lua pcall(function() vim.treesitter.start(0, 'spthy') end)
  
  " Check if TreeSitter is active for this buffer
  lua if not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] then vim.cmd('syntax enable') end
else
  " TreeSitter not available, use regular syntax highlighting
  syntax enable
endif

" Set comment string for Tamarin files
setlocal commentstring=/*%s*/
setlocal comments=s1:/*,mb:*,ex:*/

" Set formatting options
setlocal formatoptions+=ro
setlocal formatoptions-=t

" Use spthy parser for tamarin files
let b:tamarin_treesitter_initialized = 1

" Enable folding by syntax
setlocal foldmethod=syntax
setlocal foldlevel=99
