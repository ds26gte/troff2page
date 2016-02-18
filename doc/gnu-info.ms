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
