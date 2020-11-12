.\" last modified 2020-11-12
.SH 1
4. Cross-references
.LP
.IX cross-references
.IX TAG@.TAG, macro
.IX pca-tag.tmac, macro file
troff2page provides a \fC.TAG\fP macro for managing
cross-references. A compatible groff definition is provided in
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
    Extending troff using Lua, \*[TAG:sec_trofflua]
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
.IX pca-toc.tmac, macro file
.IX table of contents
The
macro file \fCpca-toc.tmac\fP supplies a \fC.ToC\fP macro
for automatic generation of a table of contents. This can be used
by both groff and troff2page.
.PP
.IX GROWPS, number register
The troff2page aspect of \fCpca-toc.tmac\fP
uses \fC.TAG\fP. For both outputs, ToC entries are created for
headers of level \fC\\n[GROWPS]\fP or lower. By default,
\fCGROWPS\fP is set to 0, so you should set it to at least 1 to see
a ToC.
.PP
\fCpca-toc.tmac\fP doesn’t require you to modify how you use your header
macros (\fC.SH\fP or \fC.NH\fP). It is a solution to the
following statement from the groff manual:
.PP
“Altering the ‘NH’ macro to automatically build the table of contents
is perhaps initially more difficult, but would save a great deal of time
in the long run if you use ‘ms’ regularly.”
.PP
.IX pca-t2p-man.tmac, macro file
troff2page uses the macro file \fCpca-t2p-man.tmac\fP (if it can
find it in \fCGROFF_TMAC_PATH\fP)
to automatically generate a ToC for man pages,
with a ToC entry for each \fC.SH\fP in the input.
