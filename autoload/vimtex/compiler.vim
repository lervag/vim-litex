" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#init_buffer() abort " {{{1
  if !g:vimtex_compiler_enabled | return | endif

  " Define commands
  command! -buffer        -nargs=* VimtexCompile               call vimtex#compiler#compile(<f-args>)
  command! -buffer -bang  -nargs=* VimtexCompileSS             call vimtex#compiler#compile_ss(<f-args>)

  command! -buffer -range VimtexCompileSelected <line1>,<line2>call vimtex#compiler#compile_selected('command')
  command! -buffer        VimtexCompileOutput                  call vimtex#compiler#output()
  command! -buffer        VimtexStop                           call vimtex#compiler#stop()
  command! -buffer        VimtexStopAll                        call vimtex#compiler#stop_all()
  command! -buffer -bang  VimtexClean                          call vimtex#compiler#clean(<q-bang> == "!")
  command! -buffer -bang  VimtexStatus                         call vimtex#compiler#status(<q-bang> == "!")

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-compile)          :call vimtex#compiler#compile()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-ss)       :call vimtex#compiler#compile_ss()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-selected) :set opfunc=vimtex#compiler#compile_selected<cr>g@
  xnoremap <buffer> <plug>(vimtex-compile-selected) :<c-u>call vimtex#compiler#compile_selected('visual')<cr>
  nnoremap <buffer> <plug>(vimtex-compile-output)   :call vimtex#compiler#output()<cr>
  nnoremap <buffer> <plug>(vimtex-stop)             :call vimtex#compiler#stop()<cr>
  nnoremap <buffer> <plug>(vimtex-stop-all)         :call vimtex#compiler#stop_all()<cr>
  nnoremap <buffer> <plug>(vimtex-clean)            :call vimtex#compiler#clean(0)<cr>
  nnoremap <buffer> <plug>(vimtex-clean-full)       :call vimtex#compiler#clean(1)<cr>
  nnoremap <buffer> <plug>(vimtex-status)           :call vimtex#compiler#status(0)<cr>
  nnoremap <buffer> <plug>(vimtex-status-all)       :call vimtex#compiler#status(1)<cr>
endfunction

" }}}1
function! vimtex#compiler#init_state(state) abort " {{{1
  if !g:vimtex_compiler_enabled | return | endif

  let a:state.compiler = s:init_compiler({
        \ 'file_info': {
        \   'root': a:state.root,
        \   'target': a:state.tex,
        \   'target_name': a:state.name,
        \   'target_basename': a:state.base,
        \   'jobname': a:state.name,
        \ }
        \})
endfunction

" }}}1

function! vimtex#compiler#callback(status) abort " {{{1
  " Status:
  " 1: Compilation cycle has started
  " 2: Compilation complete - Success
  " 3: Compilation complete - Failed
  if !exists('b:vimtex.compiler') | return | endif
  silent! call s:output.pause()

  let l:__silent = b:vimtex.compiler.silence_next_callback
  if l:__silent
    let b:vimtex.compiler.silence_next_callback = v:false
    if g:vimtex_compiler_silent
      let l:__silent = v:false
    else
      call vimtex#log#set_silent()
    endif
  endif

  let b:vimtex.compiler.status = a:status

  if a:status == 1
    if exists('#User#VimtexEventCompiling')
      doautocmd <nomodeline> User VimtexEventCompiling
    endif
  elseif a:status == 2
    if !g:vimtex_compiler_silent
      call vimtex#log#info('Compilation completed')
    endif

    if exists('b:vimtex')
      call b:vimtex.update_packages()
      call vimtex#syntax#packages#init()
    endif

    call vimtex#qf#open(0)
    if exists('#User#VimtexEventCompileSuccess')
      doautocmd <nomodeline> User VimtexEventCompileSuccess
    endif
  elseif a:status == 3
    if !g:vimtex_compiler_silent
      call vimtex#log#warning('Compilation failed!')
    endif

    call vimtex#qf#open(0)
    if exists('#User#VimtexEventCompileFailed')
      doautocmd <nomodeline> User VimtexEventCompileFailed
    endif
  endif

  if l:__silent
    call vimtex#log#set_silent_restore()
  endif

  silent! call s:output.resume()
endfunction

" }}}1

function! vimtex#compiler#compile(...) abort " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  if b:vimtex.compiler.is_running()
    call vimtex#compiler#stop()
  else
    call call('vimtex#compiler#start', a:000)
  endif
endfunction

" }}}1
function! vimtex#compiler#compile_ss(...) abort " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  if b:vimtex.compiler.is_running()
    call vimtex#log#info(
          \ 'Compiler is already running, use :VimtexStop to stop it!')
    return
  endif

  call b:vimtex.compiler.start_single(expandcmd(join(a:000)))

  if g:vimtex_compiler_silent | return | endif
  call vimtex#log#info('Compiler started in background!')
endfunction

" }}}1
function! vimtex#compiler#compile_selected(type) abort range " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  " Values of a:firstline and a:lastline are not available in nested function
  " calls, so we must handle them here.
  let l:opts = a:type ==# 'command'
        \ ? {'type': 'range', 'range': [a:firstline, a:lastline]}
        \ : {'type':  a:type =~# 'line\|char\|block' ? 'operator' : a:type}

  let l:state = vimtex#parser#selection_to_texfile(l:opts)
  if empty(l:state) | return | endif

  " Create and initialize temporary compiler
  let l:compiler = s:init_compiler({
        \ 'file_info': {
        \   'root': l:state.root,
        \   'target': l:state.tex,
        \   'target_name': l:state.name,
        \   'target_basename': l:state.base,
        \   'jobname': l:state.name,
        \ },
        \ 'out_dir': '',
        \ 'continuous': 0,
        \ 'callback': 0,
        \})
  if empty(l:compiler) | return | endif

  call vimtex#log#info('Compiling selected lines ...')
  call vimtex#log#set_silent()
  call l:compiler.start()
  call l:compiler.wait()

  " Check if successful
  if vimtex#qf#inquire(l:state.tex)
    call vimtex#log#set_silent_restore()
    call vimtex#log#warning('Compiling selected lines ... failed!')
    botright cwindow
    return
  else
    call l:compiler.clean(0)
    call b:vimtex.viewer.view(l:state.pdf)
    call vimtex#log#set_silent_restore()
    call vimtex#log#info('Compiling selected lines ... done')
  endif
endfunction

" }}}1
function! vimtex#compiler#output() abort " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  if !exists('b:vimtex.compiler.output')
        \ || !filereadable(b:vimtex.compiler.output)
    call vimtex#log#warning('No output exists!')
    return
  endif

  " If relevant output is open, then reuse it
  if exists('s:output')
    if s:output.name ==# b:vimtex.compiler.output
      if bufwinnr(b:vimtex.compiler.output) == s:output.winnr
        execute s:output.winnr . 'wincmd w'
      endif
      return
    else
      call s:output.destroy()
    endif
  endif

  call s:output_factory.create(b:vimtex.compiler.output)
endfunction

" }}}1
function! vimtex#compiler#start(...) abort " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  if !b:vimtex.is_compileable()
    call vimtex#log#error(
          \ 'Compilation error due to failed mainfile detection!',
          \ 'Please ensure that VimTeX can locate the proper main .tex file.',
          \ 'Read ":help vimtex-multi-file" for more info.'
          \)
    return
  endif
  if b:vimtex.compiler.is_running()
    call vimtex#log#warning(
          \ 'Compiler is already running for `' . b:vimtex.base . "'")
    return
  endif

  call b:vimtex.compiler.start(expandcmd(join(a:000)))

  if g:vimtex_compiler_silent | return | endif

  " We add a redraw here to clear messages (e.g. file written). This is useful
  " to avoid the "Press ENTER" prompt in some cases, see e.g.
  " https://github.com/lervag/vimtex/issues/2149
  redraw

  if b:vimtex.compiler.continuous
    call vimtex#log#info('Compiler started in continuous mode')
  else
    call vimtex#log#info('Compiler started in background!')
  endif
