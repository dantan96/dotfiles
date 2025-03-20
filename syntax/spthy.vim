" Vim syntax file for Tamarin Protocol Security Protocol Theory (.spthy) files
" Language: Tamarin
" Maintainer: Dan
" Latest Revision: 2023-10-20

if exists("b:current_syntax")
  finish
endif

" Keywords
syntax keyword spthyKeyword theory begin end builtins rule lemma functions equations
syntax keyword spthyKeyword axiom protocol nextgroup=spthyName skipwhite
syntax keyword spthyKeyword let in if then else nextgroup=spthyName skipwhite
syntax keyword spthyKeyword All Ex Fr contained
syntax keyword spthyAttr reuse hide contained

" Builtins
syntax keyword spthyBuiltin hashing signing asymmetric-encryption symmetric-encryption diffie-hellman multiset bilinear-pairing xor

" Operators and special characters
syntax match spthyOperator "[!_'?~=\-+*/%<>\[\]]"
syntax match spthyArrow "-->\|--\[\|->"
syntax match spthyFact "![A-Z][A-Za-z0-9_]*"
syntax match spthyFact "!?[A-Z][A-Za-z0-9_]*"

" Comments
syntax region spthyComment start="/\*" end="\*/" contains=spthyTodo
syntax match spthyLineComment "//.*$" contains=spthyTodo
syntax keyword spthyTodo TODO FIXME XXX NOTE contained

" Strings
syntax region spthyString start=/"/ skip=/\\"/ end=/"/

" Names and identifiers
syntax match spthyName "[A-Za-z][A-Za-z0-9_]*" contained
syntax match spthyVar "\~[a-z][A-Za-z0-9_]*"
syntax match spthyVar "\$[A-Za-z][A-Za-z0-9_]*"
syntax match spthyVar "\#[a-z][A-Za-z0-9_]*"

" Lemma attributes
syntax region spthyLemmaAttr start="\[" end="\]" contains=spthyAttr

" Define the default highlighting
highlight default link spthyKeyword Keyword
highlight default link spthyBuiltin Type
highlight default link spthyOperator Operator
highlight default link spthyArrow Special
highlight default link spthyComment Comment
highlight default link spthyLineComment Comment
highlight default link spthyTodo Todo
highlight default link spthyString String
highlight default link spthyName Function
highlight default link spthyVar Identifier
highlight default link spthyFact PreProc
highlight default link spthyAttr Special
highlight default link spthyLemmaAttr Special

let b:current_syntax = "spthy" 