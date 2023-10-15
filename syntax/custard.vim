" Ref. https://github.com/wlangstroth/vim-racket/blob/2c7ec0f35a2ad1ca00305e5d67837bc1f1d4b6cc/syntax/racket.vim
" Ref. https://github.com/neovim/neovim/blob/54ddf56589bfe3941987d3fc9242104486aa6a15/runtime/syntax/javascript.vim

if exists("b:current_syntax")
  finish
endif

" Highlight unmatched parens
syn match custardError ,[]})],

syn keyword custardSyntax import importAnyOf
syn keyword custardSyntax const let assign

syn keyword custardSyntax if else when scope fn procedure
syn keyword custardSyntax return
syn keyword custardSyntax while for forEach recursive
syn keyword custardSyntax break continue
syn keyword custardException try catch finally throw

syn keyword custardFunction incrementF decrementF
syn keyword custardFunction array text Map

syn keyword custardBoolean true false
syn keyword custardNull undefined

syn region custardString start=/\%(\\\)\@<!"/ skip=/\\[\\"]/ end=/"/ contains=custardSpecialCharacter
syn match custardSpecialCharacter "\\\d\d\d\|\\."
syn match custardNumber "-\?\<[0-9]\+\(\.[0-9]\+\)\?\>"

syn match custardSpecial "\."

hi def link custardSyntax Statement
hi def link custardFunction Function
hi def link custardException Exception

hi def link custardString String
hi def link custardSpecialCharacter custardSpecial
hi def link custardSpecial Special
hi def link custardBoolean Boolean
hi def link custardNull Keyword

hi def link custardNumber Number

hi def link custardError Error

let b:current_syntax = "custard"
