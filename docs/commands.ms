.SH 1
2. troff and troff2page commands

.IX drop caps in color
.defcolor terracottapink rgb #9b3d3d
.DC T ROFF2PAGE terracottapink
recognizes most of the commands (requests, macros,
diversions, strings, escapes, glyphs) of raw troff and its
ms and man macro packages, including such rather
recherché macros as \fC.DC\fP, here used to produce a drop cap
colored terracotta pink.
The syntax recognized is the improved kind
supported by \*[url http://groff.ffii.org]groff\& and \*[url \
http://heirloom.sf.net/doctools.html]Heirloom troff\&, i.e., macro, string,
and glyph names can be arbitrarily long, and strings can
have arguments.  Most of the commands are converted to their
obvious HTML equivalent.\**
.
.FS
.IX footnotes
E.g., ms’s footnotes (\fC\e**\fP and \fC.FS\fP/\fC.FE\fP) have a
straightforward translation in the HTML, with the footnote text set at the
bottom of the HTML page, and with the footnote markers in the body and the
footnote hyperlinking to each other.
.FE
.
Please consult troff and groff documentation for these commands.  We will
concentrate here on those commands whose HTML counterpart is not immediately
obvious.

.IX macro files provided with troff2page
.IX m@-m, groff option
.IX pca-tag.tmac, macro file
.IX pca-ix.tmac, macro file
.IX eval4troff.tmac, macro file
.IX mso@.mso, groff request
The troff2page distribution includes several troff macro
or tmac
files (with
extension \fCtmac\fP), both in the main directory and in the
sudirectory for the submodule \fCmpca\fP. They include general-purpose
extensions to the \fCms\fP package, e.g., \fCpca-tag.tmac\fP for
cross-references; \fCpca-ix.tmac\fP for index generation;
\fCpca-eval.tmac\fP for extending troff using Lua, etc.

You should put these tmac files in one of your macro directories,
i.e., the directories that are searched by groff’s \fC-m\fP
option and \fC.mso\fP request.  (groff searches for macro files
first in the directories in \fCGROFF_TMAC_PATH\fP, then in the
working directory, and finally in your home directory. See the
section for “Macro Directories” in the groff info file for
details.)

.IX macro files, loading of
Note that it is best to load these \fC.tmac\fP files into
your document with an \fC.mso\fP request rather than through
groff’s command-line option \fC-m\fP.  This is because
troff2page doesn’t support the same kind of command-line
arguments that groff does. But see below for avoiding cluttering
your source document.

.SH 2
Auxiliary files

.IX unsafe mode
.IX auxiliary files
.IX U@-U, groff option
Many of the macros defined in these \fC.tmac\fP files write
auxiliary files that are absorbed into the document during a
second run.  Note that in order to write these aux files,
groff must be run with the \fC-U\fP option for “unsafe”
mode.

.IX t@-t, groff option
.IX z@-z, groff option
As an example, consider \fCindex.ms\fP (the groff source for the
document you’re reading, which is the \fCdoc\fP subdirectory).  The following is one
way to get the correct PostScript output:

.EX
    % groff -t -U -z index.ms
.ft CI
    Rerun groff with -U
    index.ms:18: can't open `.trofftemp.toc': No such file or directory
    index.ms:38: can't open `.trofftemp.ind': No such file or directory

.ft C
    % groff -t -U index.ms > index.ps
.ft CI
    This is makeindex, version 2.15 [TeX Live 2016] (kpathsea + Thai support).
    Scanning style file ./.trofftemp.mst...............done (15 attributes redefined, 0 ignored).
    Scanning input file z.trofftemp.idx....done (61 entries accepted, 0 rejected).
    Sorting entries....done (393 comparisons).
    Generating output file z.trofftemp.ind....done (132 lines written, 0 warnings).
    Output written in z.trofftemp.ind.
    Transcript written in z.trofftemp.ilg.
.EE

The \fC-t\fP option (which calls the tbl
preprocessor) is needed because the
document \fCindex.ms\fP
uses a table.  The first run uses the \fC-z\fP option to disable
writing an output file, which we don’t need until the second
run.

In both runs, we use the \fC-U\fP option: The first run
needs unsafe mode to write the aux files, and the second run
needs it to process some of them with external programs to
create additional aux files.  Subsequent runs may dispense
with the \fC-U\fP, as all the required aux files are made.
(You will need the option again, if the aux files’ content
changes.)

troff2page also needs to process the document twice in order to absorb
information from the aux files. However:

(1) troff2page will automatically do the second processing
without needing the user to explicitly call it a second time; and

(2) troff2page doesn’t need any special option to run in “unsafe”
mode or to process tables.

.EX
    % troff2page index.ms
.ft CI
    index.ms:18: cannot open .troff2page_temp_index.toc: No such file or directory
    index.ms:38: can't open .troff2page_temp_index.ind: No such file or directory
    Missing: {eval, stylesheet, title, toc, .troff2page_temp_index.toc, last_page_number, index}
    Rerunning: troff2page index.ms
    This is makeindex, version 2.15 [TeX Live 2016] (kpathsea + Thai support).
    Scanning style file ./.troff2page_temp_index.mst...............done (15 attributes redefined, 0 ignored).
    Scanning input file z.troff2page_temp_index.idx....done (61 entries accepted, 0 rejected).
    Sorting entries....done (406 comparisons).
    Generating output file z.troff2page_temp_index.ind....done (151 lines written, 0 warnings).
    Output written in z.troff2page_temp_index.ind.
    Transcript written in z.troff2page_temp_index.ilg.
.EE

The same holds if you run troff2page by calling
the Lua procedure \fCtroff2page\fP within Lua, as described on
page \*[TAG:calling_troff2page_within_lua].

If you wish to have
the Lua procedure perform just one pass on the document, give it a
second argument that is non-false, e.g.,

.EX
    troff2page('index.ms', 'single-pass')
.EE

Call it the same way a second time to run the second pass, which
resolve the aux files. This is exactly analogous to calling
\fCgroff\fP twice on the same document to resolve aux files.

.TAG auxf
.IX auxiliary files, naming of
.IX troff2page@.troff2page, number register
The groff string \fC\e*[AUXF]\fP is used to construct the
names of the
auxiliary files.  By default it
will be quietly set to \fC.trofftemp\fP for groff and something slightly
different for troff2page.  You can change it to anything else in
your document before the first use of any macros that use or
write aux files.  It is a good idea to set it so that it
remains
different for groff and troff2page, so that the two
programs’ aux files don’t clash.  The number register
\fC\en[.troff2page]\fP (page \*[TAG:cond-bp]) suggests a way
to do this.

.SH 2
Simulating troff options

.IX troff options, translation of
The program \fCtroff2page\fP just takes a single argument.  Typically
this is a filename specifying
the input document file.  If the file so named does not exist, \fCtroff2page\fP
exits with a “could not find” message.

.IX help@--help, troff2page option
.IX version@--version, troff2page option
The only exceptions are when the argument is \fC--help\fP or \fC--version\fP,
in which case \fCtroff2page\fP displays an appropriate informative
text and exits.  For example,

.EX
    % troff2page --help
.ft CI
    troff2page version 20160216
    Copyright (C) 2003-2016 Dorai Sitaram
    For full details, please see http://ds26gte.github.io/troff2page/index.html
.EE

While this is intentionally similar to groff’s
\fC--help\fP and \fC--version\fP options, \fCtroff2page\fP cannot process true options as \fCgroff\fP
can.  Indeed, if \fC--help\fP and \fC--version\fP happen to be the names of input documents, \fCtroff2page\fP will
process them as
such.

In contrast, \fCgroff\fP options allow you to specify on the command-line not just the input file but also
additional information, e.g., \fC-m\fP to load macro files;
\fC-r\fP to pre-set number registers;
\fC-d\fP to pre-define strings;
\fC-f\fP to set default font family; etc. (Please see the groff man page
for details on all the provided options.)
The options can be usefully varied
with each call to \fCgroff\fP.

For options that do not make sense for HTML — e.g., the setting of
\fCPO\fP (adjusting the left margin to suit a particular printer) —, it is fine
that you can’t feed the same option to
\fCtroff2page\fP.  For the options
that \fIare\fP valid for both print and HTML — e.g., loading a macro
file that works for both output formats —, you
may need to add this information explicitly within the input document.
Thus, a \fC-m\fP command-line option would be replaced by an explicit call
to \fC.mso\fP within the document.

.TAG troff2pagerc
.IX init file for troff2page
.IX troff2pagerc@.troff2pagerc.tmac, macro file
However, this will not be a workable approach for some options that do
not belong to the document, or that may potentially need to
be varied for the same document, when processed by different users or
in different environments, or if you simply do not want to
clutter your document source.

For such cases, you may place the information in a file named
\fC.troff2pagerc.tmac\fP in one of your macro directories
(\fCGROFF_TMAC_PATH\fP, working directory, home). The working
directory is usual if your changes are geared to your document. A
home-directory or private \fCGROFF_TMAC_PATH\fP placement is also
plausible if your changes are valid for all your documents. A
more system-level \fCGROFF_TMAC_PATH\fP placement is typically
unadvised for such an ad hoc file.

\fCtroff2page\fP loads the first \fC.troff2pagerc.tmac\fP it
finds, if it exists, before processing its main argument file.

(Note that groff itself will not load \fC.troff2pagerc.tmac\fP
automatically.  But that is presumably OK, since you are using
groff command-line options to specify the same information
anyway.  If you do want groff to pick up this file, you can use
the option \fC-m.troff2pagerc\fP.)

.IX man.local, -man init file
If the input file is recognizably a man page (i.e., it has the
command \fC.TH\fP), both troff2page and groff will load, if it
exists, the init file \fCman.local\fP in the home directory.
