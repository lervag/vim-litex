" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#fontawesome5#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_opt('texFontawesomeOpt', {
        \ 'contains': '',
        \ 'opts': 'conceal contained containedin=texCmdFontawesome',
        \})
  call vimtex#syntax#core#new_arg('texFontawesomeArg', {
        \ 'contains': '',
        \ 'opts': 'conceal containedin=texCmdFontawesome',
        \})

  for [l:name, l:symbol] in items(s:fontawesome)
    " -alt variants correspond to starred commands
    if l:name[-4:] ==# '-alt'
      let l:name = l:name[:-5]
      let l:nameCased = substitute(l:name, '\v%(^|-)(.)', '\u\1', 'g')
      let l:re =
            \   '\\fa' . l:nameCased . '\*\|'
            \ . '\\faIcon\*\s*\%(\[\%(regular\|solid\)]\)\?\s*{' . l:name . '}'
    elseif l:name =~# '^\D'
      let l:nameCased = substitute(l:name, '\v%(^|-)(.)', '\u\1', 'g')
      let l:re =
            \   '\\fa' . l:nameCased . '\>\([^*]\|$\)\@=\|'
            \ . '\\faIcon\s*\%(\[\%(regular\|solid\)]\)\?\s*{' . l:name . '}'
    else
      " In this branch l:name ==# "500px"
      " This case does not have the \faName variant!
      let l:re = '\\faIcon\s*\%(\[\%(regular\|solid\)]\)\?\s*{' . l:name . '}'
    endif

    execute printf(
          \ 'syntax match texCmdFontawesome "%s" conceal cchar=%s',
          \ l:re, l:symbol)
  endfor

  highlight def link texCmdFontawesome texCmd
  highlight def link texFontawesomeArg texArg
  highlight def link texFontawesomeOpt texOpt
endfunction

" }}}1

let s:fontawesome = json_decode(join(
      \ readfile(vimtex#paths#asset('json/fontawesome.json'))
      \))
