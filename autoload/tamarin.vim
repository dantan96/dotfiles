" tamarin.vim - Autoload functions for Tamarin integration

" Set up TreeSitter for tamarin files
function! tamarin#setup_treesitter() abort
  if exists('g:loaded_nvim_treesitter')
    lua require'nvim-treesitter.parsers'.get_parser_configs().tamarin = { install_info = { url = "none", files = {} }, filetype = "tamarin", used_by = { "tamarin" } }
    lua vim.treesitter.language_add_aliases("spthy", { "tamarin" })
  endif
endfunction

" Ensure this runs when Tamarin filetype is loaded
augroup TamarinSetup
  autocmd!
  autocmd FileType tamarin call tamarin#setup_treesitter()
augroup END
