" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" This script has a lot of unicode characters (for conceals)
scriptencoding utf-8

" ## Performance tips
"
" Due to the way (neo)vim implements syntax highlighting, having hundreds of
" different `syntax match ...` (like this file does) results in poor
" performance. To minimize the performance impact, it is better to prefer few
" syntax rules (called syntax items in the vim docs) with complicated regexes
" over many rules with simple regexes. E.g.
"
"     syntax match texMathCmdStyle "\\math\%(rm\|tt\|normal\|sf\)\>"
"
" is faster than
"
"     syntax match texMathCmdStyle "\\mathrm\>"
"     syntax match texMathCmdStyle "\\mathtt\>"
"     syntax match texMathCmdStyle "\\mathnormal\>"
"     syntax match texMathCmdStyle "\\mathsf\>"
"
" In addition, as of the time of writing (Summer 2024), it seems like
" (neo)vim's backtracking regex engine is faster than the NFA engine for all
" regexes that aren't just literal strings (contrary to the advertising in
" :h two-engines). This is why this syntax file manually sets the old engine
" for most complicated regexes.
"
" Finally, syntax rules that don't "interact" with other rules should be
" marked as "display". See :h :syn-display for details.
"
" IF YOU WANT TO ADD NEW SYNTAX GROUP FOR A MATH-MODE COMMAND:
" Don't add it to the texClusterMath cluster, but to _texMathBackslash.
" Read the comment before the definition of texClusterMath for details.
"
" For reference: https://github.com/lervag/vimtex/pull/3006


