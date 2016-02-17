.SH 1
9. GNU Info docs

.TAG gnuinfo
.IX Info files, generating
.IX troff2info@.troff2info, macro
.IX troff2pagerc@.troff2pagerc.tmac, macro file
You can call the macro

.EX
    .troff2info
.EE

within your document to signal to \fCtroff2page\fP that it should
also create an Info document.  Since \fCtroff2page\fP doesn’t
accept options, a good place to set \fC.troff2info\fP is in the
\fC.troff2pagerc.tmac\fP file, described on page
\*[TAG:troff2pagerc].

.IX html2info, script
The Info conversion uses the bash script \fChtml2info\fP which is
included in the \fCtroff2page\fP distribution. \fChtml2info\fP
uses lynx and sed.

\fChtml2info\fP may be called on its own,
if you forgot to or didn’t want to include \fC.troff2info\fP in
your document. E.g.,

.EX
    troff2page jobname.ms
    html2info jobname.html
.EE

Here \fCjobname.html\fP is the opening file of the HTML document
(which may consist of other \fCjobname-Z-H-i.html\fP files, as
described on page \*[TAG:html-output]). The result is a single
file \fCjobname.info\fP that may then be displayed on any
Info viewer.
