.SH 1
4. Cross-references

.IX cross-references
.IX TAG@.TAG, macro
.IX pca-tag.tmac, macro file
troff2page provides a \fC.TAG\fP macro for managing
cross-references. A compatible groff definition is provided in
the supplied macro file \fCpca-tag.tmac\fP. (This overrides the
similarly named macro in groff’s \fCwww.tmac\fP, in order to allow
forward references.)

.EX
    .TAG sec_troffcl
.EE

associates the \fItag\fP \fCsec_troffcl\fP with the number of
the current page.  The \fIstring\fP \fC\e*[TAG:sec_troffcl]\fP
is defined to typeset as that page number.
Thus, in a hand-crafted table of contents, you could
use

.EX
    Extending troff using Common Lisp, \*[TAG:sec_troffcl]
.EE

In the HTML output, the string \fC\e*[TAG:sec_troffcl]\fP
furthermore is a link to where \fC.TAG sec_troffcl\fP was
called.

The \fCpca\fP macros use tags for internal bookkeeping: to avoid
name clashes, don’t start your own tags with two underscores.

\fC.TAG\fP takes an optional second argument.  The tag is
then associated with the text of the second argument instead
of the current page number.

.IX pca-toc.tmac, macro file
.IX table of contents
The
macro file \fCpca-toc.tmac\fP supplies a \fC.TOC\fP macro
for automatic generation of a table of contents. This can be used
by both groff and troff2page.

.IX GROWPS, number register
The troff2page aspect of \fCpca-toc.tmac\fP
uses \fC.TAG\fP. For both outputs, TOC entries are created for
headers of level \fC\\n[GROWPS]\fP or lower. By default,
\fCGROWPS\fP is set to 0, so you should set it to at least 1 to see
a TOC.

\fCpca-toc.tmac\fP doesn’t require you to modify how you use your header
macros (\fC.SH\fP or \fC.NH\fP). It is a solution to the
following statement from the groff manual:

“Altering the ‘NH’ macro to automatically build the table of contents
is perhaps initially more difficult, but would save a great deal of time
in the long run if you use ‘ms’ regularly.”

.IX pca-t2p-man.tmac, macro file
troff2page uses the macro file \fCpca-t2p-man.tmac\fP (if it can
find it in \fCGROFF_TMAC_PATH\fP)
to automatically generate a TOC for man pages,
with a TOC entry for each \fC.SH\fP in the input.