function! vimtex#syntax#core#init_rules() abort " {{{1
  " Operators and similar
  syntax match texMathOper "\%#=1[-+=/<>|]" contained display
  syntax match texMathSuperSub "\%#=1[_^]" contained display
  syntax match texMathDelim contained "\%#=1[()[\]]" display

  " {{{2 Define main syntax clusters

  syntax cluster texClusterOpt contains=
        \texCmd,
        \texComment,
        \texGroup,
        \texLength,
        \texOpt,
        \texOptEqual,
        \texOptSep,
        \@NoSpell

  " The following syntax cluster defines which syntax patterns are allowed to
  " appear in math mode. Syntax patterns that always start with a backslash
  " (e.g. texMathCmd) should be put in the cluster _texMathBackslash instead.
  " This speeds up syntax highlighting, because vim won't try to match other
  " patterns at positions where it encounters a backslash in math mode.

  " The following patterns sometimes start with a backslash and sometimes
  " don't, so they appear in texClusterMath and in _texMathBackslash:
  " texSpecialChar (can match "~")
  " texTabularChar (can match "&")
  " texComment (can be started by \ifffalse)
  " texCmdGreek, texMathSymbol (can match unicode symbols)
  " texMathDelim (can e.g. match "(" or "\lvert")
  syntax cluster texClusterMath contains=
        \texComment,
        \texGroupError,
        \texMathDelim,
        \texMathGroup,
        \texMathOper,
        \texMathSuperSub,
        \texSpecialChar,
        \texCmdGreek,
        \texMathSymbol,
        \texTabularChar,
        \_texMathBackslash,
        \@NoSpell

  " }}}2

  " {{{2 TeX symbols and special characters

  syntax match texLigature "---\?" display
  syntax match texLigature "``" display
  syntax match texLigature "''" display
  syntax match texLigature ",," display
  syntax match texTabularChar "&"
  syntax match texTabularChar "\\\\"

  " E.g.:  \$ \& \% \# \{ \} \_ \S \P
  syntax match texSpecialChar "\~"
  syntax match texSpecialChar "\%#=1\\[ $&%#{}_@,;:!>]"
  syntax match texSpecialChar "\%#=1\\[SP@]\ze[^a-zA-Z@]"
  syntax match texSpecialChar "\%#=1\^\^\%(\S\|[0-9a-f]\{2}\)"

  syntax match texError "\%#=1[_^]" display

  " }}}2
  " {{{2 Commands: general

  " Unspecified TeX groups
  " Note: This is necessary to keep track of all nested braces
  call vimtex#syntax#core#new_arg('texGroup', {'opts': ''})

  " Flag mismatching ending brace delimiter
  syntax match texGroupError "}" display

  " Add generic option elements contained in common option groups
  syntax match texOptEqual contained "="
  syntax match texOptSep contained ",\s*"

  " TeX Lengths (matched in options and some arguments)
  syntax match texLength contained "\%#=1\<\d\+\([.,]\d\+\)\?\s*\(true\)\?\s*\(bp\|cc\|cm\|dd\|em\|ex\|in\|mm\|pc\|pt\|sp\)\>"

  " Match general commands first
  syntax match texCmd nextgroup=texOpt,texArg skipwhite skipnl "\%#=1\\[a-zA-Z@]\+"
  call vimtex#syntax#core#new_opt('texOpt', {'next': 'texArg'})
  call vimtex#syntax#core#new_arg('texArg', {'next': 'texArg', 'opts': 'contained transparent'})

  " Define separate "generic" commands inside math regions
  " Note: Defined here because order matters!
  syntax match texMathCmd contained nextgroup=texMathArg skipwhite skipnl "\%#=1\\\a\+"
  call vimtex#syntax#core#new_arg('texMathArg', {'contains': '@texClusterMath'})

  " {{{2 Commands: core set

  " Accents and ligatures
  syntax match texCmdAccent "\%#=1\\[bcdvuH]$"
  syntax match texCmdAccent "\%#=1\\[bcdvuH]\ze[^a-zA-Z@]"
  syntax match texCmdAccent /\%#=1\\[=^.~"`']/
  syntax match texCmdAccent /\%#=1\\['=t'.c^ud"vb~Hr]{\a}/
  syntax match texCmdLigature "\%#=1\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)$"
  syntax match texCmdLigature "\%#=1\v\\%([ijolL]|ae|oe|ss|AA|AE|OE)\ze[^a-zA-Z@]"

  " Spacecodes (TeX'isms)
  " * See e.g. https://en.wikibooks.org/wiki/TeX/catcode
  " * \mathcode`\^^@ = "2201
  " * \delcode`\( = "028300
  " * \sfcode`\) = 0
  " * \uccode`X = `X
  " * \lccode`x = `x
  syntax match texCmdSpaceCode "\%#=1\v\\%(math|cat|del|lc|sf|uc)code`"me=e-1
        \ nextgroup=texCmdSpaceCodeChar
  syntax match texCmdSpaceCodeChar "\%#=1\v`\\?.%(\^.)?\?%(\d|\"\x{1,6}|`.)" contained

  " Todo commands
  syntax match texCmdTodo "\%#=1\\todo\w*"

  " \author
  syntax match texCmdAuthor nextgroup=texAuthorOpt,texAuthorArg skipwhite skipnl "\%#=1\\author\>"
  call vimtex#syntax#core#new_opt('texAuthorOpt', {'next': 'texAuthorArg'})
  call vimtex#syntax#core#new_arg('texAuthorArg', {'contains': 'TOP,@Spell'})

  " \title
  syntax match texCmdTitle nextgroup=texTitleArg skipwhite skipnl "\%#=1\\title\>"
  call vimtex#syntax#core#new_arg('texTitleArg')

  " \footnote
  syntax match texCmdFootnote nextgroup=texFootnoteArg skipwhite skipnl "\%#=1\\footnote\>"
  call vimtex#syntax#core#new_arg('texFootnoteArg')

  " \if \else \fi
  syntax match texCmdConditional nextgroup=texConditionalArg skipwhite skipnl "\%#=1\\\(if[a-zA-Z@]\+\|fi\|else\)\>"
  call vimtex#syntax#core#new_arg('texConditionalArg')

  " \@ifnextchar
  syntax match texCmdConditionalINC "\%#=1\\\w*@ifnextchar\>"
        \ nextgroup=texConditionalINCChar skipwhite skipnl
  syntax match texConditionalINCChar "\S" contained

  " Various commands that take a file argument (or similar)
  syntax match texCmdInput   nextgroup=texFileArg              skipwhite skipnl "\%#=1\\input\>"
  syntax match texCmdInput   nextgroup=texFileArg              skipwhite skipnl "\%#=1\\include\>"
  syntax match texCmdInput   nextgroup=texFilesArg             skipwhite skipnl "\%#=1\\includeonly\>"
  syntax match texCmdInput   nextgroup=texFileOpt,texFileArg   skipwhite skipnl "\%#=1\\includegraphics\>"
  syntax match texCmdBib     nextgroup=texFilesArg             skipwhite skipnl "\%#=1\\bibliography\>"
  syntax match texCmdBib     nextgroup=texFileArg              skipwhite skipnl "\%#=1\\bibliographystyle\>"
  syntax match texCmdClass   nextgroup=texFileOpt,texFileArg   skipwhite skipnl "\%#=1\\document\%(class\|style\)\>"
  syntax match texCmdPackage nextgroup=texFilesOpt,texFilesArg skipwhite skipnl "\%#=1\v\\(usepackage|RequirePackage|ProvidesPackage)>"
  call vimtex#syntax#core#new_arg('texFileArg', {'contains': '@NoSpell,texCmd,texComment'})
  call vimtex#syntax#core#new_arg('texFilesArg', {'contains': '@NoSpell,texCmd,texComment,texOptSep'})
  call vimtex#syntax#core#new_opt('texFileOpt', {'next': 'texFileArg'})
  call vimtex#syntax#core#new_opt('texFilesOpt', {'next': 'texFilesArg'})

  " LaTeX 2.09 type styles

  syntax match texCmdStyle "\%#=1\v\\%(rm|em|bf|it|s[cfl]|tt)>" display

  " LaTeX2E type styles

  syntax match texCmdStyle "\%#=1\v\\%(
        \text%(bf|it|md|rm|s[cfl]|tt|up|normal)
        \|emph
        \|%(rm|sf|tt)family
        \|%(it|sc|sl|up)shape
        \|%(bf|md)series
        \)>" display

  " Bold and italic commands
  call s:match_bold_italic()

  " Type sizes
  syntax match texCmdSize "\%#=1\v\\%(
        \tiny
        \|%(script|footnote|normal)size
        \|small
        \|[lL]arge|LARGE
        \|[hH]uge
        \)>" display

  " \newcommand
  syntax match texCmdNewcmd "\%#=1\\\%(re\)\?newcommand\>\*\?"
        \ nextgroup=texNewcmdArgName skipwhite skipnl
  syntax match texNewcmdArgName "\%#=1\\[a-zA-Z@]\+"
        \ nextgroup=texNewcmdOpt,texNewcmdArgBody skipwhite skipnl
        \ contained
  call vimtex#syntax#core#new_arg('texNewcmdArgName', {
        \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
        \ 'contains': ''
        \})
  call vimtex#syntax#core#new_opt('texNewcmdOpt', {
        \ 'next': 'texNewcmdOpt,texNewcmdArgBody',
        \ 'opts': 'oneline',
        \})
  call vimtex#syntax#core#new_arg('texNewcmdArgBody')
  " The default regexp v2 seems to be faster here:
  syntax match texNewcmdParm contained "#\+\d" containedin=texNewcmdArgBody

  " \newenvironment
  syntax match texCmdNewenv nextgroup=texNewenvArgName skipwhite skipnl "\%#=1\\\%(re\)\?newenvironment\>"
  call vimtex#syntax#core#new_arg('texNewenvArgName', {'next': 'texNewenvArgBegin,texNewenvOpt'})
  call vimtex#syntax#core#new_opt('texNewenvOpt', {
        \ 'next': 'texNewenvArgBegin,texNewenvOpt',
        \ 'opts': 'oneline'
        \})
  call vimtex#syntax#core#new_arg('texNewenvArgBegin', {'next': 'texNewenvArgEnd'})
  call vimtex#syntax#core#new_arg('texNewenvArgEnd')
  syntax match texNewenvParm contained "#\+\d" containedin=texNewenvArgBegin,texNewenvArgEnd

  " Definitions/Commands
  " E.g. \def \foo #1#2 {foo #1 bar #2 baz}
  syntax match texCmdDef "\%#=1\\def\>" nextgroup=texDefArgName skipwhite skipnl
  syntax match texDefArgName contained nextgroup=texDefParmPre,texDefArgBody skipwhite skipnl "\%#=1\\[a-zA-Z@]\+"
  syntax match texDefArgName contained nextgroup=texDefParmPre,texDefArgBody skipwhite skipnl "\%#=1\\[^a-zA-Z@]"
  syntax match texDefParmPre contained nextgroup=texDefArgBody skipwhite skipnl "#[^{]*"
  syntax match texDefParm contained "#\+\d" containedin=texDefParmPre,texDefArgBody
  call vimtex#syntax#core#new_arg('texDefArgBody')

  " \let
  syntax match texCmdLet "\%#=1\\let\>" nextgroup=texLetArgName skipwhite skipnl
  syntax match texLetArgName  contained nextgroup=texLetArgBody,texLetArgEqual skipwhite skipnl "\%#=1\\[a-zA-Z@]\+"
  syntax match texLetArgName  contained nextgroup=texLetArgBody,texLetArgEqual skipwhite skipnl "\%#=1\\[^a-zA-Z@]"
  " Note: define texLetArgEqual after texLetArgBody; order matters
  " E.g. in '\let\eq==' we want: 1st = is texLetArgEqual, 2nd = is texLetArgBody
  " Reversing lines results in:  1st = is texLetArgBody,  2nd = is unmatched
  syntax match texLetArgBody  contained "\%#=1\\[a-zA-Z@]\+\|\\[^a-zA-Z@]\|\S" contains=TOP,@Nospell
  syntax match texLetArgEqual contained nextgroup=texLetArgBody skipwhite skipnl "="

  " Reference and cite commands
  syntax match texCmdRef nextgroup=texRefArg skipwhite skipnl "\%#=1\v\\%(
        \nocite
        \|label
        \|%(page|eq|v)?ref
        \)>"

  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\%#=1\v\\cite%(>|[tp]>\*?)"
  call vimtex#syntax#core#new_opt('texRefOpt', {'next': 'texRefOpt,texRefArg'})
  call vimtex#syntax#core#new_arg('texRefArg', {'contains': 'texComment,@NoSpell'})

  " \bibitem[label]{marker}
  syntax match texCmdBibitem "\%#=1\\bibitem\>"
        \ nextgroup=texBibitemOpt,texBibitemArg skipwhite skipnl
  call vimtex#syntax#core#new_opt('texBibitemOpt', {
        \ 'next': 'texBibitemArg'
        \})
  call vimtex#syntax#core#new_arg('texBibitemArg',
        \ {'contains': 'texComment,@NoSpell'})

  " Sections and parts
  syntax match texCmdPart "\%#=1\\\(front\|main\|back\)matter\>" display
  syntax match texCmdPart "\%#=1\v\\%(
        \%(part|%(sub)?paragraph)>
        \|%(%(sub)*section|chapter)>\*?
        \)"
        \ nextgroup=texPartArgTitle
  call vimtex#syntax#core#new_arg('texPartArgTitle')

  " Item elements in lists
  syntax match texCmdItem "\%#=1\\item\>" nextgroup=texItemLabel
  call vimtex#syntax#core#new_opt('texItemLabel')

  " \begin \end environments
  syntax match texCmdEnv "\%#=1\v\\%(begin|end)>" nextgroup=texEnvArgName
  call vimtex#syntax#core#new_arg('texEnvArgName', {
        \ 'contains': 'texComment,@NoSpell',
        \ 'next': 'texEnvOpt',
        \})
  call vimtex#syntax#core#new_opt('texEnvOpt')

  " {{{2 Commands: \begin{tabular}

  syntax match texCmdTabular "\\begin{tabular}"
        \ skipwhite skipnl
        \ nextgroup=texTabularOpt,texTabularArg
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texTabularOpt', {
        \ 'next': 'texTabularArg',
        \ 'contains': 'texComment,@NoSpell',
        \})
  call vimtex#syntax#core#new_arg('texTabularArg', {
        \ 'contains': '@texClusterTabular'
        \})

  syntax match texTabularAtSep     "@"     contained nextgroup=texTabularLength
  syntax match texTabularCol       "[lcr]" contained
  syntax match texTabularCol       "\*"    contained nextgroup=texTabularMulti
  syntax match texTabularCol       "p"     contained nextgroup=texTabularLength
  syntax match texTabularVertline  "||\?"  contained
  syntax cluster texClusterTabular contains=texTabular.*

  call vimtex#syntax#core#new_arg('texTabularLength', {
        \ 'contains': 'texLength,texCmd'
        \})
  call vimtex#syntax#core#new_arg('texTabularMulti', {'next': 'texTabularArg'})

  " {{{2 Commands: \begin{minipage}[position][height][inner-pos]{width}

  " Reference: http://latexref.xyz/minipage.html

  syntax match texCmdMinipage "\\begin{minipage}"
        \ skipwhite skipnl
        \ nextgroup=texMinipageOptPos,texMinipageArgWidth
        \ contains=texCmdEnv

  call vimtex#syntax#core#new_opt('texMinipageOptPos', {
        \ 'next': 'texMinipageOptHeight,texMinipageArgWidth',
        \ 'contains': 'texBoxOptPosVal,texComment',
        \})
  call vimtex#syntax#core#new_opt('texMinipageOptHeight', {
        \ 'next': 'texMinipageOptIPos,texMinipageArgWidth',
        \ 'contains': 'texLength,texCmd,texComment',
        \})
  call vimtex#syntax#core#new_opt('texMinipageOptIPos', {
        \ 'next': 'texMinipageArgWidth',
        \ 'contains': 'texBoxOptIPosVal,texComment',
        \})
  call vimtex#syntax#core#new_arg('texMinipageArgWidth', {
        \ 'contains': 'texLength,texCmd,texComment',
        \})

  " These are also used inside \parbox options
  syntax match texBoxOptPosVal "\%#=1[bcmt]" contained
  syntax match texBoxOptIPosVal "\%#=1[bcst]" contained

  " {{{2 Commands: \parbox[position][height][inner-pos]{width}{contents}

  " Reference: http://latexref.xyz/_005cparbox.html

  syntax match texCmdParbox "\%#=1\\parbox\>"
        \ skipwhite skipnl
        \ nextgroup=texParboxOptPos,texParboxArgWidth

  call vimtex#syntax#core#new_opt('texParboxOptPos', {
        \ 'next': 'texParboxOptHeight,texParboxArgWidth',
        \ 'contains': 'texBoxOptPosVal,texComment',
        \})
  call vimtex#syntax#core#new_opt('texParboxOptHeight', {
        \ 'next': 'texParboxOptIPos,texParboxArgWidth',
        \ 'contains': 'texLength,texCmd,texComment',
        \})
  call vimtex#syntax#core#new_opt('texParboxOptIPos', {
        \ 'next': 'texParboxArgWidth',
        \ 'contains': 'texBoxOptIPosVal,texComment',
        \})
  call vimtex#syntax#core#new_arg('texParboxArgWidth', {
        \ 'next': 'texParboxArgContent',
        \ 'contains': 'texLength,texCmd,texComment',
        \})
  call vimtex#syntax#core#new_arg('texParboxArgContent')

  " }}}2
  " {{{2 Commands: Theorems

  " Reference: LaTeX 2e Unofficial reference guide, section 12.9
  "            https://texdoc.org/serve/latex2e/0

  " \newtheorem
  syntax match texCmdNewthm "\%#=1\\newtheorem\>"
        \ nextgroup=texNewthmArgName skipwhite skipnl
  call vimtex#syntax#core#new_arg('texNewthmArgName', {
        \ 'next': 'texNewthmOptCounter,texNewthmArgPrinted',
        \ 'contains': 'TOP,@Spell'
        \})
  call vimtex#syntax#core#new_opt('texNewthmOptCounter',
        \ {'next': 'texNewthmArgPrinted'}
        \)
  call vimtex#syntax#core#new_arg('texNewthmArgPrinted',
        \ {'next': 'texNewthmOptNumberby'}
        \)
  call vimtex#syntax#core#new_opt('texNewthmOptNumberby')

  " \begin{mytheorem}[custom title]
  call vimtex#syntax#core#new_opt('texTheoremEnvOpt', {
        \ 'contains': 'TOP,@NoSpell'
        \})

  " }}}2
  " {{{2 Comments

  " * In documented TeX Format, actual comments are defined by leading "^^A".
  "   Almost all other lines start with one or more "%", which may be matched
  "   as comment characters. The remaining part of the line can be interpreted
  "   as TeX syntax.
  " * For more info on dtx files, see e.g.
  "   https://ctan.uib.no/info/dtxtut/dtxtut.pdf
  if expand('%:e') ==# 'dtx'
    syntax match texComment "\%#=1\^\^A.*$"
    syntax match texComment "\%#=1^%\+"
  elseif g:vimtex_syntax_nospell_comments
    syntax match texComment "\%#=1%.*$" contains=@NoSpell
  else
    syntax match texComment "\%#=1%.*$" contains=@Spell
  endif

  " Don't spell check magic comments/directives
  syntax match texComment "\%#=1^\s*%\s*!.*" contains=@NoSpell display

  " Do not check URLs and acronyms in comments
  " Source: https://github.com/lervag/vimtex/issues/562
  syntax match texCommentURL "\%#=1\w\+:\/\/[^[:space:]]\+"
        \ containedin=texComment contained contains=@NoSpell display
  syntax match texCommentAcronym "\%#=1\v<(\u|\d){3,}s?>"
        \ containedin=texComment contained contains=@NoSpell display

  " Todo and similar within comments
  syntax case ignore
  syntax keyword texCommentTodo combak fixme todo xxx
        \ containedin=texComment contained
  syntax case match
  syntax keyword texCommentTodo ISSUE NOTE
        \ containedin=texComment contained

  " Highlight \iffalse ... \fi blocks as comments
  syntax region texComment matchgroup=texCmdConditional
        \ start="\%#=1^\s*\\iffalse\>" end="\%#=1\\\%(fi\|else\)\>"
        \ contains=texCommentConditionals

  syntax region texCommentConditionals matchgroup=texComment
        \ start="\%#=1\\if\w\+" end="\%#=1\\fi\>"
        \ contained transparent contains=NONE
  syntax match texCommentConditionals "\%#=1\\iff\>"
        \ contained transparent contains=NONE

  " Highlight \iftrue ... \else ... \fi blocks as comments
  syntax region texConditionalTrueZone matchgroup=texCmdConditional
        \ start="\%#=1^\s*\\iftrue\>"  end="\%#=1\v\\fi>|%(\\else>)@="
        \ contains=TOP nextgroup=texCommentFalse
        \ transparent

  syntax region texConditionalNested matchgroup=texCmdConditional
        \ start="\%#=1\\if\w\+" end="\%#=1\\fi\>"
        \ contained contains=TOP
        \ containedin=texConditionalTrueZone,texConditionalNested

  syntax region texCommentFalse matchgroup=texCmdConditional
        \ start="\%#=1\\else\>"  end="\%#=1\\fi\>"
        \ contained contains=texCommentConditionals

  " }}}2
  " {{{2 Zone: Verbatim

  " Verbatim environment
  call vimtex#syntax#core#new_env({
        \ 'name': '[vV]erbatim',
        \ 'region': 'texVerbZone',
        \})

  " Verbatim inline
  syntax match texCmdVerb "\%#=1\\verb\>\*\?" nextgroup=texVerbZoneInline
  call vimtex#syntax#core#new_arg('texVerbZoneInline', {
        \ 'contains': '',
        \ 'matcher': 'start="\%#=1\z([^\ta-zA-Z]\)" end="\z1"'
        \})

  " }}}2
  " {{{2 Zone: Expl3

  syntax region texE3Zone matchgroup=texCmdE3
        \ start="\%#=1\\\%(ExplSyntaxOn\|ProvidesExpl\%(Package\|Class\|File\)\)"
        \ end="\%#=1\\ExplSyntaxOff\|\%$"
        \ transparent
        \ contains=TOP,@NoSpell

  call vimtex#syntax#core#new_arg('texE3Group', {
        \ 'opts': 'contained containedin=@texClusterE3',
        \})

  syntax match texE3Cmd "\\\w\+"
        \ contained containedin=@texClusterE3
        \ nextgroup=texE3Opt,texE3Arg skipwhite skipnl
  call vimtex#syntax#core#new_opt('texE3Opt', {'next': 'texE3Arg'})
  call vimtex#syntax#core#new_arg('texE3Arg', {
        \ 'next': 'texE3Arg',
        \ 'opts': 'contained transparent'
        \})

  syntax match texE3CmdNestedZoneEnd '\\\ExplSyntaxOff'
        \ contained containedin=texE3Arg,texE3Group

  syntax match texE3Variable "\\[gl]_\%(\h\|@@_\@=\)*_\a\+"
        \ contained containedin=@texClusterE3
  syntax match texE3Constant "\\c_\%(\h\|@@_\@=\)*_\a\+"
        \ contained containedin=@texClusterE3
  syntax match texE3Function "\\\%(\h\|@@_\)\+:\a*"
        \ contained containedin=@texClusterE3
        \ contains=texE3Type

  syntax match texE3Type ":[a-zA-Z]*" contained
  syntax match texE3Parm "#\+\d" contained containedin=@texClusterE3

  syntax cluster texClusterE3 contains=texE3Zone,texE3Arg,texE3Group,texE3Opt

  " }}}2
  " {{{2 Zone: Math

  " Define math region group
  call vimtex#syntax#core#new_arg('texMathGroup', {'contains': '@texClusterMath'})

  " Define math environment boundaries
  syntax match texCmdMathEnv "\%#=1\v\\%(begin|end)>" contained nextgroup=texMathEnvArgName
  call vimtex#syntax#core#new_arg('texMathEnvArgName',
        \ {'contains': 'texComment,@NoSpell'})

  " Environments inside math zones
  " * This is used to restrict the whitespace between environment name and
  "   the option group (see https://github.com/lervag/vimtex/issues/2043).
  syntax match texCmdEnvM "\%#=1\v\\%(begin|end)>" contained nextgroup=texEnvMArgName
  call vimtex#syntax#core#new_arg('texEnvMArgName', {
        \ 'contains': 'texComment,@NoSpell',
        \ 'next': 'texEnvOpt',
        \ 'skipwhite': v:false
        \})

  " Math regions: environments
  call vimtex#syntax#core#new_env({
        \ 'name': 'displaymath',
        \ 'starred': v:true,
        \ 'math': v:true
        \})
  call vimtex#syntax#core#new_env({
        \ 'name': 'eqnarray',
        \ 'starred': v:true,
        \ 'math': v:true
        \})
  call vimtex#syntax#core#new_env({
        \ 'name': 'equation',
        \ 'starred': v:true,
        \ 'math': v:true
        \})
  call vimtex#syntax#core#new_env({
        \ 'name': 'math',
        \ 'starred': v:true,
        \ 'math': v:true
        \})

  " Math regions: Inline Math Zones
  let l:conceal = g:vimtex_syntax_conceal.math_bounds ? 'concealends' : ''
  execute 'syntax region texMathZoneLI matchgroup=texMathDelimZoneLI'
          \ 'start="\\("'
          \ 'end="\\)"'
          \ 'contains=@texClusterMath'
          \ l:conceal
  execute 'syntax region texMathZoneLD matchgroup=texMathDelimZoneLD'
          \ 'start="\\\["'
          \ 'end="\\]"'
          \ 'contains=@texClusterMath'
          \ l:conceal
  execute 'syntax region texMathZoneTI matchgroup=texMathDelimZoneTI'
          \ 'start="\$"'
          \ 'skip="\%#=1\\[\\\$]"'
          \ 'end="\$"'
          \ 'contains=@texClusterMath'
          \ 'nextgroup=texMathTextAfter'
          \ l:conceal
  execute 'syntax region texMathZoneTD matchgroup=texMathDelimZoneTD'
          \ 'start="\$\$"'
          \ 'end="\$\$"'
          \ 'contains=@texClusterMath keepend'
          \ l:conceal

  " This is to disable spell check for text just after "$" (e.g. "$n$th")
  syntax match texMathTextAfter "\%#=1\w\+" contained contains=@NoSpell

  " Math regions: \ensuremath{...}
  syntax match texCmdMath "\%#=1\\ensuremath\>" nextgroup=texMathZoneEnsured
  call vimtex#syntax#core#new_arg('texMathZoneEnsured', {'contains': '@texClusterMath'})

  " Bad/Mismatched math
  syntax match texMathError "\%#=1\\[\])]" display


  " Text Inside Math regions
  for l:re_cmd in [
        \ 'text%(normal|rm|up|tt|sf|sc)?',
        \ 'intertext',
        \ '[mf]box',
        \]
    execute 'syntax match texMathCmdText'
          \ '"\%#=1\v\\' . l:re_cmd . '>"'
          \ 'contained skipwhite nextgroup=texMathTextArg'
  endfor
  call vimtex#syntax#core#new_arg('texMathTextArg')

  " Math style commands
  syntax match texMathCmdStyle contained "\%#=1\v\\math%(bb|bf%(it)?|cal|frak|it|normal|rm|sf|tt|scr)>"

  " Bold and italic commands
  call s:match_bold_italic_math()

  " Support for array environment
  syntax match texMathCmdEnv contained contains=texCmdMathEnv "\%#=1\\begin{array}"
        \ nextgroup=texMathArrayArg skipwhite skipnl
  syntax match texMathCmdEnv contained contains=texCmdMathEnv "\%#=1\\end{array}"
  call vimtex#syntax#core#new_arg('texMathArrayArg', {
        \ 'contains': '@texClusterTabular'
        \})

  call s:match_math_sub_super()
  call s:match_math_delims()
  call s:match_math_symbols()
  call s:match_math_fracs()
  call s:match_math_unicode()
  call s:match_math_conceal_accents()

  " }}}2
  " {{{2 Zone: SynIgnore

  syntax region texSynIgnoreZone matchgroup=texComment
        \ start="\%#=1^\c\s*% VimTeX: SynIgnore\%( on\| enable\)\?\s*$"
        \ end="\%#=1^\c\s*% VimTeX: SynIgnore\%( off\| disable\).*"
        \ contains=texComment,texCmd

  " Also support Overleafs magic comment
  " https://www.overleaf.com/learn/how-to/Code_Check
  syntax region texSynIgnoreZone matchgroup=texComment
        \ start="\%#=1^%%begin novalidate\s*$"
        \ end="\%#=1^%%end novalidate\s*$"
        \ contains=texComment,texCmd

  " }}}2
  " {{{2 Conceal mode support

  " Add support for conceal with custom replacement (conceallevel = 2)

  if &encoding ==# 'utf-8'
    " Conceal various commands - be fancy
    if g:vimtex_syntax_conceal.fancy
      call s:match_conceal_fancy()
    endif

    " Conceal spacing commands
    if g:vimtex_syntax_conceal.spacing
      call s:match_conceal_spacing()
    endif

    " Conceal replace greek letters
    if g:vimtex_syntax_conceal.greek
      call s:match_conceal_greek()
    endif

    " Conceal replace accented characters
    if g:vimtex_syntax_conceal.accents
      call s:match_conceal_accents()
    endif

    " Conceal replace ligatures
    if g:vimtex_syntax_conceal.ligatures
      call s:match_conceal_ligatures()
    endif

    " Conceal cite commands
    if g:vimtex_syntax_conceal.cites
      call s:match_conceal_cites_{g:vimtex_syntax_conceal_cites.type}()
    endif

    " Conceal section commands
    if g:vimtex_syntax_conceal.sections
      call s:match_conceal_sections()
    endif
  endif

  " }}}2

  let b:current_syntax = 'tex'

  " see the definition of texClusterMath for an explanation of what this does
  syntax match _texMathBackslash "\\"me=e-1 contained nextgroup=
        \texComment,
        \texSpecialChar,
        \texCmdGreek,
        \texMathSymbol,
        \texTabularChar,
        \texCmdEnvM,
        \texCmdFootnote,
        \texCmdMinipage,
        \texCmdParbox,
        \texCmdRef,
        \texCmdSize,
        \texCmdStyle,
        \texCmdTodo,
        \texCmdVerb,
        \texMathCmd,
        \texMathCmdEnv,
        \texMathCmdStyle,
        \texMathCmdStyleBold,
        \texMathCmdStyleItal,
        \texMathCmdStyleBoth,
        \texMathCmdText,
        \texMathDelimMod,
        \texMathDelim,
        \@NoSpell