endfunction

" }}}1
function! vimtex#compiler#stop() abort " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  if !b:vimtex.compiler.is_running()
    call vimtex#log#warning(
          \ 'There is no process to stop (' . b:vimtex.base . ')')
    return
  endif

  call b:vimtex.compiler.stop()

  if g:vimtex_compiler_silent | return | endif
  call vimtex#log#info('Compiler stopped (' . b:vimtex.base . ')')
endfunction

" }}}1
function! vimtex#compiler#stop_all() abort " {{{1
  for l:state in vimtex#state#list_all()
    if exists('l:state.compiler.enabled')
          \ && l:state.compiler.enabled
          \ && l:state.compiler.is_running()
      call l:state.compiler.stop()
      call vimtex#log#info('Compiler stopped ('
            \ . l:state.compiler.file_info.target_basename . ')')
    endif
  endfor
endfunction

" }}}1
function! vimtex#compiler#clean(full) abort " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  let l:restart = b:vimtex.compiler.is_running()
  if l:restart
    call b:vimtex.compiler.stop()
  endif


  call b:vimtex.compiler.clean(a:full)
  sleep 100m
  call b:vimtex.compiler.remove_dirs()
  call vimtex#log#info('Compiler clean finished' . (a:full ? ' (full)' : ''))


  if l:restart
    let b:vimtex.compiler.silence_next_callback = 1
    silent call b:vimtex.compiler.start()
  endif
