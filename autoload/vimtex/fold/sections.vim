" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#sections#new(config) abort " {{{1
  return extend(deepcopy(s:folder), a:config).init()
endfunction

" }}}1


let s:folder = {
      \ 'name' : 'sections',
      \ 'parse_levels' : 0,
      \ 're' : {},
      \ 'folds' : [],
      \ 'sections' : [],
      \ 'parts' : [],
      \ 'time' : 0,
      \}
function! s:folder.init() abort dict " {{{1
  let self.re.parts = '\v^\s*\\%(' . join(self.parts, '|') . ')'
  let self.re.sections = '\v^\s*\\%(' . join(self.sections, '|') . ')'
  let self.re.fake_sections = '\v^\s*\% Fake%('
        \ . join(self.sections, '|') . ').*'
  let self.re.any_sections = '\v^\s*%(\\|\% Fake)%('
        \ . join(self.sections, '|') . ').*'

  let self.re.start = self.re.parts
        \ . '|' . self.re.sections
        \ . '|' . self.re.fake_sections

  let self.re.secpat1 = self.re.sections . '\*?\s*\{\zs.*'
  let self.re.secpat2 = self.re.sections . '\*?\s*\[\zs.*'

  let self.re.fold_re = '\\%(' .. join(self.parts + self.sections, '|') .. ')'
  let self.re.fold_re_comment = '^\s*\% Fake'

  return self
endfunction

" }}}1
function! s:folder.level(line, lnum) abort dict " {{{1
  call self.refresh()

  " Fold chapters and sections
  for [l:part, l:level] in self.folds
    if a:line =~# l:part
      return '>' . l:level
    endif
  endfor
endfunction

" }}}1
function! s:folder.text(line, level) abort dict " {{{1
  if a:line =~# '\\frontmatter'
    let l:title = 'Frontmatter'
  elseif a:line =~# '\\mainmatter'
    let l:title = 'Mainmatter'
  elseif a:line =~# '\\backmatter'
    let l:title = 'Backmatter'
  elseif a:line =~# '\\appendix'
    let l:title = 'Appendix'
  elseif a:line =~# self.re.secpat1
    let l:title = s:parse_title(a:line, self.re.secpat1, '{')
  elseif a:line =~# self.re.secpat2
    let l:title = s:parse_title(a:line, self.re.secpat2, '[')
  elseif a:line =~# self.re.fake_sections
    let l:title = matchstr(a:line, self.re.fake_sections)
  endif

  let l:level = self.parse_level(v:foldstart, a:level)

  return printf('%-5s %-s', l:level,
        \ substitute(strpart(l:title, 0, winwidth(0) - 7), '\s\+$', '', ''))
endfunction

" }}}1
function! s:folder.parse_level(lnum, level) abort dict " {{{1
  if !self.parse_levels | return a:level | endif

  if !has_key(self, 'toc')
    let self.toc = vimtex#toc#new({
        \ 'name' : 'Fold text ToC',
        \ 'layers' : ['content'],
        \ 'refresh_always' : 0,
        \})
    let self.toc_updated = 0
    let self.file_updated = {}
  endif

  let l:file = expand('%')
  let l:ftime = getftime(l:file)

  if l:ftime > get(self.file_updated, l:file)
        \ || localtime() > self.toc_updated + 300
    call self.toc.get_entries(1)
    let self.toc_entries = filter(
          \ self.toc.get_visible_entries(),
          \ '!empty(v:val.number)')
    let self.file_updated[l:file] = l:ftime
    let self.toc_updated = localtime()
  endif

  let l:entries = filter(deepcopy(self.toc_entries), 'v:val.line == a:lnum')
  if len(l:entries) > 1
    call filter(l:entries, "v:val.file ==# expand('%:p')")
  endif

  return empty(l:entries) ? '' : self.toc.print_number(l:entries[0].number)
endfunction

" }}}1
function! s:folder.refresh() abort dict " {{{1
  "
  " Parse current buffer to find which sections to fold and their levels.  The
  " patterns are predefined to optimize the folding.
  "
  " We ignore top level parts such as \frontmatter, \appendix, \part, and
  " similar, unless there are at least two such commands in a document.
  "

  " Only refresh if file has been changed
  let l:time = getftime(expand('%'))
  if l:time == self.time | return | endif
  let self.time = l:time

  " Initialize
  let self.folds = []
  let level = 0
  let buffer = getline(1,'$')

  " Parse part commands (frontmatter, appendix, etc)
  " Note: We want a minimum of two top level parts
  let lines = filter(copy(buffer), {_, x -> x =~# self.re.parts})
  if len(lines) >= 2
    let level += 1
    call insert(self.folds, [self.re.parts, level])
  endif

  " Parse section commands (part, chapter, [sub...]section)
  let lines = filter(copy(buffer), {_, x -> x =~# self.re.any_sections})
  for part in self.sections
    let partpattern = '\v^\s*%(\\|\% Fake)' . part . ':?>'
    for line in lines
      if line =~# partpattern
        let level += 1
        call insert(self.folds, [partpattern, level])
        break
      endif
    endfor
  endfor
endfunction

" }}}1

function! s:parse_title(line, re, type) abort " {{{1
  let l:title = matchstr(a:line, a:re)
  let [l:end, l:depth] = vimtex#parser#tex#find_closing(
        \ 0, l:title, 1, a:type)

  let l:lnum = v:foldstart
  while l:depth > 0 && l:lnum <= v:foldend
    let l:lnum += 1
    let l:start = strlen(l:title)
    let l:title .= getline(l:lnum)
    let [l:end, l:depth] = vimtex#parser#tex#find_closing(
          \ l:start, l:title, l:depth, a:type)
  endwhile

  if l:depth == 0
    let l:title = strpart(l:title, 0, l:end)
  endif

  let l:title = substitute(l:title, '^\s*', '', '')
  let l:title = substitute(l:title, '\s\{2,}', ' ', 'g')
  return vimtex#parser#tex#texorpdfstring(l:title)
endfunction

" }}}1