endfunction

" }}}1
function! vimtex#syntax#core#init_post() abort " {{{1
  if exists('b:vimtex_syntax_did_postinit') | return | endif
  let b:vimtex_syntax_did_postinit = 1

  " Add texTheoremEnvBgn for custom theorems
  " creating a single big syntax rule instead of separate rules for every
  " custom theorem results in faster syntax highlighting.
  execute 'syntax match texTheoremEnvBgn'
        \ '"\%#=1\\begin{\%(' .. join(s:gather_newtheorems(), '\|') ..'\)}"'
        \ 'nextgroup=texTheoremEnvOpt skipwhite skipnl'
        \ 'contains=texCmdEnv'

  call vimtex#syntax#packages#init()
endfunction

" }}}1
function! vimtex#syntax#core#init_custom() abort " {{{1
  " Apply custom command syntax specifications
  " Note: These will override syntax extensions from packages!
  for l:item in g:vimtex_syntax_custom_cmds
    call vimtex#syntax#core#new_cmd(l:item)
  endfor

  for l:item in g:vimtex_syntax_custom_cmds_with_concealed_delims
    call vimtex#syntax#core#new_cmd_with_concealed_delims(l:item)
  endfor

  for l:item in g:vimtex_syntax_custom_envs
    call vimtex#syntax#core#new_env(l:item)
  endfor
endfunction

" }}}1
function! vimtex#syntax#core#init_options() abort " {{{1
  " These options are enforced initially, but also after loading syntax
  " packages that may have loaded nested syntaxes that change these options.

  syntax spell toplevel
  syntax iskeyword 48-57,a-z,A-Z,192-255
  syntax sync maxlines=500
  syntax sync minlines=50

  " Enable syntax foldlevel, but since it was introduced in Vim patch 8.2.0865
  " we must protect users with older Vim versions.
  try
    syntax xxfoldlevel start
  catch /E410:/
  endtry
endfunction

" }}}1

function! vimtex#syntax#core#init_highlights() abort " {{{1
  " See :help group-name for list of conventional group names

  " Primitive TeX highlighting groups
  highlight def link texArg              Include
  highlight def link texCmd              Statement
  highlight def link texCmdSpaceCodeChar Special
  highlight def link texCmdTodo          VimtexTodo
  highlight def link texCmdWarning       VimtexWarning
  highlight def link texCmdError         VimtexError
  highlight def link texCmdFatal         VimtexFatal
  highlight def link texCmdType          Type
  highlight def link texComment          Comment
  highlight def link texCommentTodo      Todo
  highlight def link texDelim            Delimiter
  highlight def link texEnvArgName       PreCondit
  highlight def link texError            VimtexError
  highlight def link texLength           Number
  highlight def link texMathDelim        Type
  highlight def link texMathEnvArgName   Delimiter
  highlight def link texMathOper         Operator
  highlight def link texMathZone         Special
  highlight def link texOpt              Identifier
  highlight def link texOptSep           NormalNC
  highlight def link texParm             Special
  highlight def link texPartArgTitle     String
  highlight def link texRefArg           Special
  highlight def link texZone             PreCondit
  highlight def link texSpecialChar      SpecialChar
  highlight def link texSymbol           SpecialChar
  highlight def link texTitleArg         Underlined
  highlight def texStyleBold          gui=bold                  cterm=bold
  highlight def texStyleItal          gui=italic                cterm=italic
  highlight def texStyleUnder         gui=underline             cterm=underline
  highlight def texStyleBoth          gui=bold,italic           cterm=bold,italic
  highlight def texStyleBoldUnder     gui=bold,underline        cterm=bold,underline
  highlight def texStyleItalUnder     gui=italic,underline      cterm=italic,underline
  highlight def texStyleBoldItalUnder gui=bold,italic,underline cterm=bold,italic,underline
  highlight def texMathStyleBold      gui=bold        cterm=bold
  highlight def texMathStyleItal      gui=italic      cterm=italic
  highlight def texMathStyleBoth      gui=bold,italic cterm=bold,italic

  " Inherited groups
  highlight def link texArgNew             texCmd
  highlight def link texAuthorOpt          texOpt
  highlight def link texBibitemArg         texArg
  highlight def link texBibitemOpt         texOpt
  highlight def link texBoxOptPosVal       texSymbol
  highlight def link texBoxOptIPosVal      texBoxOptPosVal
  highlight def link texCmdAccent          texCmd
  highlight def link texCmdAuthor          texCmd
  highlight def link texCmdBib             texCmd
  highlight def link texCmdBibitem         texCmd
  highlight def link texCmdClass           texCmd
  highlight def link texCmdConditional     texCmd
  highlight def link texCmdConditionalINC  texCmdConditional
  highlight def link texCmdDef             texCmdNew
  highlight def link texCmdEnv             texCmd
  highlight def link texCmdEnvM            texCmdEnv
  highlight def link texCmdE3              texCmd
  highlight def link texCmdFootnote        texCmd
  highlight def link texCmdGreek           texMathCmd
  highlight def link texCmdInput           texCmd
  highlight def link texCmdItem            texCmdEnv
  highlight def link texCmdLet             texCmdNew
  highlight def link texCmdLigature        texSpecialChar
  highlight def link texCmdMath            texCmd
  highlight def link texCmdMathEnv         texCmdEnv
  highlight def link texCmdNew             texCmd
  highlight def link texCmdNewcmd          texCmdNew
  highlight def link texCmdNewenv          texCmd
  highlight def link texCmdNewthm          texCmd
  highlight def link texCmdPackage         texCmd
  highlight def link texCmdParbox          texCmd
  highlight def link texCmdPart            texCmd
  highlight def link texCmdRef             texCmd
  highlight def link texCmdRefConcealed    texCmdRef
  highlight def link texCmdSize            texCmdType
  highlight def link texCmdSpaceCode       texCmd
  highlight def link texCmdStyle           texCmdType
  highlight def link texCmdStyleBold       texCmd
  highlight def link texCmdStyleBoldItal   texCmd
  highlight def link texCmdStyleItal       texCmd
  highlight def link texCmdStyleItalBold   texCmd
  highlight def link texCmdTitle           texCmd
  highlight def link texCmdVerb            texCmd
  highlight def link texCommentAcronym     texComment
  highlight def link texCommentFalse       texComment
  highlight def link texCommentURL         texComment
  highlight def link texConcealedArg       texArg
  highlight def link texConcealedArgGroup  texConcealedArg
  highlight def link texConditionalArg     texArg
  highlight def link texConditionalINCChar texSymbol
  highlight def link texDefArgName         texArgNew
  highlight def link texDefParm            texParm
  highlight def link texE3Cmd              texCmd
  highlight def link texE3Delim            texDelim
  highlight def link texE3Function         texCmdType
  highlight def link texE3Opt              texOpt
  highlight def link texE3Parm             texParm
  highlight def link texE3Type             texParm
  highlight def link texE3Variable         texCmd
  highlight def link texE3Constant         texE3Variable
  highlight def link texEnvOpt             texOpt
  highlight def link texEnvMArgName        texEnvArgName
  highlight def link texFileArg            texArg
  highlight def link texFileOpt            texOpt
  highlight def link texFilesArg           texFileArg
  highlight def link texFilesOpt           texFileOpt
  highlight def link texGroupError         texError
  highlight def link texItemLabel          texOpt
  highlight def link texItemLabelConcealed texItemLabel
  highlight def link texLetArgEqual        texSymbol
  highlight def link texLetArgName         texArgNew
  highlight def link texLigature           texSymbol
  highlight def link texMinipageOptHeight  texError
  highlight def link texMinipageOptIPos    texError
  highlight def link texMinipageOptPos     texError
  highlight def link texMathArg            texMathZone
  highlight def link texMathArrayArg       texOpt
  highlight def link texMathCmd            texCmd
  highlight def link texMathCmdStyle       texMathCmd
  highlight def link texMathCmdStyleBold   texMathCmd
  highlight def link texMathCmdStyleItal   texMathCmd
  highlight def link texMathCmdStyleBoth   texMathCmd
  highlight def link texMathCmdText        texCmd
  highlight def link texMathDelimMod       texMathDelim
  highlight def link texMathDelimZone      texDelim
  highlight def link texMathDelimZoneLI    texMathDelimZone
  highlight def link texMathDelimZoneLD    texMathDelimZone
  highlight def link texMathDelimZoneTI    texMathDelimZone
  highlight def link texMathDelimZoneTD    texMathDelimZone
  highlight def link texMathError          texError
  highlight def link texMathErrorDelim     texError
  highlight def link texMathGroup          texMathZone
  highlight def link texMathZoneLI         texMathZone
  highlight def link texMathZoneLD         texMathZone
  highlight def link texMathZoneTI         texMathZone
  highlight def link texMathZoneTD         texMathZone
  highlight def link texMathZoneEnsured    texMathZone
  highlight def link texMathZoneEnv        texMathZone
  highlight def link texMathZoneEnvStarred texMathZone
  highlight def link texMathStyleConcArg   texMathZone
  highlight def link texMathSub            texMathZone
  highlight def link texMathSuper          texMathZone
  highlight def link texMathSuperSub       texMathOper
  highlight def link texMathSymbol         texCmd
  highlight def link texNewcmdArgName      texArgNew
  highlight def link texNewcmdOpt          texOpt
  highlight def link texNewcmdParm         texParm
  highlight def link texNewenvArgName      texEnvArgName
  highlight def link texNewenvOpt          texOpt
  highlight def link texNewenvParm         texParm
  highlight def link texNewthmArgName      texArg
  highlight def link texNewthmOptCounter   texOpt
  highlight def link texNewthmOptNumberby  texOpt
  highlight def link texOptEqual           texSymbol
  highlight def link texParboxOptHeight    texError
  highlight def link texParboxOptIPos      texError
  highlight def link texParboxOptPos       texError
  highlight def link texPartConcealed      texCmdPart
  highlight def link texPartConcArgTitle   texPartArgTitle
  highlight def link texRefOpt             texOpt
  highlight def link texRefConcealedOpt1   texRefOpt
  highlight def link texRefConcealedOpt2   texRefOpt
  highlight def link texRefConcealedArg    texRefArg
  highlight def link texRefConcealedDelim  texDelim
  highlight def link texRefConcealedPOpt1  texRefOpt
  highlight def link texRefConcealedPOpt2  texRefOpt
  highlight def link texRefConcealedPArg   texRefArg
  highlight def link texRefConcealedPDelim texDelim
  highlight def link texTabularArg         texOpt
  highlight def link texTabularAtSep       texMathDelim
  highlight def link texTabularChar        texSymbol
  highlight def link texTabularCol         texOpt
  highlight def link texTabularOpt         texEnvOpt
  highlight def link texTabularVertline    texMathDelim
  highlight def link texTheoremEnvOpt      texEnvOpt
  highlight def link texVerbZone           texZone
  highlight def link texVerbZoneInline     texVerbZone
endfunction

" }}}1

function! vimtex#syntax#core#new_arg(grp, ...) abort " {{{1
  let l:cfg = extend({
        \ 'contains': 'TOP,@NoSpell',
        \ 'matcher': 'start="{" skip="\%#=1\\[\\\}]" end="}"',
        \ 'next': '',
        \ 'matchgroup': 'matchgroup=texDelim',
        \ 'opts': 'contained',
        \ 'skipwhite': v:true,
        \}, a:0 > 0 ? a:1 : {})

  execute 'syntax region' a:grp
        \ l:cfg.matchgroup
        \ l:cfg.matcher
        \ l:cfg.opts
        \ (empty(l:cfg.contains) ? '' : 'contains=' . l:cfg.contains)
        \ (empty(l:cfg.next) ? ''
        \   : 'nextgroup=' . l:cfg.next
        \     . (l:cfg.skipwhite ? ' skipwhite skipnl' : ''))
endfunction

" }}}1
function! vimtex#syntax#core#new_opt(grp, ...) abort " {{{1
  let l:cfg = extend({
        \ 'opts': '',
        \ 'next': '',
        \ 'contains': '@texClusterOpt',
        \}, a:0 > 0 ? a:1 : {})

  execute 'syntax region' a:grp
        \ 'contained matchgroup=texDelim'
        \ 'start="\[" skip="\%#=1\\[\\\]]" end="\]"'
        \ l:cfg.opts
        \ (empty(l:cfg.contains) ? '' : 'contains=' . l:cfg.contains)
        \ (empty(l:cfg.next) ? '' : 'nextgroup=' . l:cfg.next . ' skipwhite skipnl')
endfunction