endfunction

" }}}1
function! vimtex#compiler#status(detailed) abort " {{{1
  if !b:vimtex.compiler.enabled | return | endif

  if a:detailed
    let l:running = []
    for l:data in vimtex#state#list_all()
      if l:data.compiler.is_running()
        let l:name = l:data.tex
        if len(l:name) >= winwidth('.') - 20
          let l:name = '...' . l:name[-winwidth('.')+23:]
        endif
        call add(l:running, printf('%-6s %s',
              \ string(l:data.compiler.get_pid()) . ':', l:name))
      endif
    endfor

    if empty(l:running)
      call vimtex#log#info('Compiler is not running!')
    else
      call vimtex#log#info('Compiler is running', l:running)
    endif
  else
    if exists('b:vimtex.compiler')
          \ && b:vimtex.compiler.is_running()
      call vimtex#log#info('Compiler is running')
    else
      call vimtex#log#info('Compiler is not running!')
    endif
  endif
endfunction

" }}}1


function! s:init_compiler(options) abort " {{{1
  if type(g:vimtex_compiler_method) == v:t_func
        \ || exists('*' . g:vimtex_compiler_method)
    let l:method = call(g:vimtex_compiler_method, [a:options.file_info.target])
  else
    let l:method = g:vimtex_compiler_method
  endif

  if index([
        \ 'arara',
        \ 'generic',
        \ 'latexmk',
        \ 'latexrun',
        \ 'tectonic',
        \ 'texpresso',
        \], l:method) < 0
    call vimtex#log#error('Error! Invalid compiler method: ' . l:method)
    let l:method = 'latexmk'
  endif

  let l:options = extend(
        \ deepcopy(get(g:, 'vimtex_compiler_' . l:method, {})),
        \ a:options)
  return vimtex#compiler#{l:method}#init(l:options)
endfunction

" }}}1


let s:output_factory = {}
function! s:output_factory.create(file) dict abort " {{{1
  let l:vimtex = b:vimtex
  silent execute 'split' a:file
  let b:vimtex = l:vimtex

  setlocal autoread
  setlocal nomodifiable
  setlocal bufhidden=wipe

  nnoremap <silent><buffer><nowait> q :bwipeout<cr>
  if has('nvim') || has('gui_running')
    nnoremap <silent><buffer><nowait> <esc> :bwipeout<cr>
  endif

  let s:output = deepcopy(self)
  unlet s:output.create

  let s:output.name = a:file
  let s:output.ftime = -1
  let s:output.paused = v:false
  let s:output.bufnr = bufnr('%')
  let s:output.winnr = bufwinnr('%')
  let s:output.timer = timer_start(100,
        \ {_ -> s:output.update()},
        \ {'repeat': -1})

  augroup vimtex_output_window
    autocmd!
    autocmd BufDelete <buffer> call s:output.destroy()
    autocmd BufEnter     *     call s:output.update()
    autocmd FocusGained  *     call s:output.update()
    autocmd CursorHold   *     call s:output.update()
    autocmd CursorHoldI  *     call s:output.update()
    autocmd CursorMoved  *     call s:output.update()
    autocmd CursorMovedI *     call s:output.update()
  augroup END
endfunction

" }}}1
function! s:output_factory.pause() dict abort " {{{1
  let self.paused = v:true
endfunction

" }}}1
function! s:output_factory.resume() dict abort " {{{1
  let self.paused = v:false
endfunction

" }}}1
function! s:output_factory.update() dict abort " {{{1
  if self.paused | return | endif

  let l:ftime = getftime(self.name)
  if self.ftime >= l:ftime
        \ || mode() ==? 'v' || mode() ==# "\<c-v>"
    return
  endif
  let self.ftime = getftime(self.name)

  if bufwinnr(self.name) != self.winnr
    let self.winnr = bufwinnr(self.name)
  endif

  let l:swap = bufwinnr('%') != self.winnr
  if l:swap
    let l:return = bufwinnr('%')
    execute 'keepalt' self.winnr . 'wincmd w'
  endif

  " Force reload file content
  silent edit

  if l:swap
    " Go to last line of file if it is not the current window
    normal! Gzb
    execute 'keepalt' l:return . 'wincmd w'
    redraw
  endif
endfunction

" }}}1
function! s:output_factory.destroy() dict abort " {{{1
  call timer_stop(self.timer)
  autocmd! vimtex_output_window
  augroup! vimtex_output_window
  unlet s:output
endfunction

" }}}1


" {{{1 Initialize module

if !get(g:, 'vimtex_compiler_enabled') | finish | endif

augroup vimtex_compiler
  autocmd!
  autocmd VimLeave * call vimtex#compiler#stop_all()
augroup END

" }}}1
