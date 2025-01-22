set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set fillchars=fold:\ 
set number
set foldcolumn=4

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

let g:vimtex_fold_enabled = 1

silent edit test-other.tex

if empty($INMAKE) | finish | endif


call assert_equal(1, foldlevel(1))
call assert_equal(1, foldlevel(2))
call assert_equal(2, foldlevel(34))
call assert_equal(2, foldlevel(48))
call assert_equal(3, foldlevel(128))
call assert_equal(2, foldlevel(144))

call assert_equal(
      \ '      Preamble',
      \ foldtextresult(1))
call assert_equal(
      \ '      test 4',
      \ foldtextresult(217))
call assert_equal(
      \ '\usepackage[...]{biblatex}',
      \ foldtextresult(48))
call assert_equal(
      \ '\newcommand*{\StoreCiteField}[3]{%',
      \ foldtextresult(63))
call assert_equal(
      \ '\pgfplotstableread[col sep=semicolon,trim cells]{...}{\datatable}',
      \ foldtextresult(105))
call assert_equal(
      \ '(sec:test1-longer label)',
      \ matchstr(foldtextresult(146), '(.*)$'))
call assert_equal(
      \ '% {{{ Testing markers',
      \ foldtextresult(153))

" Test with different markers
let g:vimtex_fold_types = {'markers': {'open': '<<:', 'close': ':>>'}}
VimtexReload

call assert_equal('Testing markers ', foldtextresult(158))
call assert_equal('% <<: this fold worked before issue #1515', foldtextresult(163))

call assert_equal(3, foldlevel(176))
call assert_equal(5, foldlevel(179))
call assert_equal(4, foldlevel(184))
call assert_equal(3, foldlevel(186))
call assert_equal(1, foldlevel(190))
call assert_equal(2, foldlevel(202))

call assert_equal(2, foldlevel(206))
call assert_equal(
      \ '\begin{frame}      Title: Subtitle',
      \ foldtextresult(206))
call assert_equal(2, foldlevel(213))
call assert_equal(
      \ '\begin{frame}      Title page',
      \ foldtextresult(213))

call assert_equal(1, foldlevel(line('$')-1))

call vimtex#test#finished()

" vim: fdm=manual
