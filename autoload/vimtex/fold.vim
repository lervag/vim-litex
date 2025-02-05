" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#init_buffer() abort " {{{1
  if !g:vimtex_fold_enabled
        \ || s:foldmethod_in_modeline() | return | endif

  " Set fold options
  setlocal foldmethod=expr
  setlocal foldexpr=vimtex#fold#level(v:lnum)
  setlocal foldtext=vimtex#fold#text()

  if g:vimtex_fold_manual
    " Remap zx to refresh fold levels
    nnoremap <silent><buffer><nowait> zx :call vimtex#fold#refresh('zx')<cr>
    nnoremap <silent><buffer><nowait> zX :call vimtex#fold#refresh('zX')<cr>

    " Define commands
    command! -buffer VimtexRefreshFolds call vimtex#fold#refresh('zx')

    " Ensure that folds are refreshed on startup
    augroup vimtex_temporary
      autocmd! * <buffer>
      autocmd CursorMoved <buffer>
            \   call vimtex#fold#refresh('zx')
            \ | autocmd! vimtex_temporary CursorMoved <buffer>
    augroup END
  endif
endfunction

" }}}1
function! vimtex#fold#init_state(state) abort " {{{1
  "
  " Initialize the enabled fold types
  "
  let a:state.fold_types_dict = {}
  for [l:key, l:val] in items(g:vimtex_fold_types_defaults)
    let l:config = extend(deepcopy(l:val), get(g:vimtex_fold_types, l:key, {}))
    if get(l:config, 'enabled', 1)
      let a:state.fold_types_dict[l:key] = vimtex#fold#{l:key}#new(l:config)
    endif
  endfor

  "
  " Define ordered list and the global fold regex
  "
  let a:state.fold_types_ordered = []
  let a:state.fold_re = '\v'
        \ .  '\\%(begin|end)>'
        \ . '|^\s*\%'
        \ . '|^\s*\]\s*%(\{|$)'
        \ . '|^\s*}'
  let a:state.fold_re_next = ''
  let a:state.fold_re_comment = ''
  for l:name in [
        \ 'preamble',
        \ 'cmd_single',
        \ 'cmd_single_opt',
        \ 'cmd_multi',
        \ 'cmd_addplot',
        \ 'sections',
        \ 'markers',
        \ 'items',
        \ 'envs',
        \ 'env_options',
        \]
    let l:type = get(a:state.fold_types_dict, l:name, {})
    if empty(l:type) | continue | endif

    call add(a:state.fold_types_ordered, l:type)
    if exists('l:type.re.fold_re')
      let a:state.fold_re .= '|' .. l:type.re.fold_re
    endif

    if exists('l:type.re.fold_re_next')
      let a:state.fold_re_next .=
            \ (empty(a:state.fold_re_next) ? '\v' : '|')
            \ .. l:type.re.fold_re_next
    endif

    if exists('l:type.re.fold_re_comment')
      let a:state.fold_re_comment .=
            \ (empty(a:state.fold_re_comment) ? '\v' : '|')
            \ .. l:type.re.fold_re_comment
    endif
  endfor
endfunction

" }}}1

function! vimtex#fold#refresh(map) abort " {{{1
  if &diff
    setlocal foldmethod=diff
  else
    setlocal foldmethod=expr
    execute 'normal!' a:map
    setlocal foldmethod=manual
  endif
endfunction

" }}}1
function! vimtex#fold#level(lnum) abort " {{{1
  let l:line = getline(a:lnum)
  let l:next = getline(a:lnum + 1)

  " Never fold \begin|end{document}
  if l:line =~# '^\s*\\\%(begin\|end\){document}'
    return 0
  endif

  " Optimize: Filter out irrelevant lines
  if l:line !~# b:vimtex.fold_re && l:next !~# b:vimtex.fold_re_next
    return '='
  endif

  " Handle comments by considering the syntax
  if vimtex#syntax#in_comment(a:lnum, 1)
        \ && l:line !~# b:vimtex.fold_re_comment
    if l:line =~# '^\s*\\begin\s*{comment}'
      return 'a1'
    elseif l:line =~# '^\s*\\end\s*{comment}'
      return 's1'
    else
      return '='
    endif
  endif

  for l:type in b:vimtex.fold_types_ordered
    let l:value = l:type.level(l:line, a:lnum)
    if !empty(l:value) | return l:value | endif
  endfor

  return '='
endfunction

" }}}1
function! vimtex#fold#text() abort " {{{1
  let l:line = getline(v:foldstart)
  let l:level = v:foldlevel > 1
        \ ? repeat('-', v:foldlevel-2) . g:vimtex_fold_levelmarker
        \ : ''

  for l:type in b:vimtex.fold_types_ordered
    if l:line =~# l:type.re.start
      let l:text = l:type.text(l:line, l:level)
      if !empty(l:text) | return l:text | endif
    endif
  endfor
endfunction

" }}}1


function! s:foldmethod_in_modeline() abort " {{{1
  let l:cursor_pos = vimtex#pos#get_cursor()
  let l:fdm_modeline = 'vim:.*\%(foldmethod\|fdm\)'

  call vimtex#pos#set_cursor(1, 1)
  let l:check_top = search(l:fdm_modeline, 'cn', &modelines)

  normal! G$
  let l:check_btm = search(l:fdm_modeline, 'b', line('$') + 1 - &modelines)

  call vimtex#pos#set_cursor(l:cursor_pos)
  return l:check_top || l:check_btm
endfunction

" }}}1