" }}}1
function! vimtex#syntax#core#new_cmd(cfg) abort " {{{1
  if empty(get(a:cfg, 'name')) | return | endif

  " Parse options/config
  let l:cfg = extend({
        \ 'mathmode': v:false,
        \ 'conceal': v:false,
        \ 'concealchar': '',
        \ 'opt': v:true,
        \ 'arg': v:true,
        \ 'argstyle': '',
        \ 'argspell': v:true,
        \ 'arggreedy': v:false,
        \ 'nextgroup': '',
        \ 'hlgroup': '',
        \}, a:cfg)

  " Intuitive handling of concealchar
  if !empty(l:cfg.concealchar)
    let l:cfg.conceal = v:true
    if empty(l:cfg.argstyle)
      let l:cfg.opt = v:false
      let l:cfg.arg = v:false
    endif
  endif

  " Conceal optional group unless otherwise specified
  if !has_key(l:cfg, 'optconceal')
    let l:cfg.optconceal = l:cfg.conceal
  endif

  " Define group names
  let l:pre = l:cfg.mathmode ? 'texMath' : 'tex'
  let l:name = 'C' . toupper(l:cfg.name[0]) . l:cfg.name[1:]
  let l:group_cmd = l:pre . 'Cmd' . l:name
  let l:group_opt = l:pre . l:name . 'Opt'
  let l:group_arg = l:pre . l:name . 'Arg'

  " Specify rules for next groups
  if !empty(l:cfg.nextgroup)
    let l:nextgroups = 'skipwhite nextgroup=' . l:cfg.nextgroup
  else
    " Add syntax rules for the optional group
    let l:nextgroups = []
    if l:cfg.opt
      let l:nextgroups += [l:group_opt]

      let l:opt_cfg = {'opts': l:cfg.optconceal ? 'conceal' : ''}
      if l:cfg.arg
        let l:opt_cfg.next = l:group_arg
      endif
      call vimtex#syntax#core#new_opt(l:group_opt, l:opt_cfg)

      execute 'highlight def link' l:group_opt 'texOpt'
    endif

    " Add syntax rules for the argument group
    if l:cfg.arg
      let l:nextgroups += [l:group_arg]

      let l:arg_cfg = {'opts': 'contained'}
      if l:cfg.conceal && empty(l:cfg.concealchar)
        let l:arg_cfg.opts .= ' concealends'
      endif
      if l:cfg.mathmode
        let l:arg_cfg.contains = '@texClusterMath'
      elseif !l:cfg.argspell
        let l:arg_cfg.contains = 'TOP,@Spell'
      endif
      if l:cfg.arggreedy
        let l:arg_cfg.next = l:group_arg
      endif
      call vimtex#syntax#core#new_arg(l:group_arg, l:arg_cfg)

      let l:style = get({
            \ 'bold': 'texStyleBold',
            \ 'ital': 'texStyleItal',
            \ 'under': 'texStyleUnder',
            \ 'boldital': 'texStyleBoth',
            \ 'boldunder': 'texStyleBoldUnder',
            \ 'italunder': 'texStyleItalUnder',
            \ 'bolditalunder': 'texStyleBoldItalUnder',
            \}, l:cfg.argstyle,
            \ l:cfg.mathmode ? 'texMathArg' : '')
      if !empty(l:style)
        execute 'highlight def link' l:group_arg l:style
      endif
    endif

    let l:nextgroups = !empty(l:nextgroups)
          \ ? 'skipwhite nextgroup=' . join(l:nextgroups, ',')
          \ : ''
  endif

  " Add to cluster if necessary
  if l:cfg.mathmode
    execute 'syntax cluster texClusterMath add=' . l:group_cmd
  endif

  " Create the final syntax rule
  execute 'syntax match' l:group_cmd
        \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name . '>') . '"'
        \ l:cfg.conceal ? 'conceal' : ''
        \ !empty(l:cfg.concealchar) ? 'cchar=' . l:cfg.concealchar : ''
        \ l:nextgroups
        \ l:cfg.mathmode ? 'contained' : ''

  " Define default highlight rule
  execute 'highlight def link' l:group_cmd
        \ !empty(l:cfg.hlgroup)
        \   ? l:cfg.hlgroup
        \   : l:pre . 'Cmd'
endfunction

" }}}1
function! vimtex#syntax#core#new_cmd_with_concealed_delims(cfg) abort " {{{1
  if empty(get(a:cfg, 'name')) | return | endif

  " Parse options/config
  let l:cfg = extend({
        \ 'mathmode': v:false,
        \ 'argstyle': '',
        \ 'argspell': v:true,
        \ 'nargs': 1,
        \ 'cchar_open': '',
        \ 'cchar_mid': '',
        \ 'cchar_close': '',
        \ 'hlgroup': '',
        \}, a:cfg)

  let l:pre = l:cfg.mathmode ? 'texMath' : 'tex'
  let l:name = 'C' . toupper(l:cfg.name[0]) . l:cfg.name[1:]
  let l:group_cmd = l:pre . 'Cmd' . l:name
  let l:group_arg1 = l:pre . l:name . 'Arg'
  let l:group_arg2 = l:pre . l:name . 'Arg2'
  let l:group_delims = l:pre . l:name . 'ConcealedDelim'

  if l:cfg.mathmode
    let l:contains = '@texClusterMath'
    execute 'syntax cluster texClusterMath add=' . l:group_cmd
  elseif !l:cfg.argspell
    let l:contains = 'TOP,@Spell'
  else
    let l:contains = 'TOP,@NoSpell'
  endif

  execute 'syntax match' l:group_cmd
        \ '"\v\\' . get(l:cfg, 'cmdre', l:cfg.name . '>') . '"'
        \ l:cfg.mathmode ? 'contained' : ''
        \ empty(l:cfg.cchar_open)
        \   ? 'conceal'
        \   : 'conceal cchar=' . l:cfg.cchar_open
        \ 'skipwhite nextgroup=' . l:group_arg1

  if l:cfg.nargs == 1
    execute 'syntax region' l:group_arg1
          \ 'matchgroup=' . l:group_delims
          \ empty(l:cfg.cchar_close)
          \   ? 'concealends'
          \   : 'concealends cchar=' . l:cfg.cchar_close
          \ 'start="{" skip="\%#=1\\[\\\}]" end="}"'
          \ 'contained contains=' . l:contains
  else
    execute 'syntax region' l:group_arg1
          \ 'matchgroup=' . l:group_delims
          \ empty(l:cfg.cchar_mid)
          \   ? 'concealends'
          \   : 'concealends cchar=' . l:cfg.cchar_mid
          \ 'start="{" skip="\%#=1\\[\\\}]" end="}"'
          \ 'contained contains=' . l:contains
          \ 'skipwhite nextgroup=' . l:group_arg2

    execute 'syntax region' l:group_arg2
          \ 'matchgroup=' . l:group_delims
          \ empty(l:cfg.cchar_close)
          \   ? 'concealends'
          \   : 'concealends cchar=' . l:cfg.cchar_close
          \ 'start="{" skip="\%#=1\\[\\\}]" end="}"'
          \ 'contained contains=' . l:contains
  endif

  " Define default highlight rule
  execute 'highlight def link' l:group_cmd
        \ !empty(l:cfg.hlgroup)
        \   ? l:cfg.hlgroup
        \   : l:pre . 'Cmd'
  execute 'highlight def link' l:group_delims 'texRefConcealedDelim'

  let l:style = get({
        \ 'bold': 'texStyleBold',
        \ 'ital': 'texStyleItal',
        \ 'under': 'texStyleUnder',
        \ 'boldital': 'texStyleBoth',
        \ 'boldunder': 'texStyleBoldUnder',
        \ 'italunder': 'texStyleItalUnder',
        \ 'bolditalunder': 'texStyleBoldItalUnder',
        \}, l:cfg.argstyle,
        \ l:cfg.mathmode ? 'texMathArg' : '')
  if !empty(l:style)
    execute 'highlight def link' l:group_arg1 l:style
    if l:cfg.nargs > 1
      execute 'highlight def link' l:group_arg2 l:style
    endif
  endif
endfunction

" }}}1
function! vimtex#syntax#core#new_env(cfg) abort " {{{1
  let l:cfg = extend({
        \ 'name': '',
        \ 'region': '',
        \ 'math': v:false,
        \ 'math_nextgroup': '',
        \ 'starred': v:false,
        \ 'transparent': v:false,
        \ 'opts': '',
        \ 'contains': '',
        \ 'nested': '',
        \ '__predicate': '',
        \}, a:cfg)

  if type(l:cfg.nested) == v:t_dict && !empty(l:cfg.nested)
    for [l:lang, l:predicate] in items(l:cfg.nested)
      let l:nested_cfg = deepcopy(l:cfg)
      let l:nested_cfg.nested = l:lang
      let l:nested_cfg.__predicate = l:predicate
      call vimtex#syntax#core#new_env(l:nested_cfg)
    endfor
    return
  endif

  let l:env_name = l:cfg.name . (l:cfg.starred ? '\*\?' : '')

  if l:cfg.math
    if ! empty(cfg.__predicate)
      throw 'predicates are not supported for math environments'
    endif

    let l:cfg.region = 'texMathZoneEnv'
    let l:options = 'keepend'

    let l:next = ''
    if !empty(l:cfg.math_nextgroup)
      let l:next = 'nextgroup=' . l:cfg.math_nextgroup . ' skipwhite skipnl'
    endif

    if has_key(s:custom_math_envs_by_next, l:next)
      let s:custom_math_envs_by_next[l:next] += [l:env_name]
      syntax clear texMathEnvBgnEnd
      for [l:i_next, l:envs] in items(s:custom_math_envs_by_next)
        execute 'syntax match texMathEnvBgnEnd'
              \ '"\%#=1\\\%(begin\|end\){\%(' . join(l:envs, '\|') . '\)}"'
              \ 'contained contains=texCmdMathEnv'
              \ l:i_next
      endfor
    else
      let s:custom_math_envs_by_next[l:next] = [l:env_name]
      execute 'syntax match texMathEnvBgnEnd'
            \ '"\%#=1\\\%(begin\|end\){' . l:env_name . '}"'
            \ 'contained contains=texCmdMathEnv'
            \ l:next
    endif
    let l:contains = 'contains=texMathEnvBgnEnd,@texClusterMath'

    if ! empty(s:custom_math_envs)
      syntax clear texMathError
      syntax clear texMathZoneEnv
    endif
    let s:custom_math_envs += [l:env_name]
    execute 'syntax match texMathError "\%#=1\\\%()\|]\|end{\%('
        \ . join(s:custom_math_envs, '\|')
        \ . '\|array\|[bBpvV]matrix\|split\|smallmatrix'
        \ . '\)}\)" display'

    execute 'syntax region texMathZoneEnv'
          \ 'start="\%#=1\\begin{\z(' . join(s:custom_math_envs, '\|') . '\)}"'
          \ 'end="\\end{\z1}"'
          \ 'contains=texMathEnvBgnEnd,@texClusterMath'
          \ 'keepend'

  else
    if l:cfg.region == 'texMathZoneEnv'
      throw "use {'math': 1} to define new texMathZoneEnv regions"
    endif

    if empty(l:cfg.region)
      let l:cfg.region = printf(
            \ 'tex%sZone',
            \ toupper(l:cfg.name[0]) . l:cfg.name[1:])
    endif

    let l:options = 'keepend'
    if l:cfg.transparent
      let l:options .= ' transparent'
    endif
    if !empty(l:cfg.opts)
      let l:options .= ' ' . l:cfg.opts
    endif

    let l:contains = 'contains=texCmdEnv'
    if !empty(l:cfg.contains)
      let l:contains .= ',' . l:cfg.contains
    endif

    if !empty(l:cfg.nested)
      let l:nested = vimtex#syntax#nested#include(l:cfg.nested)
      if !empty(l:nested)
        let l:contains .= ',' . l:nested
      else
        execute 'highlight def link' l:cfg.region 'texZone'
      endif
    endif

    let l:start = '\\begin{\z(' . l:env_name .'\)}'
    if !empty(l:cfg.__predicate)
      let l:start .= '\s*\[\_[^\]]\{-}' . l:cfg.__predicate . '\_[^\]]\{-}\]'
    endif

    execute 'syntax region' l:cfg.region
          \ 'start="' . l:start . '"'
          \ 'end="\\end{\z1}"'
          \ l:contains
          \ l:options
  endif
endfunction

let s:custom_math_envs = []
let s:custom_math_envs_by_next = {}

" }}}1

function! vimtex#syntax#core#conceal_cmd_pairs(cmd, pairs) abort " {{{1
  for [l:from, l:to] in a:pairs
    execute 'syntax match texMathSymbol'
          \ '"\%#=1\\' . a:cmd . '\%({\s*' . l:from . '\s*}\|\s\+' . l:from . '\)"'
          \ 'contained conceal cchar=' . l:to
  endfor
endfunction

" }}}1

function! vimtex#syntax#core#get_alphabet_map(type) abort " {{{1
  return get(s:alphabet_map, a:type, [])
endfunction

