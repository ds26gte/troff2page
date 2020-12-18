.\" last modified 2020-12-19
.SH 1
2.  troff, groff, and troff2page commands
.LP
.IX drop caps
.IX man@-man, macro package
.IX ms@-ms, macro package
.IX groff
.DC T ROFF2PAGE terracottapink
recognizes most of the commands (requests, macros,
diversions, strings, escapes, glyphs) of raw troff and its
-ms and -man macro packages, including such rather
recherch\('e macros as \fC.DC\fP, here used to produce a drop
capital
colored terracotta pink.
The syntax recognized is the improved kind
supported by \*[url https://www.gnu.org/software/groff]groff\&, \*[url \
http://heirloom.sf.net/doctools.html]Heirloom troff\&, and \*[url
http://github.com/aligrudi/neatroff]Neatroff\&, i.e., macro, string,
and glyph names can be arbitrarily long, and strings can
have arguments.  Most of the commands are converted to their
obvious HTML equivalent.\**
.
.FS
.IX footnotes
.IX FS@.FS, -ms macro
.IX FE@.FE, -ms macro
E.g., -ms’s footnotes (\fC\e**\fP and \fC.FS\fP/\fC.FE\fP) have a
straightforward translation in the HTML, with the footnote text set at the
bottom of the HTML page, and with the footnote markers in the body and the
footnote hyperlinking to each other.
.FE
.
Please consult troff and groff documentation for these commands.  We will
concentrate here on those commands whose HTML counterpart is not immediately
obvious.  In order to avoid constantly qualifying my sentences, I shall
henceforth use groff as the troff implementation to work alongside
troff2page.  There will be some modification needed when using
other troff implementations.
.PP
.IX pm@.pm, groff request
The request \fC.pm\fP lists on the console, in alphabetical
order,
all the requests, macros, and strings defined by troff2page.  You
can then search for their behavior in the troff2page and/or groff
manuals.
.PP
.SH 2
mpca macro files
.LP
.IX macro files provided with troff2page
.IX mpca@-mpca, macro package
.IX mpca macros
.IX pca-bib.tmac, macro file
.IX pca-dc.tmac, macro file
.IX pca-eval.tmac, macro file
.IX pca-img.tmac, macro file
.IX pca-ix.tmac, macro file
.IX pca-sc.tmac, macro file
.IX pca-tag.tmac, macro file
.IX pca-toc.tmac, macro file
.IX pca-verb.tmac, macro file
.IX pca.tmac, macro file
troff2page can process documents that use the \fCms\fP extension macros
provided in \*[url http://github.com/ds26gte/mpca]mpca\&. For
convenience, this repo is included as a submodule \fCmpca\fP.
It includes general-purpose extensions to the \fCms\fP package,
viz.,
\fCpca-bib.tmac\fP for bibliographic citations;
\fCpca-dc.tmac\fP for drop caps;
\fCpca-eval.tmac\fP for extending groff using Lua;
\fCpca-img.tmac\fP for image insertion;
\fCpca-ix.tmac\fP for index generation;
\fCpca-sc.tmac\fP for thought breaks;
\fCpca-tag.tmac\fP for cross-references;
\fCpca-toc.tmac\fP for table of contents;
\fCpca-verb.tmac\fP for verbatim displays.
These extensions may loaded severally or as the
single comprehensive macro file \fCpca.tmac\fP.
To load them all, use the command-line option \fC-mpca\fP or
include \fC.mso pca.tmac\fP in your document source.
Please consult
this submodule’s documentation for more information.
.PP
.IX GROFF_TMAC_PATH, environment variable
In order to take advantage of the \fCmpca\fP tmac files, you
should place them in one of your groff macro directories. (Both
groff and troff2page search for macro files first in the
directories in \fCGROFF_TMAC_PATH\fP, then in the working
directory, and finally in your home directory.  See the section
for “Macro Directories” in the groff info file for details.)
.PP
.IX m@-m, groff command-line option
.IX mso@.mso, groff request
Your input document sources the \fCmpca\fP macro files using
either the \fC-m\fP command-line option or the \fC.mso\fP request.
.PP
.SH 2
Auxiliary files
.LP
.IX unsafe mode
.IX auxiliary files
.IX U@-U, groff command-line option
Many of the macros defined in these \fC.tmac\fP files write
auxiliary files that are absorbed into the document during a
second run.  Let’s first investigate how groff deals with them,
and then see how troff2page does the same in its own way.  Note
that in order to write these aux files, groff must be run with
the \fC-U\fP option for “unsafe” mode.
.PP
.IX t@-t, groff command-line option
.IX z@-z, groff command-line option
.IX PostScript
As an example, consider \fCindex.ms\fP (the groff source for the
document you’re reading, which is the \fCdoc\fP subdirectory).  The following is one
way to get the correct PostScript output:
.EX
    % groff -t -U -z index.ms
.ft CI
    Rerun groff with -U
    index.ms:18: can't open `.trofftemp.toc': No such file or directory
    index.ms:38: can't open `.trofftemp.ind': No such file or directory
.br
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
.PP
In both runs, we use the \fC-U\fP option: The first run
needs unsafe mode to write the aux files, and the second run
needs it to process some of them with external programs to
create additional aux files.  Subsequent runs may dispense
with the \fC-U\fP, as all the required aux files are made.
(You will need the option again, if the aux files’ content
changes.)
.PP
troff2page also needs to process the document twice in order to absorb
information from the aux files.  However:
.PP
i.  troff2page will automatically do the second processing
without needing the user to explicitly call it a second time; and
.PP
ii.  troff2page doesn’t need any special option to run in “unsafe”
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
.PP
If you wish to have
the Lua procedure perform just one pass on the document, set the
global \fCSingle_pass_p\fP to true, i.e.,
.EX
    Single_pass_p = true
    troff2page 'index.ms'
.EE
Call it the same way a second time to run the second pass, which
resolve the aux files.  This is exactly analogous to calling
\fCgroff\fP twice on the same document to resolve aux files.
.PP
.TAG auxf
.IX auxiliary files!naming of
.IX troff2page@.troff2page, troff2page number register
.IX AUXF@\e*[AUXF], groff string register
The groff string \fC\e*[AUXF]\fP is used to construct the
names of the
auxiliary files.  By default it
will be quietly set to “\fC.trofftemp\fP” for groff and
“\fC.troff2page_temp_\fP\fIJobname\fP” for troff2page, where
\fIJobname\fP is the basename of the main input document file.
.PP
You can change it to anything else in
your document before the first use of any macros that use or
write aux files.  It is a good idea to set it so that it
remains
different for groff and troff2page, so that the two
programs’ aux files don’t clash.  The number register
\fC\en[.troff2page]\fP (page \*[TAG:cond-bp]) suggests a way
to do this.
