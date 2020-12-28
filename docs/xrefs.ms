.\" last modified 2020-12-26
.SH 1
4.  Cross-references
.LP
.IX cross-references
.IX TAG@.TAG, -mpca macro
.IX pca-tag.tmac, macro file
Troff2page provides a \fC.TAG\fP macro for managing
cross-references.  A compatible groff definition is provided in
the supplied macro file \fCpca-tag.tmac\fP. (This overrides the
similarly named macro in groff’s \fCwww.tmac\fP, in order to allow
forward references.)
.EX
    .TAG sec_trofflua
.EE
associates the \fItag\fP \fCsec_trofflua\fP with the number of
the current page.  The \fIstring\fP \fC\e*[TAG:sec_trofflua]\fP
is defined to typeset as that page number.
Thus, in a hand-crafted table of contents, you could
use
.EX
    Extending groff using Lua, \*[TAG:sec_trofflua]
.EE
In the HTML output, the string \fC\e*[TAG:sec_trofflua]\fP
furthermore is a link to where \fC.TAG sec_trofflua\fP was
called.
.PP
The \fCpca\fP macros use tags for internal bookkeeping: to avoid
name clashes, don’t start your own tags with two underscores.
.PP
\fC.TAG\fP takes an optional second argument.  The tag is
then associated with the text of the second argument instead
of the current page number.
.PP
.SH 2
ToC
.LP
.IX pca-toc.tmac, macro file
.IX table of contents
.IX ToC@.ToC, -mpca macro
The
macro file \fCpca-toc.tmac\fP supplies a \fC.ToC\fP macro
for automatic generation of a table of contents.  This can be used
by both groff and Troff2page.
.PP
.IX GROWPS, -ms number register
For both outputs, ToC entries are created for
headers of level \fC\\n[GROWPS]\fP or lower. By default,
\fCGROWPS\fP is set to 0, so you should set it to at least 1 to see
a ToC.
.PP
.IX PSINCR, -ms number register
The original purpose of \fCGROWPS\fP was to govern the font-size
of headers at levels below it, provided it is set to at least 2
and the register \fC\en[PSINCR]\fP is set (which it is, by
default, to 1p).
Troff2page respects this too. If you’d rather use CSS to affect
section-header style, including font-size, but you
must have \fCGROWPS\fP \(>= 2
because your ToC requires it, then conditionally set \fCPSINCR\fP
to 0.
.EX
    .if \n[.troff2page] .nr PSINCR 0
.EE
.PP
\fCpca-toc.tmac\fP doesn’t require you to modify how you use your header
macros (\fC.SH\fP or \fC.NH\fP). It is a solution to the
following statement from the groff manual:
.QS
Altering the ‘NH’ macro to automatically build the table of contents
is perhaps initially more difficult, but would save a great deal of time
in the long run if you use ‘ms’ regularly.
.QE
.IX pca-t2p-man.tmac, macro file
Troff2page autoloads the macro file \fCpca-t2p-man.tmac\fP (if it can
find it in \fCGROFF_TMAC_PATH\fP)
to automatically generate a ToC for man pages,
with a ToC entry for each \fC.SH\fP in the input.
.PP
.SH 2
Bibliography
.LP
The \fC.BIB\fP macro from
the macro file \fCpca-bib.tmac\fP introduces a paragraph that is
a simple bibliographic reference, e.g.,
.EX
    .BIB landes_clock
    David S. Landes, \fIRevolutions in Time: Clocks and the
    Making of the Modern World\fP, Belknap Press, 1983.
.EE
If it is the \fIn\fPth such reference in the document, it is prefixed
with “[\fIn\fP]” in the output.  Furthermore, the label
\fCTAG:landes_clock\fP is
associated with \fIn\fP, using the cross-reference mechanism
described earlier, and can be used to cite the reference.  E.g.,
.EX
    For a history of the first portable device that, for better
    or worse, completely changed how we live, see
    Landes\~[\*[TAG:landes_clock]].
.EE
