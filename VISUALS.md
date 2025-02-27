# VimTeX Visualized

This page contains animated GIFs that demonstrate many of the core VimTeX
editing features listed in `:help vimtex-features`. The related mappings are
documented in detail at `:help vimtex-mappings`. The GIFs and accompanying
descriptions are used with permission from
[@ejmastnak](https://github.com/ejmastnak)'s guide to [Getting started with the
VimTeX plugin](https://www.ejmastnak.com/tutorials/vim-latex/vimtex.html).

Hopefully, the animations can give you a clearer mental image of what VimTeX's
mappings do and how you might use them. You may want to scroll through this page
while simultaneously looking through `:help vimtex-features`—the animations
should nicely complement the plain-text documentation.

You can find a description of how the GIFs were made [at the bottom of this
page](#how-these-gifs-were-made).

#### This page is community-maintained

* This page is made possible only with help from the community.
  [@ejmastnak](https://github.com/ejmastnak), not
  [@lervag](https://github.com/lervag), takes primary responsibility for
  maintaining it, but contributions from all VimTeX users are welcome.

* If you notice mistakes or outdated content (following a VimTeX update, say),
  feel free to open a PR to fix it yourself. Alternatively, contact
  [@ejmastnak](https://github.com/ejmastnak) at
  [ejmastnak@gmail.com](mailto:ejmastnak@gmail.com), who will be happy to help
  fix it.

## Table of contents
<!-- vim-markdown-toc GFM -->

* [Motion commands](#motion-commands)
  * [Navigating sections](#navigating-sections)
  * [Navigating environments](#navigating-environments)
  * [Navigating math zones](#navigating-math-zones)
  * [Navigating frames](#navigating-frames)
  * [Navigating matching delimiters](#navigating-matching-delimiters)
* [Text objects](#text-objects)
  * [The math text object](#the-math-text-object)
  * [The section, delimiter, and command text objects](#the-section-delimiter-and-command-text-objects)
  * [The environment and item text objects](#the-environment-and-item-text-objects)
* [Deleting surrounding LaTeX content](#deleting-surrounding-latex-content)
  * [Delete surrounding commands](#delete-surrounding-commands)
  * [Delete surrounding environments](#delete-surrounding-environments)
  * [Delete surrounding math zones](#delete-surrounding-math-zones)
  * [Delete surrounding delimiters](#delete-surrounding-delimiters)
* [Changing surrounding LaTeX content](#changing-surrounding-latex-content)
  * [Change surrounding commands](#change-surrounding-commands)
  * [Change surrounding environments](#change-surrounding-environments)
  * [Change surrounding math zones](#change-surrounding-math-zones)
  * [Change surrounding delimiters](#change-surrounding-delimiters)
* [Toggling commands](#toggling-commands)
  * [Toggling starred commands and environments](#toggling-starred-commands-and-environments)
  * [Toggling between inline and display math](#toggling-between-inline-and-display-math)
  * [Toggling delimiter modifiers](#toggling-delimiter-modifiers)
  * [Toggling fractions](#toggling-fractions)
* [How these GIFs were made](#how-these-gifs-were-made)

<!-- vim-markdown-toc -->

## Motion commands

### Navigating sections

Use `]]` to jump to the beginning of the next `\section`, `\subsection` or
`\subsubsection`, whichever comes first. Use `[[` to jump backward through
sections, and see the similar shortcuts `][` and `[]` in the VimTeX
documentation at `:help <Plug>(vimtex-][)` and `:help <Plug>(vimtex-[])`.

![Navigating sections](https://github.com/lervag/vimtex-media/blob/main/gif/move/move-section.gif)

### Navigating environments

Use `]m` and `[m` to jump to the next or previous environment `\begin{}`
command. See the VimTeX documentation for the similar shortcuts `]M` and `[M`,
described in `:help <Plug>(vimtex-]M)` and `:help <Plug>(vimtex-[M)`.

![Navigating environments](https://github.com/lervag/vimtex-media/blob/main/gif/move/move-environment.gif)

### Navigating math zones

Use `]n` and `[n` to jump to the beginning of the next or previous math zone.
See the VimTeX documentation for the similar shortcuts `]N` and `[N`,
described in `:help <Plug>(vimtex-]N)` and `:help <Plug>(vimtex-[N)`.

![Navigating math zones](https://github.com/lervag/vimtex-media/blob/main/gif/move/move-math.gif)

### Navigating frames

Use `]r` and `[r` to jump to the beginning of the next or previous Beamer
`frame` environment. See the VimTeX documentation for the similar shortcuts
`]R` and `[R`, described in `:help <Plug>(vimtex-]R)` and `:help
<Plug>(vimtex-[R)`.

![Navigating frames](https://github.com/lervag/vimtex-media/blob/main/gif/move/move-frame.gif)

### Navigating matching delimiters

Use `%` to move between matching delimiters, inline-math `$` delimiters, and LaTeX environments.

![Navigating matching delimiters](https://github.com/lervag/vimtex-media/blob/main/gif/move/move-matching.gif)

## Text objects

VimTeX provides text objects for commands, delimiters, environments,
math zones, sections, and items. The following GIFs use Vim's visual
mode to show the scope of the text objects.

### The math text object

The `i$` and `a$` text objects select inline math, display math, and
common math environments.

![The math text object](https://github.com/lervag/vimtex-media/blob/main/gif/text-objects/obj-math.gif)

### The section, delimiter, and command text objects

The `iP` and `aP` text objects select LaTeX sections (their
subsection variations); the `id` and `ad` objects select delimiters
(parentheses, brackets, braces...); the `ic` and `ac` objects select
LaTeX commands.

![The section, delimiter, and command text objects](https://github.com/lervag/vimtex-media/blob/main/gif/text-objects/obj-sec-delim-cmd.gif)

### The environment and item text objects

The `ie` and `ae` text objects select LaTeX environments and the `im`
and `am` objects select items in enumerated environments.

![The environment and item text objects](https://github.com/lervag/vimtex-media/blob/main/gif/text-objects/obj-env-item.gif)

## Deleting surrounding LaTeX content

### Delete surrounding commands

Use `dsc` to delete a LaTeX command while preserving the command's argument(s);
the `dsc` mapping also recognizes and correctly deletes parameters inside square
brackets.

![`dsc`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/dsc.gif)

### Delete surrounding environments

Use `dse` to delete the `\begin{}` and `\end{}` declaration surrounding a LaTeX
environment without changing the environment contents.

![`dse`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/dse.gif)

### Delete surrounding math zones

Use `ds$` to delete surrounding math zones (display math, standard environments,
and inline math) without changing the math contents.

![`ds$`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/dsm.gif)

### Delete surrounding delimiters

Use `dsd` to delete delimiters (e.g. `()`, `[]`, `{}`, *and* any of their `\left
\right`, `\big \big` variants) without changing the enclosed content.

![`dsd`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/dsd.gif)


## Changing surrounding LaTeX content

### Change surrounding commands

Use `csc` to change a LaTeX command while preserving the command's argument(s).

![`csc`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/csc.gif)

### Change surrounding environments

Use `cse` to change the type of a LaTeX environment without changing the
environment contents.

![`cse`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/cse.gif)

### Change surrounding math zones

Use `cs$` to change the type of surrounding math zone without changing the math
contents. You can switch between display math, standard environments, and inline
math.

![`cs$`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/csm.gif)

### Change surrounding delimiters

Use `csd` to change delimiters (e.g. `()`, `[]`, `{}`, and any of their `\left
\right`, `\big \big` variants) without changing the enclosed content; the `csd`
command is "smart" and correctly recognizes and preserves `\left \right`-style
modifiers.

![`csd`](https://github.com/lervag/vimtex-media/blob/main/gif/change-delete/csd.gif)

## Toggling commands

### Toggling starred commands and environments

Use `tsc` and `tss` to toggle between starred and un-starred versions of
commands and environments, respectively. (Note: `tss` used to be `tse` in tag
v2.15 and prior. See v2.16 release notes for more information.)

![`tsc` and `tss`](https://github.com/lervag/vimtex-media/blob/main/gif/toggle/tsc-tse.gif)

### Toggling between inline and display math

Use `ts$` to toggle between inline math, display math, and standard math environments.

![`ts$`](https://github.com/lervag/vimtex-media/blob/main/gif/toggle/tsm.gif)

### Toggling delimiter modifiers

Use `tsd` to change between plain and `\left`/`\right` versions of delimiters.
Use the `g:vimtex_delim_toggle_mod_list` variable to add more modifiers  to the
delimiter toggle list. (e.g. `\big` as in the GIF below)

![`tsd`](https://github.com/lervag/vimtex-media/blob/main/gif/toggle/tsd.gif)

### Toggling fractions

Use `tsf` to toggle between inline and `\frac{}{}` versions of fractions.

![`tsf`](https://github.com/lervag/vimtex-media/blob/main/gif/toggle/tsf.gif)

## How these GIFs were made

(Based on interest and discussion in issue
[#2685](https://github.com/lervag/vimtex/issues/2685).)

The basic toolkit is [Menyoki](https://github.com/orhun/menyoki) for
recording the GIFs and [screenkey](https://gitlab.com/screenkey/screenkey) to
display the keys being typed, all running on a Linux system using the X11
window system.

On top of this are some aesthetic details to make the GIFs look nicer,
including:

- [Goyo](https://github.com/junegunn/goyo.vim) to remove Vim peripherals
  (status bar, line numbers, etc.) for a cleaner look
- [Limelight](https://github.com/junegunn/limelight.vim) to draw focus to the
  currently selected paragraph (and gray out the rest of the document)
- Screen recording region (crop, basically) set via Menyoki to exactly capture
  the terminal window (and not e.g. the rest of my desktop)
- Enlarged terminal font for the duration of the GIF recording for better
  readability
- Vim and screenkey color schemes and fonts aligned for visual consistency.

The aesthetic details and cropping are wrapped in shell scripts for
repeatability across multiple GIF recordings—the original scripts and auxiliary
files can be found in the GitHub repo
[ejmastnak/ejmastnak.github.io](https://github.com/ejmastnak/ejmastnak.github.io/tree/main/tutorials/vim-latex/gifs),
although they might be difficult to parse without additional context.

Feel free to contact [@ejmastnak](https://github.com/ejmastnak) if you're
interested in the details or recording similar GIFs.