let s:alphabet_map = {
      \ 'bar': [
      \   ['a', 'ā'],
      \   ['e', 'ē'],
      \   ['g', 'ḡ'],
      \   ['i', 'ī'],
      \   ['o', 'ō'],
      \   ['u', 'ū'],
      \   ['A', 'Ā'],
      \   ['E', 'Ē'],
      \   ['G', 'Ḡ'],
      \   ['I', 'Ī'],
      \   ['O', 'Ō'],
      \   ['U', 'Ū'],
      \ ],
      \ 'dot': [
      \   ['A', 'Ȧ'],
      \   ['a', 'ȧ'],
      \   ['B', 'Ḃ'],
      \   ['b', 'ḃ'],
      \   ['C', 'Ċ'],
      \   ['c', 'ċ'],
      \   ['D', 'Ḋ'],
      \   ['d', 'ḋ'],
      \   ['E', 'Ė'],
      \   ['e', 'ė'],
      \   ['F', 'Ḟ'],
      \   ['f', 'ḟ'],
      \   ['G', 'Ġ'],
      \   ['g', 'ġ'],
      \   ['H', 'Ḣ'],
      \   ['h', 'ḣ'],
      \   ['I', 'İ'],
      \   ['M', 'Ṁ'],
      \   ['m', 'ṁ'],
      \   ['N', 'Ṅ'],
      \   ['n', 'ṅ'],
      \   ['O', 'Ȯ'],
      \   ['o', 'ȯ'],
      \   ['P', 'Ṗ'],
      \   ['p', 'ṗ'],
      \   ['R', 'Ṙ'],
      \   ['r', 'ṙ'],
      \   ['S', 'Ṡ'],
      \   ['s', 'ṡ'],
      \   ['T', 'Ṫ'],
      \   ['t', 'ṫ'],
      \   ['W', 'Ẇ'],
      \   ['w', 'ẇ'],
      \   ['X', 'Ẋ'],
      \   ['x', 'ẋ'],
      \   ['Y', 'Ẏ'],
      \   ['y', 'ẏ'],
      \   ['Z', 'Ż'],
      \   ['z', 'ż'],
      \ ],
      \ 'hat': [
      \   ['a', 'â'],
      \   ['A', 'Â'],
      \   ['c', 'ĉ'],
      \   ['C', 'Ĉ'],
      \   ['e', 'ê'],
      \   ['E', 'Ê'],
      \   ['g', 'ĝ'],
      \   ['G', 'Ĝ'],
      \   ['i', 'î'],
      \   ['I', 'Î'],
      \   ['o', 'ô'],
      \   ['O', 'Ô'],
      \   ['s', 'ŝ'],
      \   ['S', 'Ŝ'],
      \   ['u', 'û'],
      \   ['U', 'Û'],
      \   ['w', 'ŵ'],
      \   ['W', 'Ŵ'],
      \   ['y', 'ŷ'],
      \   ['Y', 'Ŷ'],
      \ ],
      \ 'fraktur': [
      \   ['a', '𝔞'],
      \   ['b', '𝔟'],
      \   ['c', '𝔠'],
      \   ['d', '𝔡'],
      \   ['e', '𝔢'],
      \   ['f', '𝔣'],
      \   ['g', '𝔤'],
      \   ['h', '𝔥'],
      \   ['i', '𝔦'],
      \   ['j', '𝔧'],
      \   ['k', '𝔨'],
      \   ['l', '𝔩'],
      \   ['m', '𝔪'],
      \   ['n', '𝔫'],
      \   ['o', '𝔬'],
      \   ['p', '𝔭'],
      \   ['q', '𝔮'],
      \   ['r', '𝔯'],
      \   ['s', '𝔰'],
      \   ['t', '𝔱'],
      \   ['u', '𝔲'],
      \   ['v', '𝔳'],
      \   ['w', '𝔴'],
      \   ['x', '𝔵'],
      \   ['y', '𝔶'],
      \   ['z', '𝔷'],
      \   ['A', '𝔄'],
      \   ['B', '𝔅'],
      \   ['C', 'ℭ'],
      \   ['D', '𝔇'],
      \   ['E', '𝔈'],
      \   ['F', '𝔉'],
      \   ['G', '𝔊'],
      \   ['H', 'ℌ'],
      \   ['I', 'ℑ'],
      \   ['J', '𝔍'],
      \   ['K', '𝔎'],
      \   ['L', '𝔏'],
      \   ['M', '𝔐'],
      \   ['N', '𝔑'],
      \   ['O', '𝔒'],
      \   ['P', '𝔓'],
      \   ['Q', '𝔔'],
      \   ['R', 'ℜ'],
      \   ['S', '𝔖'],
      \   ['T', '𝔗'],
      \   ['U', '𝔘'],
      \   ['V', '𝔙'],
      \   ['W', '𝔚'],
      \   ['X', '𝔛'],
      \   ['Y', '𝔜'],
      \   ['Z', 'ℨ'],
      \ ],
      \ 'fraktur_bold': [
      \   ['a', '𝖆'],
      \   ['b', '𝖇'],
      \   ['c', '𝖈'],
      \   ['d', '𝖉'],
      \   ['e', '𝖊'],
      \   ['f', '𝖋'],
      \   ['g', '𝖌'],
      \   ['h', '𝖍'],
      \   ['i', '𝖎'],
      \   ['j', '𝖏'],
      \   ['k', '𝖐'],
      \   ['l', '𝖑'],
      \   ['m', '𝖒'],
      \   ['n', '𝖓'],
      \   ['o', '𝖔'],
      \   ['p', '𝖕'],
      \   ['q', '𝖖'],
      \   ['r', '𝖗'],
      \   ['s', '𝖘'],
      \   ['t', '𝖙'],
      \   ['u', '𝖚'],
      \   ['v', '𝖛'],
      \   ['w', '𝖜'],
      \   ['x', '𝖝'],
      \   ['y', '𝖞'],
      \   ['z', '𝖟'],
      \   ['A', '𝕬'],
      \   ['B', '𝕭'],
      \   ['C', '𝕮'],
      \   ['D', '𝕯'],
      \   ['E', '𝕰'],
      \   ['F', '𝕱'],
      \   ['G', '𝕲'],
      \   ['H', '𝕳'],
      \   ['I', '𝕴'],
      \   ['J', '𝕵'],
      \   ['K', '𝕶'],
      \   ['L', '𝕷'],
      \   ['M', '𝕸'],
      \   ['N', '𝕹'],
      \   ['O', '𝕺'],
      \   ['P', '𝕻'],
      \   ['Q', '𝕼'],
      \   ['R', '𝕽'],
      \   ['S', '𝕾'],
      \   ['T', '𝕿'],
      \   ['U', '𝖀'],
      \   ['V', '𝖁'],
      \   ['W', '𝖂'],
      \   ['X', '𝖃'],
      \   ['Y', '𝖄'],
      \   ['Z', '𝖅'],
      \ ],
      \ 'script': [
      \   ['a', '𝒶'],
      \   ['b', '𝒷'],
      \   ['c', '𝒸'],
      \   ['d', '𝒹'],
      \   ['e', 'ℯ'],
      \   ['f', '𝒻'],
      \   ['g', 'ℊ'],
      \   ['h', '𝒽'],
      \   ['i', '𝒾'],
      \   ['j', '𝒿'],
      \   ['k', '𝓀'],
      \   ['l', '𝓁'],
      \   ['m', '𝓂'],
      \   ['n', '𝓃'],
      \   ['o', 'ℴ'],
      \   ['p', '𝓅'],
      \   ['q', '𝓆'],
      \   ['r', '𝓇'],
      \   ['s', '𝓈'],
      \   ['t', '𝓉'],
      \   ['u', '𝓊'],
      \   ['v', '𝓋'],
      \   ['w', '𝓌'],
      \   ['x', '𝓍'],
      \   ['y', '𝓎'],
      \   ['z', '𝓏'],
      \   ['A', '𝒜'],
      \   ['B', 'ℬ'],
      \   ['C', '𝒞'],
      \   ['D', '𝒟'],
      \   ['E', 'ℰ'],
      \   ['F', 'ℱ'],
      \   ['G', '𝒢'],
      \   ['H', 'ℋ'],
      \   ['I', 'ℐ'],
      \   ['J', '𝒥'],
      \   ['K', '𝒦'],
      \   ['L', 'ℒ'],
      \   ['M', 'ℳ'],
      \   ['N', '𝒩'],
      \   ['O', '𝒪'],
      \   ['P', '𝒫'],
      \   ['Q', '𝒬'],
      \   ['R', 'ℛ'],
      \   ['S', '𝒮'],
      \   ['T', '𝒯'],
      \   ['U', '𝒰'],
      \   ['V', '𝒱'],
      \   ['W', '𝒲'],
      \   ['X', '𝒳'],
      \   ['Y', '𝒴'],
      \   ['Z', '𝒵'],
      \ ],
      \ 'script_bold': [
      \   ['a', '𝓪'],
      \   ['b', '𝓫'],
      \   ['c', '𝓬'],
      \   ['d', '𝓭'],
      \   ['e', '𝓮'],
      \   ['f', '𝓯'],
      \   ['g', '𝓰'],
      \   ['h', '𝓱'],
      \   ['i', '𝓲'],
      \   ['j', '𝓳'],
      \   ['k', '𝓴'],
      \   ['l', '𝓵'],
      \   ['m', '𝓶'],
      \   ['n', '𝓷'],
      \   ['o', '𝓸'],
      \   ['p', '𝓹'],
      \   ['q', '𝓺'],
      \   ['r', '𝓻'],
      \   ['s', '𝓼'],
      \   ['t', '𝓽'],
      \   ['u', '𝓾'],
      \   ['v', '𝓿'],
      \   ['w', '𝔀'],
      \   ['x', '𝔁'],
      \   ['y', '𝔂'],
      \   ['z', '𝔃'],
      \   ['A', '𝓐'],
      \   ['B', '𝓑'],
      \   ['C', '𝓒'],
      \   ['D', '𝓓'],
      \   ['E', '𝓔'],
      \   ['F', '𝓕'],
      \   ['G', '𝓖'],
      \   ['H', '𝓗'],
      \   ['I', '𝓘'],
      \   ['J', '𝓙'],
      \   ['K', '𝓚'],
      \   ['L', '𝓛'],
      \   ['M', '𝓜'],
      \   ['N', '𝓝'],
      \   ['O', '𝓞'],
      \   ['P', '𝓟'],
      \   ['Q', '𝓠'],
      \   ['R', '𝓡'],
      \   ['S', '𝓢'],
      \   ['T', '𝓣'],
      \   ['U', '𝓤'],
      \   ['V', '𝓥'],
      \   ['W', '𝓦'],
      \   ['X', '𝓧'],
      \   ['Y', '𝓨'],
      \   ['Z', '𝓩'],
      \ ],
      \ 'double': [
      \   ['0', '𝟘'],
      \   ['1', '𝟙'],
      \   ['2', '𝟚'],
      \   ['3', '𝟛'],
      \   ['4', '𝟜'],
      \   ['5', '𝟝'],
      \   ['6', '𝟞'],
      \   ['7', '𝟟'],
      \   ['8', '𝟠'],
      \   ['9', '𝟡'],
      \   ['A', '𝔸'],
      \   ['B', '𝔹'],
      \   ['C', 'ℂ'],
      \   ['D', '𝔻'],
      \   ['E', '𝔼'],
      \   ['F', '𝔽'],
      \   ['G', '𝔾'],
      \   ['H', 'ℍ'],
      \   ['I', '𝕀'],
      \   ['J', '𝕁'],
      \   ['K', '𝕂'],
      \   ['L', '𝕃'],
      \   ['M', '𝕄'],
      \   ['N', 'ℕ'],
      \   ['O', '𝕆'],
      \   ['P', 'ℙ'],
      \   ['Q', 'ℚ'],
      \   ['R', 'ℝ'],
      \   ['S', '𝕊'],
      \   ['T', '𝕋'],
      \   ['U', '𝕌'],
      \   ['V', '𝕍'],
      \   ['W', '𝕎'],
      \   ['X', '𝕏'],
      \   ['Y', '𝕐'],
      \   ['Z', 'ℤ'],
      \   ['a', '𝕒'],
      \   ['b', '𝕓'],
      \   ['c', '𝕔'],
      \   ['d', '𝕕'],
      \   ['e', '𝕖'],
      \   ['f', '𝕗'],
      \   ['g', '𝕘'],
      \   ['h', '𝕙'],
      \   ['i', '𝕚'],
      \   ['j', '𝕛'],
      \   ['k', '𝕜'],
      \   ['l', '𝕝'],
      \   ['m', '𝕞'],
      \   ['n', '𝕟'],
      \   ['o', '𝕠'],
      \   ['p', '𝕡'],
      \   ['q', '𝕢'],
      \   ['r', '𝕣'],
      \   ['s', '𝕤'],
      \   ['t', '𝕥'],
      \   ['u', '𝕦'],
      \   ['v', '𝕧'],
      \   ['w', '𝕨'],
      \   ['x', '𝕩'],
      \   ['y', '𝕪'],
      \   ['z', '𝕫'],
      \ ],
      \}

" }}}1


function! s:match_bold_italic() abort " {{{1
  let [l:conceal, l:concealends] =
        \ (g:vimtex_syntax_conceal.styles ? ['conceal', 'concealends'] : ['', ''])

  syntax cluster texClusterBold     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold
  syntax cluster texClusterItal     contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleBoldItal
  syntax cluster texClusterItalBold contains=TOP,@NoSpell,texCmdStyleItal,texCmdStyleBold,texCmdStyleItalBold,texCmdStyleBoldItal

  let l:map = {
        \ 'texCmdStyleBold': 'texStyleBold',
        \ 'texCmdStyleBoldItal': 'texStyleBoth',
        \ 'texCmdStyleItal': 'texStyleItal',
        \ 'texCmdStyleItalBold': 'texStyleBoth',
        \}

  for [l:group, l:pattern] in [
        \ ['texCmdStyleBoldItal', 'emph'],
        \ ['texCmdStyleBoldItal', 'textit'],
        \ ['texCmdStyleBoldItal', 'textsl'],
        \ ['texCmdStyleItalBold', 'textbf'],
        \ ['texCmdStyleBold', 'textbf'],
        \ ['texCmdStyleItal', 'emph'],
        \ ['texCmdStyleItal', 'textit'],
        \ ['texCmdStyleItal', 'textsl'],
        \]
    execute 'syntax match' l:group '"\%#=1\\' . l:pattern . '\>"'
          \ 'skipwhite skipnl nextgroup=' . l:map[l:group]
          \ l:conceal
  endfor

  execute 'syntax region texStyleBold matchgroup=texDelim start="{" end="}" contained contains=@texClusterBold' l:concealends
  execute 'syntax region texStyleItal matchgroup=texDelim start="{" end="}" contained contains=@texClusterItal' l:concealends
  execute 'syntax region texStyleBoth matchgroup=texDelim start="{" end="}" contained contains=@texClusterItalBold' l:concealends

  if g:vimtex_syntax_conceal.styles
    syntax match texCmdStyle "\%#=1\v\\text%(rm|tt|up|normal|sf|sc)>"
          \ conceal skipwhite skipnl nextgroup=texStyleArgConc
    syntax region texStyleArgConc matchgroup=texDelim start="{" end="}"
          \ contained contains=TOP,@NoSpell concealends
  endif
endfunction

" }}}1
function! s:match_bold_italic_math() abort " {{{1
  let [l:conceal, l:concealends] =
        \ (g:vimtex_syntax_conceal.styles ? ['conceal', 'concealends'] : ['', ''])

  let l:map = {
        \ 'texMathCmdStyleBold': 'texMathStyleBold',
        \ 'texMathCmdStyleItal': 'texMathStyleItal',
        \ 'texMathCmdStyleBoth': 'texMathStyleBoth',
        \}

  for [l:group, l:pattern] in [
        \ ['texMathCmdStyleBold', 'bm'],
        \ ['texMathCmdStyleBold', 'mathbf'],
        \ ['texMathCmdStyleItal', 'mathit'],
        \ ['texMathCmdStyleBoth', 'mathbfit'],
        \]
    execute 'syntax match' l:group '"\%#=1\\' . l:pattern . '\>"'
          \ 'contained skipwhite nextgroup=' . l:map[l:group]
          \ l:conceal
  endfor

  execute 'syntax region texMathStyleBold matchgroup=texDelim start="{" end="}" contained contains=@texClusterMath' l:concealends
  execute 'syntax region texMathStyleItal matchgroup=texDelim start="{" end="}" contained contains=@texClusterMath' l:concealends
  execute 'syntax region texMathStyleBoth matchgroup=texDelim start="{" end="}" contained contains=@texClusterMath' l:concealends

  if g:vimtex_syntax_conceal.styles
    syntax match texMathCmdStyle "\%#=1\v\\math%(rm|tt|normal|sf)>"
          \ contained conceal skipwhite nextgroup=texMathStyleConcArg
    syntax region texMathStyleConcArg matchgroup=texDelim start="{" end="}"
          \ contained contains=@texClusterMath concealends

    for l:re_cmd in [
          \ 'text%(normal|rm|up|tt|sf|sc)?',
          \ 'intertext',
          \ '[mf]box',
          \]
      execute 'syntax match texMathCmdText'
            \ '"\v\\' . l:re_cmd . '>"'
            \ 'contained skipwhite nextgroup=texMathTextConcArg'
            \ 'conceal'
    endfor
    syntax region texMathTextConcArg matchgroup=texDelim start="{" end="}"
          \ contained contains=TOP,@NoSpell concealends
  endif
