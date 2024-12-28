" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#ui#nvim#confirm(prompt) abort
  let l:content = [s:formatted_to_string(a:prompt)]
  let l:content += ['']
  let l:content += ['  y = Yes']
  let l:content += ['  n = No ']

  let l:popup_cfg = { 'content': l:content }
  function l:popup_cfg.highlight() abort
    syntax match VimtexPopupContent ".*" contains=VimtexPopupPrompt
    syntax match VimtexPopupPrompt "[yn] = \(Yes\|No\)"
          \ contains=VimtexPopupPromptInput
    syntax match VimtexPopupPromptInput "= \(Yes\|No\)" contained
  endfunction
  let l:popup = vimtex#ui#nvim#popup(l:popup_cfg)

  " Wait for input
  while v:true
    let l:input = nr2char(getchar())
    if index(["\<C-c>", "\<Esc>", 'y', 'Y', 'n', 'N'], l:input) >= 0
      break
    endif
  endwhile

  call l:popup.close()
  return l:input ==? 'y'
endfunction

function! vimtex#ui#nvim#input(options) abort
  if has_key(a:options, 'completion')
    " We can't replicate completion, so let's just fall back.
    return vimtex#ui#vim#input(a:options)
  endif

  let l:content = empty(a:options.info)
        \ ? []
        \ : [s:formatted_to_string(a:options.info)]
  let l:content += [a:options.prompt]
  let l:popup_cfg = {
        \ 'content': l:content,
        \ 'min_width': 0.7,
        \ 'prompt': a:options.prompt,
        \}
  function l:popup_cfg.highlight() abort dict
    syntax match VimtexPopupContent ".*" contains=VimtexPopupPrompt
    execute 'syntax match VimtexPopupPrompt'
          \ '"^\s*' . self.prompt . '"'
          \ 'nextgroup=VimtexPopupPromptInput'
    syntax match VimtexPopupPromptInput ".*"  contained
  endfunction
  let l:popup = vimtex#ui#nvim#popup(l:popup_cfg)

  let l:value = a:options.text
  while v:true
    call nvim_buf_set_lines(0, -2, -1, v:false, [' > ' . l:value])
    redraw!

    let l:input_raw = getchar()
    let l:input = nr2char(l:input_raw)

    if index(["\<c-c>", "\<esc>", "\<c-q>"], l:input) >= 0
      let l:value = ""
      break
    endif

    if l:input ==# "\<cr>"
      break
    endif

    if l:input_raw ==# "\<bs>"
      let l:value = strcharpart(l:value, 0, strchars(l:value) - 1)
    elseif l:input ==# "\<c-u>"
      let l:value = ""
    else
      let l:value .= l:input
    endif
  endwhile

  call l:popup.close()
  return l:value
endfunction

function! vimtex#ui#nvim#select(options, list) abort
  let l:length = len(a:list)
  let l:digits = len(l:length)

  " Prepare menu of choices
  let l:content = [s:formatted_to_string(a:options.prompt), '']
  if !a:options.force_choice
    call add(l:content, repeat(' ', l:digits - 1) . 'x: Abort')
  endif
  let l:format = printf('%%%dd: %%s', l:digits)
  let l:i = 0
  for l:x in a:list
    let l:i += 1
    call add(l:content, printf(
          \ l:format, l:i, type(l:x) == v:t_dict ? l:x.name : l:x))
  endfor

  " Create popup window
  let l:popup_cfg = {
        \ 'content': l:content,
        \ 'position': 'window',
        \ 'min_width': 0.8,
        \ 'hide_cursor': v:true,
        \}
  function l:popup_cfg.highlight() abort
    syntax match VimtexPopupContent ".*" contains=VimtexPopupPrompt
    syntax match VimtexPopupPrompt "^\s*\(\d\+\|x\):\s*"
          \ nextgroup=VimtexPopupPromptInput
    syntax match VimtexPopupPromptInput ".*" contained
  endfunction
  let l:popup = vimtex#ui#nvim#popup(l:popup_cfg)

  let l:value = [-1, '']
  while v:true
    try
      let l:choice = vimtex#ui#get_number(
            \ l:length, l:digits, a:options.force_choice, v:false)

      if !a:options.force_choice && l:choice == -2
        break
      endif

      if l:choice >= 0 && l:choice < l:length
        let l:value = [l:choice, a:list[l:choice]]
        break
      endif
    endtry
  endwhile

  call l:popup.close()
  return l:value
