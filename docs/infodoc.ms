.\" last modified 2020-11-08
.SH 1
9. GNU Info docs
.LP
.TAG gnuinfo
.IX Info files, generating
.IX troff2info@.troff2info, macro
.IX troff2pagerc@.troff2pagerc.tmac, macro file
You can call the macro
.PP
.EX
    .troff2info
.EE
.PP
within your document to signal to \fCtroff2page\fP that it should
also create an Info document.
.PP
\fCtroff2page\fP includes a (do-nothing) definition for \fC.troff2info\fP. To
ensure that regular groff can process your document,
it’s best to use
.PP
.EX
    .if d troff2info .troff2info
.EE
.PP
If the basename of the input troff document is \fCjobname\fP, the
Info file is created in \fCjobname.info\fP, which may be
displayed on any Info viewer.
.PP
A good place to set \fC.troff2info\fP external to the input troff
document is in \fC.troff2pagerc.tmac\fP or \fCjobname.t2p\fP,
described on page \*[TAG:troff2pagerc].