endfunction

" }}}1

function! s:match_math_sub_super() abort " {{{1
  if !g:vimtex_syntax_conceal.math_super_sub | return | endif

  " This feature does not work unless &encoding = 'utf-8'
  if &encoding !=# 'utf-8'
    call vimtex#log#warning(
          \ "Conceals for math_super_sub require `set encoding='utf-8'`!")
    return
  endif

  execute 'syntax match texMathSuperSub'
        \ '"\^\%(' . s:re_super . '\)"'
        \ 'conceal contained contains=texMathSuper'
  execute 'syntax match texMathSuperSub'
        \ '"\^{\%(' . s:re_super . '\|\s\)\+}"'
        \ 'conceal contained contains=texMathSuper'
  for [l:from, l:to] in s:map_super
    execute 'syntax match texMathSuper'
          \ '"' . l:from . '"'
          \ 'contained conceal cchar=' . l:to
  endfor

  execute 'syntax match texMathSuperSub'
        \ '"_\%(' . s:re_sub . '\)"'
        \ 'conceal contained contains=texMathSub'
  execute 'syntax match texMathSuperSub'
        \ '"_{\%(' . s:re_sub . '\|\s\)\+}"'
        \ 'conceal contained contains=texMathSub'
  for [l:from, l:to] in copy(s:map_sub)
    execute 'syntax match texMathSub'
          \ '"' . l:from . '"'
          \ 'contained conceal cchar=' . l:to
  endfor
endfunction

let s:re_sub =
      \ '[-+=()0-9aehijklmnoprstuvx]\|\\\%('
      \ .. join([
      \     'beta', 'gamma', 'rho', 'phi', 'chi'
      \ ], '\|') . '\)\>'
let s:re_super =
      \ '[-+=()<>:;0-9a-qr-zA-FG-QRTUVW]\|\\\%('
      \ .. join([
      \     'beta', 'gamma', 'delta', 'epsilon', 'theta', 'iota', 'phi', 'chi'
      \ ], '\|') . '\)\>'

let s:map_sub = [
      \ ['\\beta\>',  'ᵦ'],
      \ ['\\gamma\>', 'ᵧ'],
      \ ['\\rho\>',   'ᵨ'],
      \ ['\\phi\>',   'ᵩ'],
      \ ['\\chi\>',   'ᵪ'],
      \ ['(',         '₍'],
      \ [')',         '₎'],
      \ ['+',         '₊'],
      \ ['-',         '₋'],
      \ ['=',         '₌'],
      \ ['0',         '₀'],
      \ ['1',         '₁'],
      \ ['2',         '₂'],
      \ ['3',         '₃'],
      \ ['4',         '₄'],
      \ ['5',         '₅'],
      \ ['6',         '₆'],
      \ ['7',         '₇'],
      \ ['8',         '₈'],
      \ ['9',         '₉'],
      \ ['a',         'ₐ'],
      \ ['e',         'ₑ'],
      \ ['h',         'ₕ'],
      \ ['i',         'ᵢ'],
      \ ['j',         'ⱼ'],
      \ ['k',         'ₖ'],
      \ ['l',         'ₗ'],
      \ ['m',         'ₘ'],
      \ ['n',         'ₙ'],
      \ ['o',         'ₒ'],
      \ ['p',         'ₚ'],
      \ ['r',         'ᵣ'],
      \ ['s',         'ₛ'],
      \ ['t',         'ₜ'],
      \ ['u',         'ᵤ'],
      \ ['v',         'ᵥ'],
      \ ['x',         'ₓ'],
      \]

let s:map_super = [
      \ ['\\beta\>',    'ᵝ'],
      \ ['\\gamma\>',   'ᵞ'],
      \ ['\\delta\>',   'ᵟ'],
      \ ['\\epsilon\>', 'ᵋ'],
      \ ['\\theta\>',   'ᶿ'],
      \ ['\\iota\>',    'ᶥ'],
      \ ['\\phi\>',     'ᵠ'],
      \ ['\\chi\>',     'ᵡ'],
      \ ['(',  '⁽'],
      \ [')',  '⁾'],
      \ ['+',  '⁺'],
      \ ['-',  '⁻'],
      \ ['=',  '⁼'],
      \ [':',  '︓'],
      \ [';',  '︔'],
      \ ['<',  '˂'],
      \ ['>',  '˃'],
      \ ['0',  '⁰'],
      \ ['1',  '¹'],
      \ ['2',  '²'],
      \ ['3',  '³'],
      \ ['4',  '⁴'],
      \ ['5',  '⁵'],
      \ ['6',  '⁶'],
      \ ['7',  '⁷'],
      \ ['8',  '⁸'],
      \ ['9',  '⁹'],
      \ ['a',  'ᵃ'],
      \ ['b',  'ᵇ'],
      \ ['c',  'ᶜ'],
      \ ['d',  'ᵈ'],
      \ ['e',  'ᵉ'],
      \ ['f',  'ᶠ'],
      \ ['g',  'ᵍ'],
      \ ['h',  'ʰ'],
      \ ['i',  'ⁱ'],
      \ ['j',  'ʲ'],
      \ ['k',  'ᵏ'],
      \ ['l',  'ˡ'],
      \ ['m',  'ᵐ'],
      \ ['n',  'ⁿ'],
      \ ['o',  'ᵒ'],
      \ ['p',  'ᵖ'],
      \ ['q',  '𐞥'],
      \ ['r',  'ʳ'],
      \ ['s',  'ˢ'],
      \ ['t',  'ᵗ'],
      \ ['u',  'ᵘ'],
      \ ['v',  'ᵛ'],
      \ ['w',  'ʷ'],
      \ ['x',  'ˣ'],
      \ ['y',  'ʸ'],
      \ ['z',  'ᶻ'],
      \ ['A',  'ᴬ'],
      \ ['B',  'ᴮ'],
      \ ['C',  'ꟲ'],
      \ ['D',  'ᴰ'],
      \ ['E',  'ᴱ'],
      \ ['F',  'ꟳ'],
      \ ['G',  'ᴳ'],
      \ ['H',  'ᴴ'],
      \ ['I',  'ᴵ'],
      \ ['J',  'ᴶ'],
      \ ['K',  'ᴷ'],
      \ ['L',  'ᴸ'],
      \ ['M',  'ᴹ'],
      \ ['N',  'ᴺ'],
      \ ['O',  'ᴼ'],
      \ ['P',  'ᴾ'],
      \ ['Q',  'ꟴ'],
      \ ['R',  'ᴿ'],
      \ ['T',  'ᵀ'],
      \ ['U',  'ᵁ'],
      \ ['V',  'ⱽ'],
      \ ['W',  'ᵂ'],
      \]

" }}}1
function! s:match_math_symbols() abort " {{{1
  " Many of these symbols were contributed by Björn Winckler
  if !g:vimtex_syntax_conceal.math_symbols | return | endif

  syntax match texMathSymbol "\\|"        contained conceal cchar=‖
  syntax match texMathSymbol "\\sqrt\[3]" contained conceal cchar=∛
  syntax match texMathSymbol "\\sqrt\[4]" contained conceal cchar=∜

  for [l:cmd, l:symbol] in s:cmd_symbols
    execute 'syntax match texMathSymbol'
          \ '"\%#=1\\' . l:cmd . '\ze\%(\>\|[_^]\)"'
          \ 'contained conceal cchar=' . l:symbol
  endfor

  for [l:cmd, l:alphabet_map] in [
        \ ['bar', 'bar'],
        \ ['hat', 'hat'],
        \ ['dot', 'dot'],
        \ ['\%(var\)\?math\%(bb\%(b\|m\%(ss\|tt\)\?\)\?\|ds\)', 'double'],
        \ ['mathfrak', 'fraktur'],
        \ ['math\%(scr\|cal\)', 'script'],
        \ ['mathbffrak', 'fraktur_bold'],
        \ ['mathbf\%(scr\|cal\)', 'script_bold'],
        \]
    let l:pairs = vimtex#syntax#core#get_alphabet_map(l:alphabet_map)
    call vimtex#syntax#core#conceal_cmd_pairs(l:cmd, l:pairs)
  endfor
endfunction

let s:cmd_symbols = [
      \ ['aleph', 'ℵ'],
      \ ['amalg', '∐'],
      \ ['angle', '∠'],
      \ ['approx', '≈'],
      \ ['ast', '∗'],
      \ ['asymp', '≍'],
      \ ['backslash', '∖'],
      \ ['bigcap', '∩'],
      \ ['bigcirc', '○'],
      \ ['bigcup', '∪'],
      \ ['bigodot', '⊙'],
      \ ['bigoplus', '⊕'],
      \ ['bigotimes', '⊗'],
      \ ['bigsqcup', '⊔'],
      \ ['bigtriangledown', '∇'],
      \ ['bigtriangleup', '∆'],
      \ ['bigvee', '⋁'],
      \ ['bigwedge', '⋀'],
      \ ['bot', '⊥'],
      \ ['bowtie', '⋈'],
      \ ['bullet', '•'],
      \ ['cap', '∩'],
      \ ['cdot', '·'],
      \ ['cdots', '⋯'],
      \ ['circ', '∘'],
      \ ['clubsuit', '♣'],
      \ ['cong', '≅'],
      \ ['coprod', '∐'],
      \ ['copyright', '©'],
      \ ['cup', '∪'],
      \ ['dagger', '†'],
      \ ['dashv', '⊣'],
      \ ['ddagger', '‡'],
      \ ['ddots', '⋱'],
      \ ['diamond', '⋄'],
      \ ['diamondsuit', '♢'],
      \ ['div', '÷'],
      \ ['doteq', '≐'],
      \ ['dots', '…'],
      \ ['downarrow', '↓'],
      \ ['Downarrow', '⇓'],
      \ ['ell', 'ℓ'],
      \ ['emptyset', 'Ø'],
      \ ['equiv', '≡'],
      \ ['exists', '∃'],
      \ ['flat', '♭'],
      \ ['forall', '∀'],
      \ ['frown', '⁔'],
      \ ['ge', '≥'],
      \ ['geq', '≥'],
      \ ['gets', '←'],
      \ ['gg', '⟫'],
      \ ['hbar', 'ℏ'],
      \ ['heartsuit', '♡'],
      \ ['hookleftarrow', '↩'],
      \ ['hookrightarrow', '↪'],
      \ ['iff', '⇔'],
      \ ['Im', 'ℑ'],
      \ ['imath', 'ɩ'],
      \ ['in', '∈'],
      \ ['increment', '∆'],
      \ ['infty', '∞'],
      \ ['int', '∫'],
      \ ['iint', '∬'],
      \ ['iiint', '∭'],
      \ ['jmath', '𝚥'],
      \ ['land', '∧'],
      \ ['lnot', '¬'],
      \ ['lceil', '⌈'],
      \ ['ldots', '…'],
      \ ['le', '≤'],
      \ ['leftarrow', '←'],
      \ ['Leftarrow', '⇐'],
      \ ['leftharpoondown', '↽'],
      \ ['leftharpoonup', '↼'],
      \ ['leftrightarrow', '↔'],
      \ ['Leftrightarrow', '⇔'],
      \ ['lhd', '◁'],
      \ ['rhd', '▷'],
      \ ['leq', '≤'],
      \ ['ll', '≪'],
      \ ['lmoustache', '╭'],
      \ ['lor', '∨'],
      \ ['mapsto', '↦'],
      \ ['mbfnabla', '𝛁'],
      \ ['mid', '∣'],
      \ ['models', '⊨'],
      \ ['mp', '∓'],
      \ ['nabla', '∇'],
      \ ['natural', '♮'],
      \ ['ne', '≠'],
      \ ['nearrow', '↗'],
      \ ['neg', '¬'],
      \ ['neq', '≠'],
      \ ['ni', '∋'],
      \ ['notin', '∉'],
      \ ['nwarrow', '↖'],
      \ ['odot', '⊙'],
      \ ['oint', '∮'],
      \ ['ominus', '⊖'],
      \ ['oplus', '⊕'],
      \ ['oslash', '⊘'],
      \ ['otimes', '⊗'],
      \ ['owns', '∋'],
      \ ['P', '¶'],
      \ ['parallel', '║'],
      \ ['partial', '∂'],
      \ ['perp', '⊥'],
      \ ['pm', '±'],
      \ ['prec', '≺'],
      \ ['preceq', '⪯'],
      \ ['prime', '′'],
      \ ['prod', '∏'],
      \ ['propto', '∝'],
      \ ['rceil', '⌉'],
      \ ['Re', 'ℜ'],
      \ ['rightarrow', '→'],
      \ ['Rightarrow', '⇒'],
      \ ['leftarrow', '←'],
      \ ['Leftarrow', '⇐'],
      \ ['rightleftharpoons', '⇌'],
      \ ['rmoustache', '╮'],
      \ ['S', '§'],
      \ ['searrow', '↘'],
      \ ['setminus', '∖'],
      \ ['sharp', '♯'],
      \ ['sim', '∼'],
      \ ['simeq', '⋍'],
      \ ['smile', '‿'],
      \ ['spadesuit', '♠'],
      \ ['sqcap', '⊓'],
      \ ['sqcup', '⊔'],
      \ ['sqsubset', '⊏'],
      \ ['sqsubseteq', '⊑'],
      \ ['sqsupset', '⊐'],
      \ ['sqsupseteq', '⊒'],
      \ ['star', '✫'],
      \ ['subset', '⊂'],
      \ ['subseteq', '⊆'],
      \ ['succ', '≻'],
      \ ['succeq', '⪰'],
      \ ['sum', '∑'],
      \ ['supset', '⊃'],
      \ ['supseteq', '⊇'],
      \ ['surd', '√'],
      \ ['swarrow', '↙'],
      \ ['times', '×'],
      \ ['to', '→'],
      \ ['top', '⊤'],
      \ ['triangle', '∆'],
      \ ['triangleleft', '⊲'],
      \ ['triangleright', '⊳'],
      \ ['uparrow', '↑'],
      \ ['Uparrow', '⇑'],
      \ ['updownarrow', '↕'],
      \ ['Updownarrow', '⇕'],
      \ ['vdash', '⊢'],
      \ ['vdots', '⋮'],
      \ ['vee', '∨'],
      \ ['wedge', '∧'],
      \ ['wp', '℘'],
      \ ['wr', '≀'],
      \ ['implies', '⇒'],
      \ ['choose', 'C'],
      \ ['sqrt', '√'],
      \ ['colon', ':'],
      \ ['coloneqq', '≔'],
      \]

let s:cmd_symbols += &ambiwidth ==# 'double'
      \ ? [
      \     ['gg', '≫'],
      \     ['ll', '≪'],
      \ ]
      \ : [
      \     ['gg', '⟫'],
      \     ['ll', '⟪'],
      \ ]

