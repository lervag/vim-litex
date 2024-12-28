" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#init_buffer() abort
  if !g:vimtex_view_enabled | return | endif

  command! -buffer -nargs=? -complete=file VimtexView
        \ call vimtex#view#view(<q-args>)

  nnoremap <buffer> <plug>(vimtex-view) :VimtexView<cr>

  if has('nvim')
    call s:nvim_prune_servernames()
  endif
endfunction

function! vimtex#view#init_state(state) abort
  if !g:vimtex_view_enabled | return | endif
  if has_key(a:state, 'viewer') | return | endif

  augroup vimtex_viewer
    autocmd!
    autocmd User VimtexEventCompileSuccess call vimtex#view#compiler_callback()
    autocmd User VimtexEventCompileStopped call vimtex#view#compiler_stopped()
  augroup END

  try
    let a:state.viewer = vimtex#view#{g:vimtex_view_method}#new()
  catch /E117/
    call vimtex#log#warning(
          \ 'Invalid viewer: ' . g:vimtex_view_method,
          \ 'Please see :h g:vimtex_view_method')
    return
  endtry
endfunction


function! vimtex#view#view(...) abort
  if exists('*b:vimtex.viewer.view')
    call b:vimtex.viewer.view(a:0 > 0 ? a:1 : '')
  endif
endfunction

function! vimtex#view#compiler_callback() abort
  if exists('*b:vimtex.viewer.compiler_callback')
    if !b:vimtex.viewer.check() | return | endif

    let l:pdf = b:vimtex.viewer.out()
    if empty(l:pdf) | return | endif

    call b:vimtex.viewer.compiler_callback(l:pdf)
  endif
endfunction

function! vimtex#view#compiler_stopped() abort
  if exists('*b:vimtex.viewer.compiler_stopped')
    call b:vimtex.viewer.compiler_stopped()
  endif
endfunction


function! vimtex#view#inverse_search(line, filename, column = 0) abort
  " Only activate in VimTeX buffers
  if !exists('b:vimtex') | return -1 | endif

  " Only activate in relevant VimTeX projects
  let l:file = resolve(a:filename)
  let l:sources = b:vimtex.get_sources()
  if vimtex#paths#is_abs(l:file)
    call map(l:sources, {_, x -> vimtex#paths#join(b:vimtex.root, x)})
  endif
  if index(l:sources, l:file) < 0 | return -2 | endif


  if mode() ==# 'i' | stopinsert | endif

  " Open file if necessary
  if !bufloaded(l:file)
    if filereadable(l:file)
      try
        execute g:vimtex_view_reverse_search_edit_cmd l:file
      catch
        call vimtex#log#warning([
              \ 'Reverse goto failed!',
              \ printf('Command error: %s %s',
              \        g:vimtex_view_reverse_search_edit_cmd, l:file)])
        return -3
      endtry
    else
      call vimtex#log#warning([
            \ 'Reverse goto failed!',
            \ printf('File not readable: "%s"', l:file)])
      return -4
    endif
  endif

  " Get buffer, window, and tab numbers
  " * If tab/window exists, switch to it/them
  let l:bufnr = bufnr(l:file)
  try
    let [l:winid; _] = win_findbuf(l:bufnr)
    let [l:tabnr, l:winnr] = win_id2tabwin(l:winid)
    execute l:tabnr . 'tabnext'
    execute l:winnr . 'wincmd w'
  catch
    execute g:vimtex_view_reverse_search_edit_cmd l:file
  endtry

  execute 'normal!' a:line . 'G'
  if a:column > 0
    execute 'normal!' a:column . '|'
  endif
  if b:vimtex.viewer.xdo_check()
    call b:vimtex.viewer.xdo_focus_vim()
  endif
  redraw

  call vimtex#ui#blink()

  if exists('#User#VimtexEventViewReverse')
    doautocmd <nomodeline> User VimtexEventViewReverse
  endif
endfunction

function! vimtex#view#inverse_search_cmd(line, filename, column) abort
  " One may call this function manually, but the main usage is to through the
  " command "VimtexInverseSearch". See ":help vimtex-synctex-inverse-search"
  " for more info.

  if a:line > 0 && !empty(a:filename)
    try
      if has('nvim')
        call s:inverse_search_cmd_nvim(a:line, a:filename, a:column)
      else
        call s:inverse_search_cmd_vim(a:line, a:filename, a:column)
      endif
    catch
    endtry
  endif

  quitall!
endfunction


function! s:inverse_search_cmd_nvim(line, filename, column) abort
  if !filereadable(s:nvim_servernames) | return | endif

  for l:server in readfile(s:nvim_servernames)
    try
      let l:socket = sockconnect('pipe', l:server, {'rpc': 1})
    catch
    endtry

    call rpcnotify(l:socket,
          \ 'nvim_call_function',
          \ 'vimtex#view#inverse_search',
          \ [a:line, a:filename, a:column])
    call chanclose(l:socket)
  endfor
endfunction

function! s:inverse_search_cmd_vim(line, filename, column) abort
  for l:server in split(serverlist(), "\n")
    call remote_expr(l:server,
          \ printf("vimtex#view#inverse_search(%d, '%s', %d)",
          \        a:line, a:filename, a:column))
  endfor
endfunction


function! s:nvim_prune_servernames() abort
  " Load servernames from file
  let l:servers = filereadable(s:nvim_servernames)
        \ ? readfile(s:nvim_servernames)
        \ : []

  " Check which servers are available
  let l:available_servernames = []
  for l:server in vimtex#util#uniq_unsorted(l:servers + [v:servername])
    try
      let l:socket = sockconnect('pipe', l:server)
      call add(l:available_servernames, l:server)
      call chanclose(l:socket)
    catch
    endtry
  endfor

  " Write the pruned list to file
  call writefile(l:available_servernames, s:nvim_servernames)
endfunction


let s:nvim_servernames = vimtex#cache#path('nvim_servernames.log')
