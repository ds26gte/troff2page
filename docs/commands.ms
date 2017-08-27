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
.IX pca-tag.tmac, macro file
.IX pca-ix.tmac, macro file
.IX eval4troff.tmac, macro file
The troff2page distribution includes several troff macro
or tmac
files (with
extension \fCtmac\fP), both in the main directory and in the
sudirectory for the submodule \fCmpca\fP. They include general-purpose
extensions to the \fCms\fP package, e.g., \fCpca-tag.tmac\fP for
cross-references; \fCpca-ix.tmac\fP for index generation;
\fCpca-eval.tmac\fP for extending troff using Lua, etc.

.IX m@-m, command-line option
.IX mso@.mso, groff request
You should put these tmac files in one of your macro directories,
i.e., the directories that are searched by the \fC-m\fP
command-line option and \fC.mso\fP request.  (Both groff and troff2page search for macro files
first in the directories in \fCGROFF_TMAC_PATH\fP, then in the
working directory, and finally in your home directory. See the
section for “Macro Directories” in the groff info file for
details.)

.SH 2
Auxiliary files

.IX unsafe mode
.IX auxiliary files
.IX U@-U, command-line option
Many of the macros defined in these \fC.tmac\fP files write
auxiliary files that are absorbed into the document during a
second run.  Let’s first investigate how groff deals with them,
and then see how troff2page does the same in its own way. Note
that in order to write these aux files, groff must be run with
the \fC-U\fP option for “unsafe” mode.

.IX t@-t, command-line option
.IX z@-z, command-line option
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
the Lua procedure perform just one pass on the document, set the
global \fCSingle_pass_p\fP to true, i.e.,

.EX
    Single_pass_p = true
    troff2page('index.ms')
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
Commmand-line options

.IX command-line options
.IX version@--version, command-line option
.IX help@--help, command-line option
.IX v@-v, command-line option
.IX h@-h, command-line option
.IX m@-m, command-line option
.IX r@-r, command-line option
.IX d@-d, command-line option
.IX -@--, command-line option
\fCtroff2page\fP takes some, but not all, of the same options as \fCgroff\fP,
viz.,
\fC-v\fP or \fC--version\fP to display the version;
\fC-h\fP or \fC--help\fP to display help;
\fC-m\fP to load macro files from \fCGROFF_TMAC_PATH\fP;
\fC-r\fP to pre-set number registers;
\fC-d\fP to pre-define strings; and
\fC--\fP to signal the end of options.

The options can be varied with each call to \fCtroff2page\fP, just as
with \fCgroff\fP. Please see the groff man page
for details on all the provided options.

.IX z@-z, command-line option
.IX t@-t, command-line option
.IX U@-U, command-line option
\fCtroff2page\fP ignores all other \fCgroff\fP options, most with a warning.
The options
\fC-z\fP, \fC-t\fP, and \fC-U\fP are silently ignored, as they're always valid
for troff2page.

.EX
    % troff2page --help
.ft CI
    troff2page version 20170827
    Copyright (C) ...
    For full details, please see http://ds26gte.github.io/troff2page
.EE

In the unlikely event that you have a document file named
\fC--help\fP (and wish to process it), use
use

.EX
    % troff2page -- --help
.EE

Macro file options must be given without the suffix \fC.tmac\fP or prefix
\fCtmac.\fP. Thus, \fC-mxyz\fP or \fC-m xyz\fP looks for the macro file
\fCxyz.tmac\fP or \fCtmac.xyz\fP, whichever is found in the macro directories,
and loads it.

If after all the option processing, no file arguments remain,
\fCtroff2page\fP displays a “could not find” message.

If you find you need to specify an option that \fCtroff2page\fP
doesn't accept, you can always supply it in a macro file via
\fC-m\fP.

.TAG troff2pagerc
.IX init files for troff2page
.IX troff2pagerc@.troff2pagerc.tmac, macro file
\fCtroff2page\fP can read directives in some autoloaded files
without the need to explicitly use a command-line option. These
are useful to specify information that is relevant only the HTML
output.

The first such file is named
\fC.troff2pagerc.tmac\fP, placed in one of your macro directories
(\fCGROFF_TMAC_PATH\fP, working directory, home). The working
directory is a good location if your changes are geared to only those
documents that are in that directory.
If your changes will be used in all your documents, place it in
your home or a private \fCGROFF_TMAC_PATH\fP directory.
A
more system-level \fCGROFF_TMAC_PATH\fP placement is typically
unadvised for such an ad hoc file.

\fCtroff2page\fP loads the first \fC.troff2pagerc.tmac\fP it
finds, if it exists, before processing its main argument file.

.IX t2p@.t2p, macro file
In addition, \fCtroff2page\fP will also pick up a file
\fCjobname.t2p\fP, where \fCjobname\fP is the basename of the input document.
This is useful for directives that are specific to a document. Note that the
\fCjobname.t2p\fP, unlike \fC.troff2pagerc.tmac\fP, is looked for only in the
working directory, and not more generally in \fCGROFF_TMAC_PATH\fP.

(Note that groff itself will not load either \fC.troff2pagerc.tmac\fP or
\fCjobname.t2p\fP automatically.  But that is presumably OK, since you are
using groff command-line options to specify the same information anyway, or
these files contain information that's only relevant for HTML.  If you do want
groff to pick up this file, you can use the option \fC-m.troff2pagerc\fP.)

.IX man.local, -man init file
If the input file is recognizably a man page (i.e., it has the
command \fC.TH\fP), both troff2page and groff will load, if it
exists, the init file \fCman.local\fP in the home directory.
