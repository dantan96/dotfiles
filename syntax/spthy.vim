" Vim syntax file
" Language: Tamarin Security Protocol Theory
" Maintainer: Your Name
" Latest Revision: 20 Mar 2023

" Skip loading if syntax has already been handled by tamarin-colors.lua in ftplugin
if exists("b:spthy_syntax_loaded") || exists("b:current_syntax")
  finish
endif

" Clear any existing syntax highlighting
syntax clear

" Set up colors using our color variables defined in Lua
let s:colors = luaeval('require("config.spthy-colorscheme").colors')

" Helper function to convert a color from our table to vim highlighting
function! s:hl(group, color_key) 
  let l:fg = s:colors[a:color_key].fg
  let l:attrs = ""
  
  if get(s:colors[a:color_key], 'bold', v:false)
    let l:attrs .= " bold"
  endif
  
  if get(s:colors[a:color_key], 'italic', v:false)
    let l:attrs .= " italic"
  endif
  
  if get(s:colors[a:color_key], 'underline', v:false)
    let l:attrs .= " underline"
  endif
  
  execute "highlight " . a:group . " guifg=" . l:fg . " " . l:attrs
endfunction

" Basic elements for spthy files
" =================================
" Comments
syntax match spthyComment /\/\/.*$/ contains=@Spell
syntax region spthyComment start="/\*" end="\*/" fold contains=@Spell
call s:hl("spthyComment", "grayItalic")

" Theory structure
syntax keyword spthyKeyword theory begin end
syntax keyword spthyKeyword rule lemma axiom builtins
syntax keyword spthyKeyword functions equations predicates
syntax keyword spthyKeyword restrictions let in
call s:hl("spthyKeyword", "magentaBold")

" Operators and punctuation
" =================================
" Equal sign in let statements - neutral color
syntax match spthyOperator /=/ 
call s:hl("spthyOperator", "slateGrayPlain")

" Rule arrows and brackets with the same color
syntax match spthyRuleArrow /--\[\|\]->/ 
call s:hl("spthyRuleArrow", "slateGrayBold")

" Standard brackets and delimiters
syntax match spthyBracket /(\|)\|\[\|\]\|{\|}\|,\|;\|:/
call s:hl("spthyBracket", "slateGrayPlain")

" Variables and terms
" =================================
" Fresh variables (~) - HIGHEST PRIORITY
syntax match spthyFreshVar /\~[A-Za-z0-9_]\+/ containedin=ALL
call s:hl("spthyFreshVar", "hotPinkPlain")

" Public variables ($) - HIGHEST PRIORITY
syntax match spthyPublicVar /\$[A-Za-z0-9_]\+/ containedin=ALL
call s:hl("spthyPublicVar", "deepGreen")

" Temporal variables (#) - HIGHEST PRIORITY
syntax match spthyTemporalVar /#[A-Za-z0-9_]\+/ containedin=ALL
call s:hl("spthyTemporalVar", "skyBluePlain")

" Variable types (:pub, :fresh, etc)
syntax match spthyPublicType /[A-Za-z0-9_]\+:pub/ containedin=ALL
call s:hl("spthyPublicType", "deepGreen")

syntax match spthyFreshType /[A-Za-z0-9_]\+:fresh/ containedin=ALL
call s:hl("spthyFreshType", "hotPinkPlain")

syntax match spthyTemporalType /[A-Za-z0-9_]\+:temporal/ containedin=ALL
call s:hl("spthyTemporalType", "skyBluePlain")

syntax match spthyMessageType /[A-Za-z0-9_]\+:msg/ containedin=ALL
call s:hl("spthyMessageType", "orangePlain")

" Facts and predicates
" =================================
" Persistent facts (!) - HIGHEST PRIORITY
syntax match spthyPersistentFact /![A-Za-z0-9_]\+/ containedin=ALL
call s:hl("spthyPersistentFact", "redBold")

" Built-in facts (Fr, In, Out, K) - HIGHEST PRIORITY
syntax keyword spthyBuiltinFact Fr In Out K containedin=ALL
call s:hl("spthyBuiltinFact", "blueBoldUnderlined")

" Regular facts (not caught by others)
syntax match spthyNormalFact /\<[A-Z][A-Za-z0-9_]*\>/ 
call s:hl("spthyNormalFact", "blueBold")

" Functions and constants
" =================================
" Function names
syntax match spthyFunction /\<[a-z][A-Za-z0-9_]*\>(/he=e-1 containedin=ALL
call s:hl("spthyFunction", "tomatoItalic")

" Constants in single quotes
syntax region spthyConstant start=/'/ end=/'/ 
call s:hl("spthyConstant", "hotPinkBold")

let b:current_syntax = "spthy" 