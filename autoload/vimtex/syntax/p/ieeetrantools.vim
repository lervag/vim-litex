" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#ieeetrantools#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'ieeetrantools') | return | endif
  let b:vimtex_syntax.ieeetrantools = 1

  call s:new_math_zone('IEEEeqnA', 'IEEEeqnarray')
  call s:new_math_zone('IEEEeqnB', 'IEEEeqnarrayboxm')
endfunction

" }}}1

function! s:new_math_zone(sfx, mathzone) abort " {{{1
  " This needs to be slightly different than vimtex#syntax#core#new_math_zone
  " to handle options for the environment.

  execute 'syntax match texBadMath ''\\end\s*{\s*' . a:mathzone . '\*\?\s*}'''

  let grp = 'texMathZone' . a:sfx
  execute 'syntax region ' . grp
        \ . ' start=''\\begin\s*{\s*' . a:mathzone . '\z(\*\?\)\s*}'
        \   . '\(\[.\{-}\]\)\?{\w*}'''
        \ . ' end=''\\end\s*{\s*' . a:mathzone . '\z1\s*}'''
        \ . ' keepend contains=@texClusterMath'
  execute 'highlight def link ' . grp . ' texMath'
endfunction

" }}}1