endfunction

function! vimtex#ui#nvim#popup(cfg) abort
  let l:popup = extend({
        \ 'content': [],
        \ 'padding': 1,
        \ 'position': 'cursor',
        \ 'min_width': 0.0,
        \ 'min_height': 0.0,
        \ 'hide_cursor': v:false,
        \}, a:cfg)

  " Define default highlight groups
  if !hlexists("VimtexHideCursor")
    call nvim_set_hl(0, "VimtexHideCursor", #{ blend: 100, nocombine: v:true })
    highlight default link VimtexPopupContent PreProc
    highlight default link VimtexPopupPrompt Special
    highlight default link VimtexPopupPromptInput Type
  endif

  " Prepare content
  let l:content = map(
        \ repeat([''], l:popup.padding) + deepcopy(l:popup.content),
        \ { _, x -> empty(x) ? x : repeat(' ', l:popup.padding) . x }
        \)

  " Calculate window dimensions
  let l:winheight = winheight(0)
  let l:winwidth = winwidth(0)
  let l:height = len(l:content) + l:popup.padding
  let l:height = max([l:height, float2nr(l:popup.min_height*l:winheight)])

  let l:width = 0
  for l:line in l:content
    if strdisplaywidth(l:line) > l:width
      let l:width = strdisplaywidth(l:line)
    endif
  endfor
  let l:width += 2*l:popup.padding
  let l:width = max([l:width, float2nr(l:popup.min_width*l:winwidth)])

  " Create and fill the buffer
  let l:bufnr = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(l:bufnr, 0, -1, v:false, l:content)
  call nvim_buf_set_option(l:bufnr, 'buftype', 'nofile')

  " Create popup window
  let l:winopts = #{
        \ width: l:width,
        \ height: l:height,
        \ style: "minimal",
        \ noautocmd: v:true,
        \}
  if l:popup.position ==# 'cursor'
    let l:winopts.relative = 'cursor'

    let l:c = col('.')
    if l:width < l:winwidth - l:c - 1
      let l:winopts.row = 1 - l:height/2
      let l:winopts.col = 2
    else
      let l:winopts.row = 1
      let l:winopts.col = 1
      " let l:winopts.col = (l:winwidth - width)/2 - l:c
    endif
  elseif l:popup.position ==# 'window'
    let l:winopts.relative = 'win'
    let l:winopts.row = (l:winheight - l:height)/3
    let l:winopts.col = (l:winwidth - l:width)/2
  endif
  call nvim_open_win(l:bufnr, v:true, l:winopts)
  if l:popup.hide_cursor
    let l:popup._guicursor = &guicursor
    let &guicursor = 'a:VimtexHideCursor'
  endif

  " Apply highlighting
  if has_key(l:popup, 'highlight')
    call l:popup.highlight()
  endif

  call extend(l:popup, #{
        \ bufnr: l:bufnr,
        \ height: height,
        \ width: width,
        \})

  function l:popup.close() abort dict
    close
    call nvim_buf_delete(self.bufnr, #{force: v:true})
    if self.hide_cursor
      let &guicursor = self._guicursor
    endif
  endfunction

  redraw!
  return l:popup
endfunction


function! s:formatted_to_string(list_or_string) abort
  " The input can be a string or an echo-formatted list (see vimtex#ui#echo).
  " If the latter, then we must "flatten" and join it.
  if type(a:list_or_string) == v:t_string
    return a:list_or_string
  endif

  let l:strings = map(
        \ a:list_or_string,
        \ { _, x -> type(x) == v:t_list ? x[1] : x })
  return join(l:strings, '')
endfunction
