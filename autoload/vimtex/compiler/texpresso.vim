" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#texpresso#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_template#new({
      \ 'name' : 'texpresso',
      \ 'continuous': 1,
      \ 'options' : [
      \   '-json',
      \   '-lines'
      \ ],
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  if !executable('texpresso')
    call vimtex#log#warning('texpresso is not executable!')
    let self.enabled = v:false
  endif
endfunction
" }}}1

function! s:compiler.__init() abort dict " {{{1
  let self.start = function('s:compiler_start', [self.start])
  let self.stop = function('s:compiler_stop', [self.stop])
  call add(self.hooks, function('s:texpresso_process_message'))
endfunction
" }}}1

function! s:compiler.__build_cmd(passed_options) abort dict " {{{1
  return 'texpresso ' . join(self.options)
        \ . ' ' . vimtex#util#shellescape(self.file_info.target_basename)
endfunction
" }}}1

if has('nvim')
  let s:nvim_attach = luaeval('
    \ function()
    \   local stopped = false
    \   vim.api.nvim_buf_attach(0, false, {
    \     on_lines = function(e, buf, _tick, first, oldlast, newlast)
    \       if stopped then
    \         return true
    \       end
    \       local path = vim.api.nvim_buf_get_name(buf)
    \       local count = oldlast - first
    \       local lines = ""
    \       if first < newlast then
    \         lines = table.concat(vim.api.nvim_buf_get_lines(buf, first, newlast, false), "\n") .. "\n"
    \       end
    \       local msg = vim.json.encode({"change-lines", path, first, count, lines})
    \       vim.fn.chansend(vim.b[buf].vimtex.compiler.job, {msg, ""})
    \     end
    \   })
    \  return function() stopped = true end
    \ end')
endif

function! s:compiler_start(super, ...) abort dict " {{{1
  call call(a:super, a:000, self)

  augroup vimtex_compiler_texpresso
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call b:vimtex.compiler.texpresso_synctex_forward()
    autocmd ColorScheme <buffer> call b:vimtex.compiler.texpresso_theme()
  augroup END

  if has('nvim')
    let self.nvim_detach = s:nvim_attach()
  else
    let self.listener_id = listener_add(function(self.texpresso_listener, [], self))
  endif

  call self.texpresso_theme()
  call self.texpresso_reload()
endfunction
" }}}1

function! s:compiler_stop(super, ...) abort dict " {{{1
  call call(a:super, a:000, self)
  if has('nvim')
    call self.nvim_detach()
    unlet self.nvim_detach
  else
    call listener_remove(self.listener_id)
    unlet self.listener_id
  endif

  autocmd! vimtex_compiler_texpresso * <buffer>
endfunction
" }}}1

function! s:compiler.texpresso_listener(bufnr, start, end, added, changes) abort dict " {{{1
  let l:path = fnamemodify(bufname(a:bufnr), ":p")
  let l:lines = getbufline(a:bufnr, a:start, a:end - 1 + a:added)
  call self.texpresso_send("change-lines", l:path, a:start - 1, a:end - a:start,  s:join_lines(l:lines))
endfunction
" }}}1

function! s:compiler.texpresso_theme() abort dict " {{{1
  let l:normal_id = synIDtrans(hlID('Normal'))
  let l:fg = synIDattr(l:normal_id, 'fg#')
  let l:bg = synIDattr(l:normal_id, 'bg#')
  
  if l:fg ==# '' || l:bg ==# ''
    return
  endif

  call self.texpresso_send("theme", s:convert_color(l:bg), s:convert_color(l:fg))
endfunction
" }}}1

function! s:compiler.texpresso_reload() abort dict " {{{1
  let l:path = fnamemodify(bufname(), ":p")
  call self.texpresso_send("open", l:path, s:join_lines(getline(1, '$')))
endfunction
" }}}1

function! s:compiler.texpresso_synctex_forward() abort dict "{{{1
  let l:path = fnamemodify(bufname(), ":p")
  let l:lnum = getpos('.')[1]
  let l:prev_key = 'texpresso_synctex_forward_previous'
  if has_key(self, l:prev_key) && self[l:prev_key] == [l:path, l:lnum]
    return
  endif
  let self.texpresso_synctex_forward_previous = [l:path, l:lnum]
  call self.texpresso_send("synctex-forward", l:path, l:lnum)
endfunction
" }}}1

function! s:compiler.texpresso_previous_page() abort dict "{{{1
  call self.texpresso_send("previous-page")
endfunction
"}}}1

function! s:compiler.texpresso_next_page() abort dict "{{{1
  call self.texpresso_send("next-page")
endfunction
"}}}1

function! s:compiler.texpresso_send(...) abort dict " {{{1
  if !self.is_running() | return | endif
  if has('nvim')
    call chansend(self.job, json_encode(a:000) .. "\n")
  else
    call ch_sendraw(self.job, json_encode(a:000) .. "\n")
  endif
endfunction
" }}}1

function! s:texpresso_process_message(json) abort " {{{1
  try
    let l:msg = json_decode(a:json)
  catch
    " FIXME: hooks receive messages from both stdout and stderr, so
    " sometimes parsing can fail.
    return
  endtry

  if type(l:msg) != v:t_list || empty(l:msg)
    return
  endif

  " echom l:msg

  if l:msg[0] ==# 'synctex'
    let l:path = l:msg[1]
    let l:lnum = l:msg[2]
    call vimtex#view#inverse_search(l:lnum, l:path)
  elseif l:msg[0] ==# 'truncate-lines'
    let l:name = l:msg[1]
    let l:count = l:msg[2]
    if name ==# 'out'
      call setqflist(slice(getqflist(), 0, l:count), 'r')
    endif
  elseif l:msg[0] ==# 'append-lines'
    let l:name = l:msg[1]
    let l:lines = l:msg[2:]
    if name ==# 'out'
      call setqflist([], 'a', { 'lines': l:lines, 'efm': '%t%*[^:]: %f:%l: %m' })
    endif
  elseif l:msg[0] ==# 'flush'
  else
    " TODO: handle other types of messages
  endif
endfunction

" }}}1

function s:join_lines(lines) abort " {{{1
  return a:lines == [] ? '' : join(a:lines, "\n") .. "\n"
endfunction

" }}}1

function s:convert_color(color) abort " {{{1
  let l:color = get(s:to_HEX, a:color, a:color)
  let l:r = str2nr(l:color[1:2], 16) 
  let l:g = str2nr(l:color[3:4], 16)
  let l:b = str2nr(l:color[5:6], 16)
  return [l:r / 255.0, l:g / 255.0, l:b / 255.0]
endfunction

" }}}1


let s:to_HEX = {
      \ '00':  '#000000',  '01':  '#800000',  '02':  '#008000',  '03':  '#808000',  '04':  '#000080',
      \ '05':  '#800080',  '06':  '#008080',  '07':  '#c0c0c0',  '08':  '#808080',  '09':  '#ff0000',
      \ '10':  '#00ff00',  '11':  '#ffff00',  '12':  '#0000ff',  '13':  '#ff00ff',  '14':  '#00ffff',
      \ '15':  '#ffffff',  '16':  '#000000',  '17':  '#00005f',  '18':  '#000087',  '19':  '#0000af',
      \ '20':  '#0000d7',  '21':  '#0000ff',  '22':  '#005f00',  '23':  '#005f5f',  '24':  '#005f87',
      \ '25':  '#005faf',  '26':  '#005fd7',  '27':  '#005fff',  '28':  '#008700',  '29':  '#00875f',
      \ '30':  '#008787',  '31':  '#0087af',  '32':  '#0087d7',  '33':  '#0087ff',  '34':  '#00af00',
      \ '35':  '#00af5f',  '36':  '#00af87',  '37':  '#00afaf',  '38':  '#00afd7',  '39':  '#00afff',
      \ '40':  '#00d700',  '41':  '#00d75f',  '42':  '#00d787',  '43':  '#00d7af',  '44':  '#00d7d7',
      \ '45':  '#00d7ff',  '46':  '#00ff00',  '47':  '#00ff5f',  '48':  '#00ff87',  '49':  '#00ffaf',
      \ '50':  '#00ffd7',  '51':  '#00ffff',  '52':  '#5f0000',  '53':  '#5f005f',  '54':  '#5f0087',
      \ '55':  '#5f00af',  '56':  '#5f00d7',  '57':  '#5f00ff',  '58':  '#5f5f00',  '59':  '#5f5f5f',
      \ '60':  '#5f5f87',  '61':  '#5f5faf',  '62':  '#5f5fd7',  '63':  '#5f5fff',  '64':  '#5f8700',
      \ '65':  '#5f875f',  '66':  '#5f8787',  '67':  '#5f87af',  '68':  '#5f87d7',  '69':  '#5f87ff',
      \ '70':  '#5faf00',  '71':  '#5faf5f',  '72':  '#5faf87',  '73':  '#5fafaf',  '74':  '#5fafd7',
      \ '75':  '#5fafff',  '76':  '#5fd700',  '77':  '#5fd75f',  '78':  '#5fd787',  '79':  '#5fd7af',
      \ '80':  '#5fd7d7',  '81':  '#5fd7ff',  '82':  '#5fff00',  '83':  '#5fff5f',  '84':  '#5fff87',
      \ '85':  '#5fffaf',  '86':  '#5fffd7',  '87':  '#5fffff',  '88':  '#870000',  '89':  '#87005f',
      \ '90':  '#870087',  '91':  '#8700af',  '92':  '#8700d7',  '93':  '#8700ff',  '94':  '#875f00',
      \ '95':  '#875f5f',  '96':  '#875f87',  '97':  '#875faf',  '98':  '#875fd7',  '99':  '#875fff',
      \ '100': '#878700',  '101': '#87875f',  '102': '#878787',  '103': '#8787af',  '104': '#8787d7',
      \ '105': '#8787ff',  '106': '#87af00',  '107': '#87af5f',  '108': '#87af87',  '109': '#87afaf',
      \ '110': '#87afd7',  '111': '#87afff',  '112': '#87d700',  '113': '#87d75f',  '114': '#87d787',
      \ '115': '#87d7af',  '116': '#87d7d7',  '117': '#87d7ff',  '118': '#87ff00',  '119': '#87ff5f',
      \ '120': '#87ff87',  '121': '#87ffaf',  '122': '#87ffd7',  '123': '#87ffff',  '124': '#af0000',
      \ '125': '#af005f',  '126': '#af0087',  '127': '#af00af',  '128': '#af00d7',  '129': '#af00ff',
      \ '130': '#af5f00',  '131': '#af5f5f',  '132': '#af5f87',  '133': '#af5faf',  '134': '#af5fd7',
      \ '135': '#af5fff',  '136': '#af8700',  '137': '#af875f',  '138': '#af8787',  '139': '#af87af',
      \ '140': '#af87d7',  '141': '#af87ff',  '142': '#afaf00',  '143': '#afaf5f',  '144': '#afaf87',
      \ '145': '#afafaf',  '146': '#afafd7',  '147': '#afafff',  '148': '#afd700',  '149': '#afd75f',
      \ '150': '#afd787',  '151': '#afd7af',  '152': '#afd7d7',  '153': '#afd7ff',  '154': '#afff00',
      \ '155': '#afff5f',  '156': '#afff87',  '157': '#afffaf',  '158': '#afffd7',  '159': '#afffff',
      \ '160': '#d70000',  '161': '#d7005f',  '162': '#d70087',  '163': '#d700af',  '164': '#d700d7',
      \ '165': '#d700ff',  '166': '#d75f00',  '167': '#d75f5f',  '168': '#d75f87',  '169': '#d75faf',
      \ '170': '#d75fd7',  '171': '#d75fff',  '172': '#d78700',  '173': '#d7875f',  '174': '#d78787',
      \ '175': '#d787af',  '176': '#d787d7',  '177': '#d787ff',  '178': '#d7af00',  '179': '#d7af5f',
      \ '180': '#d7af87',  '181': '#d7afaf',  '182': '#d7afd7',  '183': '#d7afff',  '184': '#d7d700',
      \ '185': '#d7d75f',  '186': '#d7d787',  '187': '#d7d7af',  '188': '#d7d7d7',  '189': '#d7d7ff',
      \ '190': '#d7ff00',  '191': '#d7ff5f',  '192': '#d7ff87',  '193': '#d7ffaf',  '194': '#d7ffd7',
      \ '195': '#d7ffff',  '196': '#ff0000',  '197': '#ff005f',  '198': '#ff0087',  '199': '#ff00af',
      \ '200': '#ff00d7',  '201': '#ff00ff',  '202': '#ff5f00',  '203': '#ff5f5f',  '204': '#ff5f87',
      \ '205': '#ff5faf',  '206': '#ff5fd7',  '207': '#ff5fff',  '208': '#ff8700',  '209': '#ff875f',
      \ '210': '#ff8787',  '211': '#ff87af',  '212': '#ff87d7',  '213': '#ff87ff',  '214': '#ffaf00',
      \ '215': '#ffaf5f',  '216': '#ffaf87',  '217': '#ffafaf',  '218': '#ffafd7',  '219': '#ffafff',
      \ '220': '#ffd700',  '221': '#ffd75f',  '222': '#ffd787',  '223': '#ffd7af',  '224': '#ffd7d7',
      \ '225': '#ffd7ff',  '226': '#ffff00',  '227': '#ffff5f',  '228': '#ffff87',  '229': '#ffffaf',
      \ '230': '#ffffd7',  '231': '#ffffff',  '232': '#080808',  '233': '#121212',  '234': '#1c1c1c',
      \ '235': '#262626',  '236': '#303030',  '237': '#3a3a3a',  '238': '#444444',  '239': '#4e4e4e',
      \ '240': '#585858',  '241': '#626262',  '242': '#6c6c6c',  '243': '#767676',  '244': '#808080',
      \ '245': '#8a8a8a',  '246': '#949494',  '247': '#9e9e9e',  '248': '#a8a8a8',  '249': '#b2b2b2',
      \ '250': '#bcbcbc',  '251': '#c6c6c6',  '252': '#d0d0d0',  '253': '#dadada',  '254': '#e4e4e4',
      \ '255': '#eeeeee' }
