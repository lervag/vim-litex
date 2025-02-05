set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax enable

set fillchars=fold:\ 
set number
set foldcolumn=4

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

let g:vimtex_fold_enabled = 1

silent edit test-comment.tex

if empty($INMAKE) | finish | endif

call assert_equal(2, foldlevel(9))
call assert_equal(2, foldlevel(11))

call vimtex#test#finished()
