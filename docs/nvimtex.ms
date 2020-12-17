.\" last modified 2020-12-17
.SH 1
11. Some unusual ways to call troff2page
.LP
.TAG nvimtex
.IX Neovim
.IX LuaTeX
troff2page doesn’t need a standalone Lua implementation.
It
runs equally well in Lua embedded in other applications, e.g.,
the text editor \*[url https://neovim.io]Neovim\& and the
typesetter \*[url https://luatex.org]LuaTeX\&.
.PP
.SH 2
Calling troff2page from Neovim
.LP
.TAG calling_troff2page_from_neovim
.IX calling troff2page from!Neovim
One of the merits of using
Neovim’s Lua to run \fCtroff2page\fP is the tight integration of
composing and previewing it offers. You can convert your groff
source and browse the HTML output as you’re editing it, using
appropriate autocommands.
.PP
To set up, first copy the files \fClua/troff2page.lua\fP and
\fCplugin/troff2page.vim\fP to subdirectories \fClua/\fP and
\fCplugin/\fP respectively, somewhere in your Neovim
\fC'runtimepath'\fP.  Alternatively, place a clone of the
\fCtroff2page\fP repo in a \fCpack/\fP subdirectory, somewhere in
your \fC'runtimepath'\fP or \fC'packpath'\fP.
.PP
You now have the Neovim command \fCTroff2page\fP
which is called with the same style of arguments
as \fCtroff2page\fP, with the following Vim-specific special
features:
.PP
i. The argument \fC%\fP is replaced with the name of the file in
the current window (just as for other Vim commands).
.PP
ii. If called with no argument, the name of the file in the
current window is assumed to be the single argument.
.PP
(Note the capital \fCT\fP! Vim won’t allow non-primitive commands
to start with a lowercase letter.)
.PP
.IX neovim-troff2page, script
The script \fCneovim-troff2page\fP combines all this into a shell
script that can be used exactly like the regular Lua script. Use
it if you have Neovim but not Lua.
.PP
.SH 2
Calling troff2page from LuaTeX
.LP
.TAG calling_troff2page_from_luatex
.IX calling troff2page from!LuaTeX
.
The Lua of LuaTeX can also be used for
running \fCtroff2page\fP. First ensure you
have a copy of \fClua/troff2page.lua\fP in your \fCTEXINPUTS\fP.
It is loaded in LuaTeX by
.EX
    \directlua{
      troff2page = (require 'troff2page')
    }
.EE
You can than call it on a single argument string that includes
all the option and filename inputs, e.g.,
.EX
    \directlua{
      troff2page.troff2page '-mpca -t doc.ms'
    }
.EE
The above commands can be supplied to LuaTeX either via a TeX
file or as a console interaction.
.PP
.IX luatex-troff2page, script
The script \fCluatex-troff2page\fP combines all this into a shell
script that can be used exactly like the regular Lua script. Use
it if you have LuaTeX but not Lua.
