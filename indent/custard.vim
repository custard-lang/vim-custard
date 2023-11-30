" Ref. https://github.com/wlangstroth/vim-racket/blob/2c7ec0f35a2ad1ca00305e5d67837bc1f1d4b6cc/ftplugin/racket.vim
" Ref. https://github.com/wlangstroth/vim-racket/blob/2c7ec0f35a2ad1ca00305e5d67837bc1f1d4b6cc/indent/racket.vim

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Custard's keywords don't comply with the other Lisps. So empty up.
setlocal lispwords=
setlocal lispwords+=if,else,when,scope,fn,procedure,generatorFn
setlocal lispwords+=while,for,forEach,recursive
setlocal lispwords+=async.fn,async.procedure,async.generatorFn,async.forEach
setlocal lispwords+=Map

setlocal lisp autoindent nosmartindent

let b:undo_ftplugin = "setlocal lispwords< lisp< autoindent< smartindent<"
