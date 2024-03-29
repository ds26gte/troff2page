.\" last modified 2021-11-08
.SH 1
1.  Introduction
.LP
.IX troff2page, script
.IX man@-man, macro package
.IX ms@-ms, macro package
.IX Lua
.IX troff
\fCtroff2page\fP is a \*[url https://www.lua.org]Lua\& script that
makes Web pages from troff manuscripts.  It reads an input
document that is marked up in troff (-man or -ms) and produces an
output document with the functionally equivalent HTML markup.
.PP
.IX groff
.IX Info files, generating
troff is a venerable typesetting program that produces
high-quality print output from plain text source.
It doesn’t require
special-purpose software to create content; any text
editor will do.  troff macros and standard Unix external tools can
be used to arbitrarily enhance troff’s print output.
troff is very compact (unlike its great rival TeX) and is
practically ubiquitous, being available by default on
all Unixish machines.  These are significant benefits: so even
though
troff is a toolchain of some vintage, there continues to be a
devoted band of troffglodytes preserving the tradition.
Troff2page lets you put your troff documents on the Web without
your having to learn a new system or to maintain separate documents.
Troff2page can be instructed to also produce an Info version of your
document that’s suitable for browsing on a text terminal (chapter
\*[TAG:gnuinfo]).
.PP
.IX PATH, environment variable
First,
ensure that the script \fCtroff2page\fP is in a directory in your
\fCPATH\fP.
.PP
.TAG html-output
.IX calling Troff2page from!the command-line
To convert an input troff document named \fCjobname.ms\fP, type
the following on the operating-system command line.
.EX
    troff2page jobname.ms
.EE
at your operating-system prompt.  This creates an output HTML file
\fCjobname.html\fP in the current directory.  (This HTML file has the same basename as the
input troff file (i.e., \fCjobname\fP), but its extension is
\fC.html\fP.)
.PP
.IX page breaks
If the input troff uses the page-break request
\fC.bp\fP,
then the output
HTML consists of a series of interlinked files: The first file is named
\fCjobname.html\fP;
the rest are
\fCjobname-Z-H-1.html\fP,
\fCjobname-Z-H-2.html\fP,
etc.
.PP
.SH 2
Commmand-line options
.LP
.IX command-line options
.IX version@--version, groff command-line option
.IX help@--help, command-line option
.IX v@-v, groff command-line option
.IX h@-h, groff command-line option
.IX m@-m, groff command-line option
.IX r@-r, groff command-line option
.IX d@-d, groff command-line option
.IX c@-c, groff command-line option
.IX -@--, groff command-line option
\fCtroff2page\fP takes some, but not all, of the same options as \fCgroff\fP,
a widely used and actively developed implementation of troff.
viz.,
.TS
tab(@) center;
lw(14m) lw(30m).
_
\fC-v\fP or \fC--version\fP @ display version
_
\fC-h\fP or \fC--help\fP @ display help
_
\fC-m\fP @ load macro files from \fCGROFF_TMAC_PATH\fP
_
\fC-r\fP @ pre-set number registers
_
\fC-d\fP @ pre-define strings
_
\fC-c\fP @ turn off color
_
\fC--\fP @ signal end of options
_
.TE
.EX
    % troff2page --help
.ft CI
    Troff2page version 20201226
    Copyright (C) ...
    Usage: troff2page OPTION ... FILE
    Available options: ...
    ...
    For full details, please see http://ds26gte.github.io/troff2page
.EE
In the unlikely event that you have a document file named
\fC--help\fP (and wish to process it), use
.EX
    % troff2page -- --help
.EE
.IX z@-z, groff command-line option
.IX t@-t, groff command-line option
.IX U@-U, groff command-line option
\fCtroff2page\fP ignores all other \fCgroff\fP options, most with a warning.
The options
\fC-z\fP, \fC-t\fP, and \fC-U\fP are silently ignored, as they’re always valid
for Troff2page.
.PP
Macro file options must be given without the suffix \fC.tmac\fP or prefix
\fCtmac.\fP.  Thus, \fC-mxyz\fP or \fC-m xyz\fP looks for the macro file
\fCxyz.tmac\fP or \fCtmac.xyz\fP, whichever is found first in the macro directories,
and loads it.
.PP
If you find you need to specify an option that \fCtroff2page\fP
doesn’t accept, you can always supply it in a macro file via
\fC-m\fP.
.PP
The options can be varied with each call to \fCtroff2page\fP, just as
with \fCgroff\fP.  Please see the groff man page
for details on all the provided options.
.PP
.SH 2
Filename arguments
.LP
The arguments remaining after all the option processing are
considered to be the names of document files.
.PP
If there is \fIone\fP file argument, say \fCfilename.ext\fP,
\fCtroff2page\fP converts it to \fCfilename.html\fP (and possibly
some auxiliary HTML files whose names are of form
\fCfilename-Z-H-number.html\fP). This is unlike groff, which
writes to console (“standard output”).
.PP
If there is \fImore than one\fP file argument, say \fCf1.e1, f2.e2, ...
flast.elast\fP, \fCtroff2page\fP concatenates their content to create a
corresponding HTML version in \fCflast.html\fP (and possibly some
aux HTML files \fCflast-Z-H-number.html\fP). Again, this is
unlike groff.
.PP
If any of the argument files don’t exist, \fCtroff2page\fP, like groff, issues a
“cannot open ... No such file or directory” diagnostic, but does
its best with the files that do exist.
.PP
If after all the option processing, \fIno\fP file arguments remain, and
the options for help or version were not used,
\fCtroff2page\fP reads from the console (“standard input”), like
groff.  The output HTML file(s) in this case use the basename
\fCtroffput\fP.\**
.FS
The name \fCtroffput\fP is inspired by \fCtexput\fP,
the name that TeX uses when it isn’t given an input file.
.FE
This part is unlike groff, which always writes
to console.
.PP
.SH 2
Autoloaded init files
.LP
.TAG troff2pagerc
.IX init files for Troff2page
.IX troff2pagerc.tmac@.troff2pagerc.tmac, user macro file
.IX TROFF2PAGERC, environment variable
\fCtroff2page\fP can read directives in some autoloaded files
without the need to explicitly use a command-line option.  These
are useful to specify information that is relevant only for the HTML
output, and they’re loaded before the input document is
processed.
.PP
i.  The first such file is the one named by the environment
variable \fCTROFF2PAGERC\fP, or if that isn't set,
\fC.troff2pagerc.tmac\fP: Troff2page looks for it in your macro
directories: \fCGROFF_TMAC_PATH\fP, working directory, home — in
that order.\**
.FS
You can of course collapse the order somewhat by putting the working
directory (\fC.\fP) and home in \fCGROFF_TMAC_PATH\fP, but then
the order of the directories in \fCGROFF_TMAC_PATH\fP decides the
issue.
.FE
The working directory is a good location if your
changes are meant only for those
documents that are in that directory.
If your changes will be used in all your documents, place it in
your home or a private (not a system!) \fCGROFF_TMAC_PATH\fP directory.
.PP
That your home directory is the last place Troff2page looks in
for \fC.troff2pagerc.tmac\fP has a nice benefit: Use
\fC~/.troff2pagerc.tmac\fP for standard boilerplate customization that
you want unthinkingly autoloaded for \fImost\fP of your
documents, but easily disable it for the documents that need
special TLC by simply placing an empty or different
\fC.troff2pagerc.tmac\fP in the working directory.
.PP
A
more system-level \fCGROFF_TMAC_PATH\fP placement is typically
unadvised for such an ad hoc file.
.PP
\fCtroff2page\fP loads only the first \fC.troff2pagerc.tmac\fP it
finds.
.PP
.IX t2p@.t2p, user macro file
ii.  Next, \fCtroff2page\fP will also pick up a file
\fCjobname.t2p\fP, where \fCjobname\fP is the basename of the input document.
This is useful for directives that are specific to this document.
\fCjobname.t2p\fP, unlike \fC.troff2pagerc.tmac\fP, is looked for only in the
working directory, and not more generally in
\fCGROFF_TMAC_PATH\fP.
.PP
(Note that groff itself will \fInot\fP load either
\fC.troff2pagerc.tmac\fP or
\fCjobname.t2p\fP automatically.  But that is presumably OK, since
these two files typically contain information that’s relevant
for HTML only.)
.PP
.IX man.local, man init file
iii.  Finally, If the input file is recognizably a man page (i.e., it has the
command \fC.TH\fP), both Troff2page and groff will load, if it
exists, the init file \fCman.local\fP.  This init file, like
\fC.troff2pagerc.tmac\fP, is searched for in the
\fCGROFF_TMAC_PATH\fP, working directory, and home, in that
order.
.PP
None of the autoloaded file disables the loading of
the others.  However, because of the order in which they’re
loaded, settings in \fCman.local\fP can override or shadow
\fCjobname.t2p\fP, which in its turn shadows
\fC.troff2pagerc.tmac\fP.
.PP
.SH 2
Calling Troff2page from within Lua
.LP
.TAG calling_troff2page_within_lua
.IX calling Troff2page from!Lua
The script \fCtroff2page\fP runs on the command-line on Unix-esque
machines that have Lua installed.
For more installation information,
please see the file \*[url \
https://github.com/ds26gte/troff2page/blob/master/INSTALL.adoc]INSTALL.adoc\&
in the distribution.
.PP
However, it is not necessary to run the file \fCtroff2page\fP as a
Unix script.  You can load \fCtroff2page.lua\fP (\fCtroff2page\fP is a soft link
to the Lua file \fCtroff2page.lua\fP) into Lua, and then call the
Lua procedure \fCtroff2page\fP on your source document.  E.g.,
.EX
    dofile 'troff2page.lua'
    troff2page 'my-troff-document.ms'
.EE
The procedure \fCtroff2page\fP can be called
several times, on the same or different documents, from within
the same Lua session.  It takes the same options as the script,
supplied as multiple string arguments.
.PP
.\" For some more exotic ways of invoking \fCtroff2page\fP, see
.\" section \*[TAG:nvimtex].