" }}}1
function! s:match_math_fracs() abort " {{{1
  if !g:vimtex_syntax_conceal.math_fracs | return | endif

  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(2\|{2}\)" contained conceal cchar=½
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(3\|{3}\)" contained conceal cchar=⅓
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(2\|{2}\)\s*\%(3\|{3}\)" contained conceal cchar=⅔
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(4\|{4}\)" contained conceal cchar=¼
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(5\|{5}\)" contained conceal cchar=⅕
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(2\|{2}\)\s*\%(5\|{5}\)" contained conceal cchar=⅖
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(3\|{3}\)\s*\%(5\|{5}\)" contained conceal cchar=⅗
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(4\|{4}\)\s*\%(5\|{5}\)" contained conceal cchar=⅘
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(6\|{6}\)" contained conceal cchar=⅙
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(5\|{5}\)\s*\%(6\|{6}\)" contained conceal cchar=⅚
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(1\|{1}\)\s*\%(8\|{8}\)" contained conceal cchar=⅛
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(3\|{3}\)\s*\%(8\|{8}\)" contained conceal cchar=⅜
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(5\|{5}\)\s*\%(8\|{8}\)" contained conceal cchar=⅝
  syntax match texMathSymbol "\%#=1\\[dt]\?frac\s*\%(7\|{7}\)\s*\%(8\|{8}\)" contained conceal cchar=⅞
endfunction

" }}}1
function! s:match_math_delims() abort " {{{1
  syntax match texMathDelimMod contained "\%#=1\\\%(left\|right\)\>" display
  syntax match texMathDelimMod contained "\%#=1\\[bB]igg\?[lr]\?\>" display
  syntax match texMathDelim contained "\%#=1\\[{}]" display

  syntax match texMathDelim contained "\%#=1\v\\%(
        \[lr]%([vV]ert|angle|brace|ceil|floor|group|moustache)
        \|backslash
        \|[uU]%(down)?parrow
        \|[dD]ownarrow
        \)>" display

  if !g:vimtex_syntax_conceal.math_delimiters || &encoding !=# 'utf-8'
    return
  endif

  syntax match texMathDelimMod contained conceal "\%#=1\\[bB]igg\?\>"

  syntax match texMathDelim contained conceal cchar=| "\%#=1\\left|\s\?"
  syntax match texMathDelim contained conceal cchar=| "\%#=1\\right|"
  syntax match texMathDelim contained conceal cchar=‖ "\%#=1\\left\\|\s\?"
  syntax match texMathDelim contained conceal cchar=‖ "\%#=1\\right\\|"
  syntax match texMathDelim contained conceal cchar=| "\%#=1\\lvert\>\s\?"
  syntax match texMathDelim contained conceal cchar=| "\%#=1\\rvert\>"
  syntax match texMathDelim contained conceal cchar=‖ "\%#=1\\lVert\>\s\?"
  syntax match texMathDelim contained conceal cchar=‖ "\%#=1\\rVert\>"
  syntax match texMathDelim contained conceal cchar=( "\%#=1\\left(\s\?"
  syntax match texMathDelim contained conceal cchar=) "\%#=1\\right)"
  syntax match texMathDelim contained conceal cchar=[ "\%#=1\\left\[\s\?"
  syntax match texMathDelim contained conceal cchar=] "\%#=1\\right]"
  syntax match texMathDelim contained conceal cchar={ "\%#=1\\{\s\?"
  syntax match texMathDelim contained conceal cchar=} "\%#=1\\}"
  syntax match texMathDelim contained conceal cchar={ "\%#=1\\left\\{\s\?"
  syntax match texMathDelim contained conceal cchar=} "\%#=1\\right\\}"
  syntax match texMathDelim contained conceal cchar={ "\%#=1\\lbrace\>\s\?"
  syntax match texMathDelim contained conceal cchar=} "\%#=1\\rbrace\>"
  syntax match texMathDelim contained conceal cchar=⟨ "\%#=1\\langle\>\s\?"
  syntax match texMathDelim contained conceal cchar=⟩ "\%#=1\\rangle\>"
  syntax match texMathDelim contained conceal cchar=⌊ "\%#=1\\lfloor\>\s\?"
  syntax match texMathDelim contained conceal cchar=⌋ "\%#=1\\rfloor\>"
  syntax match texMathDelim contained conceal cchar=< "\%#=1\\\%([bB]igg\?l\|left\)<\s\?"
  syntax match texMathDelim contained conceal cchar=> "\%#=1\\\%([bB]igg\?r\|right\)>"
  syntax match texMathDelim contained conceal cchar=( "\%#=1\\\%([bB]igg\?l\|left\)(\s\?"
  syntax match texMathDelim contained conceal cchar=) "\%#=1\\\%([bB]igg\?r\|right\))"
  syntax match texMathDelim contained conceal cchar=[ "\%#=1\\\%([bB]igg\?l\|left\)\[\s\?"
  syntax match texMathDelim contained conceal cchar=] "\%#=1\\\%([bB]igg\?r\|right\)]"
  syntax match texMathDelim contained conceal cchar={ "\%#=1\\\%([bB]igg\?l\|left\)\\{\s\?"
  syntax match texMathDelim contained conceal cchar=} "\%#=1\\\%([bB]igg\?r\|right\)\\}"
  syntax match texMathDelim contained conceal cchar={ "\%#=1\\\%([bB]igg\?l\|left\)\\lbrace\>\s\?"
  syntax match texMathDelim contained conceal cchar=} "\%#=1\\\%([bB]igg\?r\|right\)\\rbrace\>"
  syntax match texMathDelim contained conceal cchar=⌈ "\%#=1\\\%([bB]igg\?l\|left\)\\lceil\>\s\?"
  syntax match texMathDelim contained conceal cchar=⌉ "\%#=1\\\%([bB]igg\?r\|right\)\\rceil\>"
  syntax match texMathDelim contained conceal cchar=⌊ "\%#=1\\\%([bB]igg\?l\|left\)\\lfloor\>\s\?"
  syntax match texMathDelim contained conceal cchar=⌋ "\%#=1\\\%([bB]igg\?r\|right\)\\rfloor\>"
  syntax match texMathDelim contained conceal cchar=⌊ "\%#=1\\\%([bB]igg\?l\|left\)\\lgroup\>\s\?"
  syntax match texMathDelim contained conceal cchar=⌋ "\%#=1\\\%([bB]igg\?r\|right\)\\rgroup\>"
  syntax match texMathDelim contained conceal cchar=⎛ "\%#=1\\\%([bB]igg\?l\|left\)\\lmoustache\>\s\?"
  syntax match texMathDelim contained conceal cchar=⎞ "\%#=1\\\%([bB]igg\?r\|right\)\\rmoustache\>"
  syntax match texMathDelim contained conceal cchar=| "\%#=1\\\%([bB]igg\?l\|left\)|\s\?"
  syntax match texMathDelim contained conceal cchar=| "\%#=1\\\%([bB]igg\?r\|right\)|"
  syntax match texMathDelim contained conceal cchar=‖ "\%#=1\\\%([bB]igg\?l\|left\)\\|\s\?"
  syntax match texMathDelim contained conceal cchar=‖ "\%#=1\\\%([bB]igg\?r\|right\)\\|"
  syntax match texMathDelim contained conceal cchar=↓ "\%#=1\\\%([bB]igg\?l\|left\)\\downarrow\>\s\?"
  syntax match texMathDelim contained conceal cchar=↓ "\%#=1\\\%([bB]igg\?r\|right\)\\downarrow\>"
  syntax match texMathDelim contained conceal cchar=⇓ "\%#=1\\\%([bB]igg\?l\|left\)\\Downarrow\>\s\?"
  syntax match texMathDelim contained conceal cchar=⇓ "\%#=1\\\%([bB]igg\?r\|right\)\\Downarrow\>"
  syntax match texMathDelim contained conceal cchar=↑ "\%#=1\\\%([bB]igg\?l\|left\)\\uparrow\>\s\?"
  syntax match texMathDelim contained conceal cchar=↑ "\%#=1\\\%([bB]igg\?r\|right\)\\uparrow\>"
  syntax match texMathDelim contained conceal cchar=↑ "\%#=1\\\%([bB]igg\?l\|left\)\\Uparrow\>\s\?"
  syntax match texMathDelim contained conceal cchar=↑ "\%#=1\\\%([bB]igg\?r\|right\)\\Uparrow\>"
  syntax match texMathDelim contained conceal cchar=↕ "\%#=1\\\%([bB]igg\?l\|left\)\\updownarrow\>\s\?"
  syntax match texMathDelim contained conceal cchar=↕ "\%#=1\\\%([bB]igg\?r\|right\)\\updownarrow\>"
  syntax match texMathDelim contained conceal cchar=⇕ "\%#=1\\\%([bB]igg\?l\|left\)\\Updownarrow\>\s\?"
  syntax match texMathDelim contained conceal cchar=⇕ "\%#=1\\\%([bB]igg\?r\|right\)\\Updownarrow\>"

  if &ambiwidth ==# 'double'
    syntax match texMathDelim contained conceal cchar=〈 "\%#=1\\\%([bB]igg\?l\|left\)\\langle\>\s\?"
    syntax match texMathDelim contained conceal cchar=〉 "\%#=1\\\%([bB]igg\?r\|right\)\\rangle\>"
  else
    syntax match texMathDelim contained conceal cchar=⟨ "\%#=1\\\%([bB]igg\?l\|left\)\\langle\>\s\?"
    syntax match texMathDelim contained conceal cchar=⟩ "\%#=1\\\%([bB]igg\?r\|right\)\\rangle\>"
  endif
endfunction

