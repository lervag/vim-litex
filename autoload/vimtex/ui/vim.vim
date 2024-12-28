" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#ui#vim#confirm(prompt) abort
  return vimtex#ui#legacy#confirm(a:prompt)
endfunction

function! vimtex#ui#vim#input(options) abort
  return vimtex#ui#legacy#input(a:options)
endfunction

function! vimtex#ui#vim#select(options, list) abort
  return vimtex#ui#legacy#select(a:options, a:list)
endfunction
