" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#options#init() abort " {{{1
  if s:initialized | return | endif

  call s:init_highlights()
  call s:check_for_deprecated_options()

  call s:init_option('vimtex_bibliography_commands', [
        \ '%(no)?bibliography',
        \ 'add%(bibresource|globalbib|sectionbib)',
        \])

  call s:init_option('vimtex_compiler_enabled', 1)
  call s:init_option('vimtex_compiler_silent', 0)
  call s:init_option('vimtex_compiler_method', 'latexmk')
  call s:init_option('vimtex_compiler_clean_paths', [])
  call s:init_option('vimtex_compiler_latexmk_engines', {
        \  '_'                : '-pdf',
        \  'pdfdvi'           : '-pdfdvi',
        \  'pdfps'            : '-pdfps',
        \  'pdflatex'         : '-pdf',
        \  'luatex'           : '-lualatex',
        \  'lualatex'         : '-lualatex',
        \  'xelatex'          : '-xelatex',
        \  'context (pdftex)' : '-pdf -pdflatex=texexec',
        \  'context (luatex)' : '-pdf -pdflatex=context',
        \  'context (xetex)'  : '-pdf -pdflatex=''texexec --xtx''',
        \ })
  call s:init_option('vimtex_compiler_latexrun_engines', {
        \ '_'        : 'pdflatex',
        \ 'pdflatex' : 'pdflatex',
        \ 'lualatex' : 'lualatex',
        \ 'xelatex'  : 'xelatex',
        \})

  call s:init_option('vimtex_complete_enabled', 1)
  call s:init_option('vimtex_complete_close_braces', 0)
  call s:init_option('vimtex_complete_ignore_case', &ignorecase)
  call s:init_option('vimtex_complete_smart_case', &smartcase)
  call s:init_option('vimtex_complete_bib', {
        \ 'simple': 0,
        \ 'match_str_fmt': '@key [@type] @author_all (@year), "@title"',
        \ 'menu_fmt': '[@type] @author_short (@year), "@title"',
        \ 'info_fmt': "TITLE: @title\nAUTHOR: @author_all\nYEAR: @year",
        \ 'abbr_fmt': '',
        \ 'auth_len': 20,
        \ 'custom_patterns': [],
        \})
  call s:init_option('vimtex_complete_ref', {
        \ 'custom_patterns': [],
        \})

  let l:viewer = get(g:, 'vimtex_view_method', 'general')
  if l:viewer ==# 'general'
    let l:viewer = 'NONE'
  endif
  call s:init_option('vimtex_context_pdf_viewer', l:viewer)

  call s:init_option('vimtex_delim_timeout', 300)
  call s:init_option('vimtex_delim_insert_timeout', 60)
  call s:init_option('vimtex_delim_stopline', 500)

  call s:init_option('vimtex_include_search_enabled', 1)

  call s:init_option('vimtex_doc_enabled', 1)
  call s:init_option('vimtex_doc_confirm_single', v:true)
  call s:init_option('vimtex_doc_handlers', [])

  call s:init_option('vimtex_echo_verbose_input', 1)

  call s:init_option('vimtex_env_change_autofill', 0)
  call s:init_option('vimtex_env_toggle_map', {
        \ 'itemize': 'enumerate',
        \ 'enumerate': 'itemize',
        \})
  call s:init_option('vimtex_env_toggle_math_map', {
        \ '$': '\[',
        \ '\[': 'equation',
        \ '$$': '\[',
        \ '\(': '$',
        \})

  if &diff
    let g:vimtex_fold_enabled = 0
    let g:vimtex_fold_bib_enabled = 0
  else
    call s:init_option('vimtex_fold_enabled', 0)
    call s:init_option('vimtex_fold_bib_enabled', g:vimtex_fold_enabled)
  endif
  call s:init_option('vimtex_fold_bib_max_key_width', 0)
  call s:init_option('vimtex_fold_manual', 0)
  call s:init_option('vimtex_fold_levelmarker', '*')
  call s:init_option('vimtex_fold_types', {})
  call s:init_option('vimtex_fold_types_defaults', {
        \ 'preamble' : {},
        \ 'items' : {},
        \ 'comment_pkg' : {},
        \ 'comments' : { 'enabled' : 0 },
        \ 'envs' : {
        \   'blacklist' : [],
        \   'whitelist' : [],
        \ },
        \ 'env_options' : {},
        \ 'markers' : {},
        \ 'sections' : {
        \   'parse_levels' : 0,
        \   'sections' : [
        \     '%(add)?part',
        \     '%(chapter|addchap)',
        \     '%(section|addsec)',
        \     'subsection',
        \     'subsubsection',
        \   ],
        \   'parts' : [
        \     'appendix',
        \     'frontmatter',
        \     'mainmatter',
        \     'backmatter',
        \   ],
        \ },
        \ 'cmd_single' : {
        \   'cmds' : [
        \     'hypersetup',
        \     'tikzset',
        \     'pgfplotstableread',
        \     'lstset',
        \   ],
        \ },
        \ 'cmd_single_opt' : {
        \   'cmds' : [
        \     'usepackage',
        \     'includepdf',
        \   ],
        \ },
        \ 'cmd_multi' : {
        \   'cmds' : [
        \     '%(re)?new%(command|environment)',
        \     'providecommand',
        \     'presetkeys',
        \     'Declare%(Multi|Auto)?CiteCommand',
        \     'Declare%(Index)?%(Field|List|Name)%(Format|Alias)',
        \   ],
        \ },
        \ 'cmd_addplot' : {
        \   'cmds' : [
        \     'addplot[+3]?',
        \   ],
        \ },
        \})

  call s:init_option('vimtex_format_enabled', 0)
  call s:init_option('vimtex_format_border_begin', '\v^\s*%(' . join([
        \ '\\item',
        \ '\\begin',
        \ '\\end',
        \ '%(\\\[|\$\$)\s*$',
        \], '|') . ')')
  call s:init_option('vimtex_format_border_end', '\v\\%(' . join([
        \ '\\\*?',
        \ 'clear%(double)?page',
        \ 'linebreak',
        \ 'new%(line|page)',
        \ 'pagebreak',
        \ '%(begin|end)\{[^}]*\}',
        \], '|') . ')\s*$' . '|^\s*%(\\\]|\$\$)\s*$')

  call s:init_option('vimtex_grammar_textidote', {
        \ 'jar': '',
        \ 'args': '',
        \})
  call s:init_option('vimtex_grammar_vlty', {
        \ 'lt_directory': '~/lib/LanguageTool',
        \ 'lt_command': '',
        \ 'lt_disable': 'WHITESPACE_RULE',
        \ 'lt_enable': '',
        \ 'lt_disablecategories': '',
        \ 'lt_enablecategories': '',
        \ 'server': 'no',
        \ 'shell_options': '',
        \ 'show_suggestions': 0,
        \ 'encoding': 'auto',
        \})

  call s:init_option('vimtex_imaps_enabled', 1)
  call s:init_option('vimtex_imaps_disabled', [])
  call s:init_option('vimtex_imaps_leader', '`')
  call s:init_option('vimtex_imaps_list', [
        \ { 'lhs' : '0',  'rhs' : '\emptyset' },
        \ { 'lhs' : '2',  'rhs' : '\sqrt' },
        \ { 'lhs' : '6',  'rhs' : '\partial' },
        \ { 'lhs' : '8',  'rhs' : '\infty' },
        \ { 'lhs' : '=',  'rhs' : '\equiv' },
        \ { 'lhs' : '\',  'rhs' : '\setminus' },
        \ { 'lhs' : '.',  'rhs' : '\cdot' },
        \ { 'lhs' : '*',  'rhs' : '\times' },
        \ { 'lhs' : '<',  'rhs' : '\langle' },
        \ { 'lhs' : '>',  'rhs' : '\rangle' },
        \ { 'lhs' : 'H',  'rhs' : '\hbar' },
        \ { 'lhs' : '+',  'rhs' : '\dagger' },
        \ { 'lhs' : '[',  'rhs' : '\subseteq' },
        \ { 'lhs' : ']',  'rhs' : '\supseteq' },
        \ { 'lhs' : '(',  'rhs' : '\subset' },
        \ { 'lhs' : ')',  'rhs' : '\supset' },
        \ { 'lhs' : 'A',  'rhs' : '\forall' },
        \ { 'lhs' : 'B',  'rhs' : '\boldsymbol' },
        \ { 'lhs' : 'E',  'rhs' : '\exists' },
        \ { 'lhs' : 'N',  'rhs' : '\nabla' },
        \ { 'lhs' : 'jj', 'rhs' : '\downarrow' },
        \ { 'lhs' : 'jJ', 'rhs' : '\Downarrow' },
        \ { 'lhs' : 'jk', 'rhs' : '\uparrow' },
        \ { 'lhs' : 'jK', 'rhs' : '\Uparrow' },
        \ { 'lhs' : 'jh', 'rhs' : '\leftarrow' },
        \ { 'lhs' : 'jH', 'rhs' : '\Leftarrow' },
        \ { 'lhs' : 'jl', 'rhs' : '\rightarrow' },
        \ { 'lhs' : 'jL', 'rhs' : '\Rightarrow' },
        \ { 'lhs' : 'a',  'rhs' : '\alpha' },
        \ { 'lhs' : 'b',  'rhs' : '\beta' },
        \ { 'lhs' : 'c',  'rhs' : '\chi' },
        \ { 'lhs' : 'd',  'rhs' : '\delta' },
        \ { 'lhs' : 'e',  'rhs' : '\epsilon' },
        \ { 'lhs' : 'f',  'rhs' : '\phi' },
        \ { 'lhs' : 'g',  'rhs' : '\gamma' },
        \ { 'lhs' : 'h',  'rhs' : '\eta' },
        \ { 'lhs' : 'i',  'rhs' : '\iota' },
        \ { 'lhs' : 'k',  'rhs' : '\kappa' },
        \ { 'lhs' : 'l',  'rhs' : '\lambda' },
        \ { 'lhs' : 'm',  'rhs' : '\mu' },
        \ { 'lhs' : 'n',  'rhs' : '\nu' },
        \ { 'lhs' : 'p',  'rhs' : '\pi' },
        \ { 'lhs' : 'q',  'rhs' : '\theta' },
        \ { 'lhs' : 'r',  'rhs' : '\rho' },
        \ { 'lhs' : 's',  'rhs' : '\sigma' },
        \ { 'lhs' : 't',  'rhs' : '\tau' },
        \ { 'lhs' : 'y',  'rhs' : '\psi' },
        \ { 'lhs' : 'u',  'rhs' : '\upsilon' },
        \ { 'lhs' : 'w',  'rhs' : '\omega' },
        \ { 'lhs' : 'z',  'rhs' : '\zeta' },
        \ { 'lhs' : 'x',  'rhs' : '\xi' },
        \ { 'lhs' : 'D',  'rhs' : '\Delta' },
        \ { 'lhs' : 'F',  'rhs' : '\Phi' },
        \ { 'lhs' : 'G',  'rhs' : '\Gamma' },
        \ { 'lhs' : 'L',  'rhs' : '\Lambda' },
        \ { 'lhs' : 'P',  'rhs' : '\Pi' },
        \ { 'lhs' : 'Q',  'rhs' : '\Theta' },
        \ { 'lhs' : 'S',  'rhs' : '\Sigma' },
        \ { 'lhs' : 'U',  'rhs' : '\Upsilon' },
        \ { 'lhs' : 'W',  'rhs' : '\Omega' },
        \ { 'lhs' : 'X',  'rhs' : '\Xi' },
        \ { 'lhs' : 'Y',  'rhs' : '\Psi' },
        \ { 'lhs' : 've', 'rhs' : '\varepsilon' },
        \ { 'lhs' : 'vf', 'rhs' : '\varphi' },
        \ { 'lhs' : 'vk', 'rhs' : '\varkappa' },
        \ { 'lhs' : 'vp', 'rhs' : '\varpi' },
        \ { 'lhs' : 'vq', 'rhs' : '\vartheta' },
        \ { 'lhs' : 'vr', 'rhs' : '\varrho' },
        \ { 'lhs' : '/',  'rhs' : 'vimtex#imaps#style_math("slashed")', 'expr' : 1, 'leader' : '#'},
        \ { 'lhs' : 'b',  'rhs' : 'vimtex#imaps#style_math("mathbf")', 'expr' : 1, 'leader' : '#'},
        \ { 'lhs' : 'f',  'rhs' : 'vimtex#imaps#style_math("mathfrak")', 'expr' : 1, 'leader' : '#'},
        \ { 'lhs' : 'c',  'rhs' : 'vimtex#imaps#style_math("mathcal")', 'expr' : 1, 'leader' : '#'},
        \ { 'lhs' : '-',  'rhs' : 'vimtex#imaps#style_math("overline")', 'expr' : 1, 'leader' : '#'},
        \ { 'lhs' : 'B',  'rhs' : 'vimtex#imaps#style_math("mathbb")', 'expr' : 1, 'leader' : '#'},
        \ { 'lhs' : g:vimtex_imaps_leader,
        \   'rhs' : repeat(g:vimtex_imaps_leader, 2),
        \   'wrapper' : 'vimtex#imaps#wrap_trivial'},
        \])

  call s:init_option('vimtex_indent_enabled', 1)
  call s:init_option('vimtex_indent_bib_enabled', 1)
  call s:init_option('vimtex_indent_tikz_commands', 1)
  call s:init_option('vimtex_indent_conditionals', {
        \ 'open': '\v%(\\newif)@<!\\if%(f>|field|name|numequal|thenelse|toggle)@!',
        \ 'else': '\\else\>',
        \ 'close': '\\fi\>',
        \})
  call s:init_option('vimtex_indent_delims', {
        \ 'open' : ['{'],
        \ 'close' : ['}'],
        \ 'close_indented' : 0,
        \ 'include_modified_math' : 1,
        \})
  call s:init_option('vimtex_indent_ignored_envs', ['document'])
  call s:init_option('vimtex_indent_lists', [
        \ 'itemize',
        \ 'description',
        \ 'enumerate',
        \ 'thebibliography',
        \])
  call s:init_option('vimtex_indent_on_ampersands', 1)

  call s:init_option('vimtex_mappings_enabled', 1)
  call s:init_option('vimtex_mappings_disable', {})
  call s:init_option('vimtex_mappings_override_existing', 0)

  call s:init_option('vimtex_mappings_prefix', '<localleader>l')

  call s:init_option('vimtex_matchparen_enabled', 1)
  call s:init_option('vimtex_motion_enabled', 1)

  call s:init_option('vimtex_labels_enabled', 1)
  call s:init_option('vimtex_labels_refresh_always', 1)


  let s:chktexrc = (empty($XDG_CONFIG_HOME)
        \ ? $HOME . '/.config'
        \ : $XDG_CONFIG_HOME) . '/chktexrc'

  call s:init_option('vimtex_lint_chktex_parameters',
        \ filereadable(s:chktexrc)
        \   ? '--localrc ' . shellescape(s:chktexrc)
        \   : '')
  call s:init_option('vimtex_lint_chktex_ignore_warnings',
        \ '-n1 -n3 -n8 -n25 -n36')

  call s:init_option('vimtex_parser_bib_backend',
        \ has('nvim') ? 'lua' : 'bibtex'
        \)
  call s:init_option('vimtex_parser_cmd_separator_check',
        \ 'vimtex#cmd#parser_separator_check')

  call s:init_option('vimtex_quickfix_enabled', 1)
  call s:init_option('vimtex_quickfix_method', 'latexlog')
  call s:init_option('vimtex_quickfix_autojump', 0)
  call s:init_option('vimtex_quickfix_ignore_filters', [])
  call s:init_option('vimtex_quickfix_mode', 2)
  call s:init_option('vimtex_quickfix_open_on_warning', 1)
  call s:init_option('vimtex_quickfix_blgparser', {})
  call s:init_option('vimtex_quickfix_autoclose_after_keystrokes', 0)

  call s:init_option('vimtex_subfile_start_local', 0)

  call s:init_option('vimtex_syntax_enabled', 1)
  call s:init_option('vimtex_syntax_conceal', {
        \ 'accents': 1,
        \ 'ligatures': 1,
        \ 'cites': 1,
        \ 'fancy': 1,
        \ 'spacing': 1,
        \ 'greek': 1,
        \ 'math_bounds': 1,
        \ 'math_delimiters': 1,
        \ 'math_fracs': 1,
        \ 'math_super_sub': 1,
        \ 'math_symbols': 1,
        \ 'sections': 0,
        \ 'styles': 1,
        \})
  call s:init_option('vimtex_syntax_conceal_cites', {
        \ 'type': 'brackets',
        \ 'icon': '📖',
        \ 'verbose': v:true,
        \})
  call s:init_option('vimtex_syntax_conceal_disable', 0)
  call s:init_option('vimtex_syntax_custom_cmds', [])
  call s:init_option('vimtex_syntax_custom_cmds_with_concealed_delims', [])
  call s:init_option('vimtex_syntax_custom_envs', [])
  call s:init_option('vimtex_syntax_match_unicode', v:true)
  call s:init_option('vimtex_syntax_nested', {
        \ 'aliases' : {
        \   'C' : 'c',
        \   'csharp' : 'cs',
        \ },
        \ 'ignored' : {
        \   'sh' : ['shSpecial'],
        \   'bash' : ['shSpecial'],
        \   'cs' : [
        \     'csBraces',
        \   ],
        \   'haskell' : [
        \     'hsVarSym',
        \   ],
        \   'java' : [
        \     'javaError',
        \   ],
        \   'lua' : [
        \     'luaParen',
        \     'luaParenError',
        \   ],
        \   'markdown' : [
        \     'mkdNonListItemBlock',
        \   ],
        \   'python' : [
        \     'pythonEscape',
        \     'pythonBEscape',
        \     'pythonBytesEscape',
        \   ],
        \ }
        \})
  call s:init_option('vimtex_syntax_nospell_comments', 0)
  call s:init_option('vimtex_syntax_packages', {
        \ 'amsmath': {'conceal': 1, 'load': 2},
        \ 'babel': {'conceal': 1},
        \ 'hyperref': {'conceal': 1},
        \ 'fontawesome5': {'conceal': 1},
        \ 'robust_externalize': {
        \   'presets': [
        \     ['bash', 'bash'],
        \     ['python', 'python'],
        \     ['gnuplot', 'gnuplot'],
        \     ['tikz', '@texClusterTikz'],
        \     ['latex', 'TOP'],
        \   ],
        \ },
        \})

  " Disable conceals if chosen
  if g:vimtex_syntax_conceal_disable
    call map(g:vimtex_syntax_conceal, {k, v -> 0})
    let g:vimtex_syntax_packages.amsmath.conceal = 0
    let g:vimtex_syntax_packages.babel.conceal = 0
    let g:vimtex_syntax_packages.hyperref.conceal = 0
    let g:vimtex_syntax_packages.fontawesome5.conceal = 0
  endif

  call s:init_option('vimtex_texcount_custom_arg', '')

  call s:init_option('vimtex_text_obj_enabled', 1)
  call s:init_option('vimtex_text_obj_variant', 'auto')
  call s:init_option('vimtex_text_obj_linewise_operators', ['d', 'y'])

  call s:init_option('vimtex_toc_enabled', 1)
  call s:init_option('vimtex_toc_config', {
        \ 'name' : 'Table of contents (VimTeX)',
        \ 'mode' : 1,
        \ 'fold_enable' : 0,
        \ 'fold_level_start' : -1,
        \ 'hide_line_numbers' : 1,
        \ 'hotkeys_enabled' : 0,
        \ 'hotkeys' : 'abcdeilmnopuvxyz',
        \ 'hotkeys_leader' : ';',
        \ 'indent_levels' : 0,
        \ 'layer_status' : {
        \   'content': 1,
        \   'label': 1,
        \   'todo': 1,
        \   'include': 1,
        \ },
        \ 'layer_keys' : {
        \   'content': 'C',
        \   'label': 'L',
        \   'todo': 'T',
        \   'include': 'I',
        \ },
        \ 'resize' : 0,
        \ 'refresh_always' : 1,
        \ 'show_help' : 1,
        \ 'show_numbers' : 1,
        \ 'split_pos' : 'vert leftabove',
        \ 'split_width' : 50,
        \ 'tocdepth' : 3,
        \ 'todo_sorted' : 1,
        \})
  call s:init_option('vimtex_toc_config_matchers', {})
  call s:init_option('vimtex_toc_custom_matchers', [])
  call s:init_option('vimtex_toc_show_preamble', 1)
  call s:init_option('vimtex_toc_todo_labels', {
        \ 'TODO': 'TODO: ',
        \ 'FIXME': 'FIXME: '
        \})

  call s:init_option('vimtex_toggle_fractions', {
        \ 'INLINE': 'frac',
        \ 'frac': 'INLINE',
        \ 'dfrac': 'INLINE',
        \})

  call s:init_option('vimtex_ui_method', {
        \ 'confirm': has('nvim') ? 'nvim' : 'legacy',
        \ 'input': has('nvim') ? 'nvim' : 'legacy',
        \ 'select': has('nvim') ? 'nvim' : 'legacy',
        \})

  call s:init_option('vimtex_view_enabled', 1)
  call s:init_option('vimtex_view_automatic', 1)
  call s:init_option('vimtex_view_method', 'general')
  call s:init_option('vimtex_view_use_temp_files', v:false)
  call s:init_option('vimtex_view_forward_search_on_start', 1)
  call s:init_option('vimtex_view_reverse_search_edit_cmd', 'edit')

  " OS dependent defaults
  let l:os = vimtex#util#get_os()
  if l:os ==# 'win'
    if executable('SumatraPDF')
      call s:init_option('vimtex_view_general_viewer', 'SumatraPDF')
      call s:init_option('vimtex_view_general_options',
            \ '-reuse-instance -forward-search @tex @line @pdf')
    elseif executable('mupdf')
      call s:init_option('vimtex_view_general_viewer', 'mupdf')
      call s:init_option('vimtex_view_general_options', '@pdf')
    else
      call s:init_option('vimtex_view_general_viewer', 'start ""')
      call s:init_option('vimtex_view_general_options', '@pdf')
    endif
  else
    call s:init_option('vimtex_view_general_viewer', get({
          \ 'linux' : 'xdg-open',
          \ 'mac'   : 'open',
          \}, l:os, ''))
    call s:init_option('vimtex_view_general_options', '@pdf')
  endif

  call s:init_option('vimtex_view_mupdf_options', '')
  call s:init_option('vimtex_view_mupdf_send_keys', '')
  call s:init_option('vimtex_view_sioyek_exe', 'sioyek')
  call s:init_option('vimtex_view_sioyek_options', '')
  call s:init_option('vimtex_view_skim_activate', 0)
  call s:init_option('vimtex_view_skim_sync', 0)
  call s:init_option('vimtex_view_skim_reading_bar', 0)
  call s:init_option('vimtex_view_skim_no_select', 0)
  call s:init_option('vimtex_view_texshop_activate', 0)
  call s:init_option('vimtex_view_texshop_sync', 0)
  call s:init_option('vimtex_view_zathura_options', '')
  call s:init_option('vimtex_view_zathura_check_libsynctex', 1)
  call s:init_option('vimtex_view_zathura_use_synctex', 1)

  " Fallback option
  if g:vimtex_context_pdf_viewer ==# 'NONE'
    let g:vimtex_context_pdf_viewer = g:vimtex_view_general_viewer
  endif

  let s:initialized = v:true
endfunction

let s:initialized = v:false

" }}}1

function! s:check_for_deprecated_options() abort " {{{1
  let l:deprecated = filter([
        \ 'g:vimtex_change_complete_envs',
        \ 'g:vimtex_change_ignored_delims_pattern',
        \ 'g:vimtex_change_set_formatexpr',
        \ 'g:vimtex_change_toggled_delims',
        \ 'g:vimtex_compiler_callback_hooks',
        \ 'g:vimtex_disable_recursive_main_file_detection',
        \ 'g:vimtex_env_complete_list',
        \ 'g:vimtex_fold_commands',
        \ 'g:vimtex_fold_commands_default',
        \ 'g:vimtex_fold_comments',
        \ 'g:vimtex_fold_env_blacklist',
        \ 'g:vimtex_fold_env_whitelist',
        \ 'g:vimtex_fold_envs',
        \ 'g:vimtex_fold_markers',
        \ 'g:vimtex_fold_parts',
        \ 'g:vimtex_fold_preamble',
        \ 'g:vimtex_fold_sections',
        \ 'g:vimtex_index_hide_line_numbers',
        \ 'g:vimtex_index_mode',
        \ 'g:vimtex_index_resize',
        \ 'g:vimtex_index_show_help',
        \ 'g:vimtex_index_split_pos',
        \ 'g:vimtex_index_split_width',
        \ 'g:vimtex_latexmk_autojump',
        \ 'g:vimtex_latexmk_background',
        \ 'g:vimtex_latexmk_callback',
        \ 'g:vimtex_latexmk_callback_hooks',
        \ 'g:vimtex_latexmk_continuous',
        \ 'g:vimtex_latexmk_enabled',
        \ 'g:vimtex_latexmk_options',
        \ 'g:vimtex_latexmk_progname',
        \ 'g:vimtex_quickfix_ignore_all_warnings',
        \ 'g:vimtex_quickfix_ignored_warnings',
        \ 'g:vimtex_quickfix_latexlog',
        \ 'g:vimtex_quickfix_warnings',
        \ 'g:vimtex_syntax_autoload_packages',
        \ 'g:vimtex_syntax_conceal_default',
        \ 'g:vimtex_syntax_nospell_commands',
        \ 'g:vimtex_textidote_jar',
        \ 'g:vimtex_toc_fold',
        \ 'g:vimtex_toc_fold_level_start',
        \ 'g:vimtex_toc_fold_levels',
        \ 'g:vimtex_toc_hide_help',
        \ 'g:vimtex_toc_hide_line_numbers',
        \ 'g:vimtex_toc_hide_preamble',
        \ 'g:vimtex_toc_hotkeys',
        \ 'g:vimtex_toc_layers',
        \ 'g:vimtex_toc_number_width',
        \ 'g:vimtex_toc_numbers',
        \ 'g:vimtex_toc_numbers_width',
        \ 'g:vimtex_toc_refresh_always',
        \ 'g:vimtex_toc_resize',
        \ 'g:vimtex_toc_show_numbers',
        \ 'g:vimtex_toc_split_pos',
        \ 'g:vimtex_toc_tocdepth',
        \ 'g:vimtex_toc_width',
        \ 'g:vimtex_view_automatic_xwin',
        \ 'g:vimtex_view_general_callback',
        \ 'g:vimtex_view_general_hook_callback',
        \ 'g:vimtex_view_general_hook_view',
        \ 'g:vimtex_view_general_options_latexmk',
        \ 'g:vimtex_view_mupdf_hook_callback',
        \ 'g:vimtex_view_mupdf_hook_view',
        \ 'g:vimtex_view_skim_hook_callback',
        \ 'g:vimtex_view_skim_hook_view',
        \ 'g:vimtex_view_zathura_hook_callback',
        \ 'g:vimtex_view_zathura_hook_view',
        \], 'exists(v:val)')

  if !empty(l:deprecated)
    redraw!
    let l:message = ['Deprecated option(s) detected!']
          \ + map(l:deprecated, { _, val -> '- ' . val})
          \ + ['Please see `:help OPTION` for more info!']
    call vimtex#log#warning(l:message)
  endif
endfunction

" }}}1

function! s:init_highlights() abort " {{{1
  for [l:name, l:target] in [
        \ ['VimtexImapsArrow', 'Comment'],
        \ ['VimtexImapsLhs', 'ModeMsg'],
        \ ['VimtexImapsRhs', 'ModeMsg'],
        \ ['VimtexImapsWrapper', 'Type'],
        \ ['VimtexInfo', 'Question'],
        \ ['VimtexInfoTitle', 'PreProc'],
        \ ['VimtexInfoKey', 'PreProc'],
        \ ['VimtexInfoValue', 'Statement'],
        \ ['VimtexInfoOther', ''],
        \ ['VimtexMsg', 'ModeMsg'],
        \ ['VimtexSuccess', 'Statement'],
        \ ['VimtexTodo', 'Todo'],
        \ ['VimtexWarning', 'WarningMsg'],
        \ ['VimtexError', 'Error'],
        \ ['VimtexFatal', 'ErrorMsg'],
        \ ['VimtexBlink', 'PMenu'],
        \ ['VimtexTocHelp', 'helpVim'],
        \ ['VimtexTocHelpKey', 'ModeMsg'],
        \ ['VimtexTocHelpLayerOn', 'Statement'],
        \ ['VimtexTocHelpLayerOff', 'Comment'],
        \ ['VimtexTocTodo', 'VimtexTodo'],
        \ ['VimtexTocWarning', 'VimtexWarning'],
        \ ['VimtexTocError', 'VimtexError'],
        \ ['VimtexTocFatal', 'VimtexFatal'],
        \ ['VimtexTocNum', 'Number'],
        \ ['VimtexTocSec0', 'Title'],
        \ ['VimtexTocSec1', ''],
        \ ['VimtexTocSec2', 'helpVim'],
        \ ['VimtexTocSec3', 'NonText'],
        \ ['VimtexTocSec4', 'Comment'],
        \ ['VimtexTocHotkey', 'Comment'],
        \ ['VimtexTocLabelsSecs', 'Statement'],
        \ ['VimtexTocLabelsEq', 'PreProc'],
        \ ['VimtexTocLabelsFig', 'Identifier'],
        \ ['VimtexTocLabelsTab', 'String'],
        \ ['VimtexTocIncl', 'Number'],
        \ ['VimtexTocInclPath', ''],
        \]
    if !hlexists(l:name) && !empty(l:target)
      silent execute 'highlight default link' l:name l:target
    endif
  endfor
endfunction

" }}}1
function! s:init_option(option, default) abort " {{{1
  let l:option = 'g:' . a:option
  if !exists(l:option)
    let {l:option} = a:default
  elseif type(a:default) == v:t_dict
    call vimtex#util#extend_recursive({l:option}, a:default, 'keep')
  endif
endfunction

" }}}1