" }}}1
function! s:match_math_unicode() abort " {{{1
  if !g:vimtex_syntax_match_unicode | return | endif
  syntax match texCmdGreek
        \ "[αβγδ𝝳𝛿𝛅𝞭ϵεζηθϑικλμνξπϖρϱσςτυϕφχψωΓΔΘΛΞΠΣΥΦΧΨΩ]" contained

  if !exists('s:re_math_symbols')
    let l:symbols = map(vimtex#util#uniq_unsorted(s:cmd_symbols), 'v:val[1]')
    call filter(l:symbols, 'v:val =~# "[^A-Za-z]"')
    let s:re_math_symbols = '"[' . join(l:symbols, '') . ']"'
  endif
  execute 'syntax match texMathSymbol' s:re_math_symbols 'contained'
endfunction

" }}}1
function! s:match_math_conceal_accents() abort " {{{1
  if !g:vimtex_syntax_conceal.accents | return | endif

  for [l:chr; l:targets] in s:map_accents
    for i in range(13)
      let l:target = l:targets[i]
      if empty(l:target) | continue | endif

      let l:accent = s:key_accents[i]
      let l:re_ws = l:accent =~# '^\\\\\a$' ? '\s\+' : '\s*'
      let l:re = l:accent . '\%(\s*{' . l:chr . '}\|' . l:re_ws . l:chr . '\)'
      execute 'syntax match texMathSymbol /\%#=1' . l:re . '/'
            \ 'conceal cchar=' . l:target
    endfor
  endfor
endfunction

" }}}1

function! s:match_conceal_accents() abort " {{{1
  for [l:chr; l:targets] in s:map_accents
    for i in range(13)
      let l:target = l:targets[i]
      if empty(l:target) | continue | endif

      let l:accent = s:key_accents[i]
      let l:re_ws = l:accent =~# '^\\\\\a$' ? '\s\+' : '\s*'
      let l:re = l:accent . '\%(\s*{' . l:chr . '}\|' . l:re_ws . l:chr . '\)'
      execute 'syntax match texCmdAccent /\%#=1' . l:re . '/'
            \ 'conceal cchar=' . l:target
    endfor
  endfor
endfunction

let s:key_accents = [
      \ '\\`',
      \ '\\''',
      \ '\\^',
      \ '\\"',
      \ '\\\%(\~\|tilde\)',
      \ '\\\.',
      \ '\\=',
      \ '\\c',
      \ '\\H',
      \ '\\k',
      \ '\\r',
      \ '\\u',
      \ '\\v'
      \]

let s:map_accents = [
      \ ['a',  'à','á','â','ä','ã','ȧ','ā','' ,'' ,'ą','å','ă','ǎ'],
      \ ['A',  'À','Á','Â','Ä','Ã','Ȧ','Ā','' ,'' ,'Ą','Å','Ă','Ǎ'],
      \ ['c',  '' ,'ć','ĉ','' ,'' ,'ċ','' ,'ç','' ,'' ,'' ,'' ,'č'],
      \ ['C',  '' ,'Ć','Ĉ','' ,'' ,'Ċ','' ,'Ç','' ,'' ,'' ,'' ,'Č'],
      \ ['d',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ď'],
      \ ['D',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ď'],
      \ ['e',  'è','é','ê','ë','ẽ','ė','ē','ȩ','' ,'ę','' ,'ĕ','ě'],
      \ ['E',  'È','É','Ê','Ë','Ẽ','Ė','Ē','Ȩ','' ,'Ę','' ,'Ĕ','Ě'],
      \ ['g',  '' ,'ǵ','ĝ','' ,'' ,'ġ','' ,'ģ','' ,'' ,'' ,'ğ','ǧ'],
      \ ['G',  '' ,'Ǵ','Ĝ','' ,'' ,'Ġ','' ,'Ģ','' ,'' ,'' ,'Ğ','Ǧ'],
      \ ['h',  '' ,'' ,'ĥ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ȟ'],
      \ ['H',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ȟ'],
      \ ['i',  'ì','í','î','ï','ĩ','į','ī','' ,'' ,'į','' ,'ĭ','ǐ'],
      \ ['I',  'Ì','Í','Î','Ï','Ĩ','İ','Ī','' ,'' ,'Į','' ,'Ĭ','Ǐ'],
      \ ['J',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'ǰ'],
      \ ['k',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ķ','' ,'' ,'' ,'' ,'ǩ'],
      \ ['K',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ķ','' ,'' ,'' ,'' ,'Ǩ'],
      \ ['l',  '' ,'ĺ','ľ','' ,'' ,'' ,'' ,'ļ','' ,'' ,'' ,'' ,'ľ'],
      \ ['L',  '' ,'Ĺ','Ľ','' ,'' ,'' ,'' ,'Ļ','' ,'' ,'' ,'' ,'Ľ'],
      \ ['n',  '' ,'ń','' ,'' ,'ñ','' ,'' ,'ņ','' ,'' ,'' ,'' ,'ň'],
      \ ['N',  '' ,'Ń','' ,'' ,'Ñ','' ,'' ,'Ņ','' ,'' ,'' ,'' ,'Ň'],
      \ ['o',  'ò','ó','ô','ö','õ','ȯ','ō','' ,'ő','ǫ','' ,'ŏ','ǒ'],
      \ ['O',  'Ò','Ó','Ô','Ö','Õ','Ȯ','Ō','' ,'Ő','Ǫ','' ,'Ŏ','Ǒ'],
      \ ['r',  '' ,'ŕ','' ,'' ,'' ,'' ,'' ,'ŗ','' ,'' ,'' ,'' ,'ř'],
      \ ['R',  '' ,'Ŕ','' ,'' ,'' ,'' ,'' ,'Ŗ','' ,'' ,'' ,'' ,'Ř'],
      \ ['s',  '' ,'ś','ŝ','' ,'' ,'' ,'' ,'ş','' ,'ȿ','' ,'' ,'š'],
      \ ['S',  '' ,'Ś','Ŝ','' ,'' ,'' ,'' ,'Ş','' ,'' ,'' ,'' ,'Š'],
      \ ['t',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'ţ','' ,'' ,'' ,'' ,'ť'],
      \ ['T',  '' ,'' ,'' ,'' ,'' ,'' ,'' ,'Ţ','' ,'' ,'' ,'' ,'Ť'],
      \ ['u',  'ù','ú','û','ü','ũ','' ,'ū','' ,'ű','ų','ů','ŭ','ǔ'],
      \ ['U',  'Ù','Ú','Û','Ü','Ũ','' ,'Ū','' ,'Ű','Ų','Ů','Ŭ','Ǔ'],
      \ ['w',  '' ,'' ,'ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['W',  '' ,'' ,'Ŵ','' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['y',  'ỳ','ý','ŷ','ÿ','ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['Y',  'Ỳ','Ý','Ŷ','Ÿ','Ỹ','' ,'' ,'' ,'' ,'' ,'' ,'' ,''],
      \ ['z',  '' ,'ź','' ,'' ,'' ,'ż','' ,'' ,'' ,'' ,'' ,'' ,'ž'],
      \ ['Z',  '' ,'Ź','' ,'' ,'' ,'Ż','' ,'' ,'' ,'' ,'' ,'' ,'Ž'],
      \ ['\\i','ì','í','î','ï','ĩ','į','' ,'' ,'' ,'' ,'' ,'ĭ',''],
      \]

" }}}1
function! s:match_conceal_ligatures() abort " {{{1
  syntax match texCmdLigature "\%#=1\\lq\>" conceal cchar=‘
  syntax match texCmdLigature "\%#=1\\rq\>" conceal cchar=′
  syntax match texCmdLigature "\%#=1\\i\>"  conceal cchar=ı
  syntax match texCmdLigature "\%#=1\\j\>"  conceal cchar=ȷ
  syntax match texCmdLigature "\%#=1\\AE\>" conceal cchar=Æ
  syntax match texCmdLigature "\%#=1\\ae\>" conceal cchar=æ
  syntax match texCmdLigature "\%#=1\\oe\>" conceal cchar=œ
  syntax match texCmdLigature "\%#=1\\OE\>" conceal cchar=Œ
  syntax match texCmdLigature "\%#=1\\o\>"  conceal cchar=ø
  syntax match texCmdLigature "\%#=1\\O\>"  conceal cchar=Ø
  syntax match texCmdLigature "\%#=1\\aa\>" conceal cchar=å
  syntax match texCmdLigature "\%#=1\\AA\>" conceal cchar=Å
  syntax match texCmdLigature "\%#=1\\ss\>" conceal cchar=ß
  syntax match texLigature    "--"     conceal cchar=–
  syntax match texLigature    "---"    conceal cchar=—
  syntax match texLigature    "`"      conceal cchar=‘
  syntax match texLigature    "'"      conceal cchar=’
  syntax match texLigature    "``"     conceal cchar=“
  syntax match texLigature    "''"     conceal cchar=”
  syntax match texLigature    ",,"     conceal cchar=„
  syntax match texLigature    "!`"     conceal cchar=¡
  syntax match texLigature    "?`"     conceal cchar=¿
endfunction

" }}}1
function! s:match_conceal_fancy() abort " {{{1
  syntax match texCmd         "\%#=1\\colon\>" conceal cchar=:
  syntax match texCmd         "\%#=1\\dots\>"  conceal cchar=…
  syntax match texCmd         "\%#=1\\slash\>" conceal cchar=/
  syntax match texCmd         "\%#=1\\ldots\>" conceal cchar=…
  syntax match texTabularChar "\\\\"      conceal cchar=⏎

  syntax match texCmdItem     "\%#=1\\item\>"  conceal cchar=○
        \ nextgroup=texItemLabelConcealed
  syntax match texItemLabelConcealed "\s*\[[^]]*\]"
        \ contained contains=texItemLabelDelim
  syntax match texItemLabelDelim "\]"    contained conceal
  syntax match texItemLabelDelim "\s*\[" contained conceal cchar= 
endfunction

" }}}1
function! s:match_conceal_spacing() abort " {{{1
  syntax match texSpecialChar "\~"                     conceal cchar= 
  syntax match texSpecialChar "\%#=1\\ "               conceal cchar= 
  syntax match texSpecialChar "\%#=1\\[,;:!>]"         conceal
  syntax match texSpecialChar "\%#=1\\@\ze\s\+"        conceal
  syntax match texCmd         "\%#=1\\bigskip\>"       conceal
  syntax match texCmd         "\%#=1\\hfill\>"         conceal
  syntax match texCmd         "\%#=1\\medspace\>"      conceal
  syntax match texCmd         "\%#=1\\qquad\>"         conceal
  syntax match texCmd         "\%#=1\\quad\>"          conceal
  syntax match texCmd         "\%#=1\\thickspace\>"    conceal
  syntax match texCmd         "\%#=1\\thinspace\>"     conceal
  syntax match texCmd         "\%#=1\\vfill\>"         conceal
  syntax match texCmd         "\%#=1\\[hv]space\>"     conceal
        \ skipwhite nextgroup=texConcealedArg
  syntax match texCmd         "\%#=1\\h\?phantom\>"    conceal
        \ skipwhite nextgroup=texConcealedArg

  syntax match texMathCmd "\%#=1\\bigskip\>"    contained conceal
  syntax match texMathCmd "\%#=1\\hfill\>"      contained conceal
  syntax match texMathCmd "\%#=1\\medspace\>"   contained conceal
  syntax match texMathCmd "\%#=1\\qquad\>"      contained conceal
  syntax match texMathCmd "\%#=1\\quad\>"       contained conceal
  syntax match texMathCmd "\%#=1\\thickspace\>" contained conceal
  syntax match texMathCmd "\%#=1\\thinspace\>"  contained conceal
  syntax match texMathCmd "\%#=1\\vfill\>"      contained conceal
  syntax match texMathCmd "\%#=1\\[hv]space\>"  contained conceal
        \ skipwhite nextgroup=texConcealedArg
  syntax match texMathCmd "\%#=1\\h\?phantom\>" contained conceal
        \ skipwhite nextgroup=texConcealedArg

  call vimtex#syntax#core#new_arg('texConcealedArg', {
        \ 'opts': 'contained conceal',
        \ 'contains': 'texSpecialChar,texConcealedArgGroup',
        \})
  call vimtex#syntax#core#new_arg('texConcealedArgGroup', {
        \ 'matchgroup': 'matchgroup=NONE',
        \ 'opts': 'contained conceal',
        \ 'contains': 'texConcealedArgGroup',
        \})
endfunction

" }}}1
function! s:match_conceal_greek() abort " {{{1
  syntax match texCmdGreek "\%#=1\\alpha\>"      contained conceal cchar=α
  syntax match texCmdGreek "\%#=1\\beta\>"       contained conceal cchar=β
  syntax match texCmdGreek "\%#=1\\gamma\>"      contained conceal cchar=γ
  syntax match texCmdGreek "\%#=1\\delta\>"      contained conceal cchar=δ
  syntax match texCmdGreek "\%#=1\\epsilon\>"    contained conceal cchar=ϵ
  syntax match texCmdGreek "\%#=1\\varepsilon\>" contained conceal cchar=ε
  syntax match texCmdGreek "\%#=1\\zeta\>"       contained conceal cchar=ζ
  syntax match texCmdGreek "\%#=1\\eta\>"        contained conceal cchar=η
  syntax match texCmdGreek "\%#=1\\theta\>"      contained conceal cchar=θ
  syntax match texCmdGreek "\%#=1\\vartheta\>"   contained conceal cchar=ϑ
  syntax match texCmdGreek "\%#=1\\iota\>"       contained conceal cchar=ι
  syntax match texCmdGreek "\%#=1\\kappa\>"      contained conceal cchar=κ
  syntax match texCmdGreek "\%#=1\\lambda\>"     contained conceal cchar=λ
  syntax match texCmdGreek "\%#=1\\mu\>"         contained conceal cchar=μ
  syntax match texCmdGreek "\%#=1\\nu\>"         contained conceal cchar=ν
  syntax match texCmdGreek "\%#=1\\xi\>"         contained conceal cchar=ξ
  syntax match texCmdGreek "\%#=1\\pi\>"         contained conceal cchar=π
  syntax match texCmdGreek "\%#=1\\varpi\>"      contained conceal cchar=ϖ
  syntax match texCmdGreek "\%#=1\\rho\>"        contained conceal cchar=ρ
  syntax match texCmdGreek "\%#=1\\varrho\>"     contained conceal cchar=ϱ
  syntax match texCmdGreek "\%#=1\\sigma\>"      contained conceal cchar=σ
  syntax match texCmdGreek "\%#=1\\varsigma\>"   contained conceal cchar=ς
  syntax match texCmdGreek "\%#=1\\tau\>"        contained conceal cchar=τ
  syntax match texCmdGreek "\%#=1\\upsilon\>"    contained conceal cchar=υ
  syntax match texCmdGreek "\%#=1\\phi\>"        contained conceal cchar=ϕ
  syntax match texCmdGreek "\%#=1\\varphi\>"     contained conceal cchar=φ
  syntax match texCmdGreek "\%#=1\\chi\>"        contained conceal cchar=χ
  syntax match texCmdGreek "\%#=1\\psi\>"        contained conceal cchar=ψ
  syntax match texCmdGreek "\%#=1\\omega\>"      contained conceal cchar=ω
  syntax match texCmdGreek "\%#=1\\Gamma\>"      contained conceal cchar=Γ
  syntax match texCmdGreek "\%#=1\\Delta\>"      contained conceal cchar=Δ
  syntax match texCmdGreek "\%#=1\\Theta\>"      contained conceal cchar=Θ
  syntax match texCmdGreek "\%#=1\\Lambda\>"     contained conceal cchar=Λ
  syntax match texCmdGreek "\%#=1\\Xi\>"         contained conceal cchar=Ξ
  syntax match texCmdGreek "\%#=1\\Pi\>"         contained conceal cchar=Π
  syntax match texCmdGreek "\%#=1\\Sigma\>"      contained conceal cchar=Σ
  syntax match texCmdGreek "\%#=1\\Upsilon\>"    contained conceal cchar=Υ
  syntax match texCmdGreek "\%#=1\\Phi\>"        contained conceal cchar=Φ
  syntax match texCmdGreek "\%#=1\\Chi\>"        contained conceal cchar=Χ
  syntax match texCmdGreek "\%#=1\\Psi\>"        contained conceal cchar=Ψ
  syntax match texCmdGreek "\%#=1\\Omega\>"      contained conceal cchar=Ω
endfunction

" }}}1
function! s:match_conceal_cites_brackets() abort " {{{1
  syntax match texCmdRefConcealed "\\citet\?\>\*\?" conceal
        \ skipwhite nextgroup=texRefConcealedOpt1,texRefConcealedArg
  call vimtex#syntax#core#new_opt('texRefConcealedOpt1', {
        \ 'opts': g:vimtex_syntax_conceal_cites.verbose ? '' : 'conceal',
        \ 'contains': '@texClusterOpt,texSpecialChar',
        \ 'next': 'texRefConcealedOpt2,texRefConcealedArg',
        \})
  call vimtex#syntax#core#new_opt('texRefConcealedOpt2', {
        \ 'opts': g:vimtex_syntax_conceal_cites.verbose ? '' : 'conceal',
        \ 'contains': '@texClusterOpt,texSpecialChar',
        \ 'next': 'texRefConcealedArg',
        \})
  syntax match texRefConcealedOpt2 "\[\s*\]" contained conceal
        \ skipwhite nextgroup=texRefConcealedPArg
  call vimtex#syntax#core#new_arg('texRefConcealedArg', {
        \ 'contains': 'texComment,@NoSpell,texRefConcealedDelim',
        \ 'opts': 'keepend contained',
        \ 'matchgroup': '',
        \})
  syntax match texRefConcealedDelim contained "{" cchar=[ conceal
  syntax match texRefConcealedDelim contained "}" cchar=] conceal

  syntax match texCmdRefConcealed "\\citep\>\*\?" conceal
        \ skipwhite nextgroup=texRefConcealedPOpt1,texRefConcealedPArg
  call vimtex#syntax#core#new_opt('texRefConcealedPOpt1', {
        \ 'opts': g:vimtex_syntax_conceal_cites.verbose ? '' : 'conceal',
        \ 'contains': '@texClusterOpt,texSpecialChar',
        \ 'next': 'texRefConcealedPOpt2,texRefConcealedPArg',
        \})
  call vimtex#syntax#core#new_opt('texRefConcealedPOpt2', {
        \ 'opts': g:vimtex_syntax_conceal_cites.verbose ? '' : 'conceal',
        \ 'contains': '@texClusterOpt,texSpecialChar',
        \ 'next': 'texRefConcealedPArg',
        \})
  syntax match texRefConcealedPOpt2 "\[\s*\]" contained conceal
        \ skipwhite nextgroup=texRefConcealedPArg
  call vimtex#syntax#core#new_arg('texRefConcealedPArg', {
        \ 'contains': 'texComment,@NoSpell,texRefConcealedPDelim',
        \ 'opts': 'keepend contained',
        \ 'matchgroup': '',
        \})
  syntax match texRefConcealedPDelim contained "{" cchar=( conceal
  syntax match texRefConcealedPDelim contained "}" cchar=) conceal
endfunction

" }}}1
function! s:match_conceal_cites_icon() abort " {{{1
  if empty(g:vimtex_syntax_conceal_cites.icon) | return | endif

  execute 'syntax match texCmdRefConcealed'
        \ '"\\cite[tp]\?\*\?\%(\[[^]]*\]\)\{,2}{[^}]*}"'
        \ 'conceal cchar=' . g:vimtex_syntax_conceal_cites.icon
endfunction

" }}}1
function! s:match_conceal_sections() abort " {{{1
  syntax match texCmdPart "\%#=1\v\\%(sub)*section>\*?" contains=texPartConcealed nextgroup=texPartConcArgTitle
  syntax match texPartConcealed "\\" contained conceal cchar=#
  syntax match texPartConcealed "sub" contained conceal cchar=#
  syntax match texPartConcealed "section\*\?" contained conceal cchar= 

  call vimtex#syntax#core#new_arg('texPartConcArgTitle', {
        \ 'opts': 'contained concealends'
        \})
endfunction

" }}}1

function! s:gather_newtheorems() abort " {{{1
  let l:lines = vimtex#parser#preamble(b:vimtex.tex)

  call filter(l:lines, {_, x -> x =~# '^\s*\\newtheorem\>'})
  call map(l:lines, {_, x -> matchstr(x, '^\s*\\newtheorem\>\*\?{\zs[^}]*')})

  return l:lines
endfunction

" }}}1

" vim: set fdm=marker
