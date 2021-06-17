.\" last modified 2021-06-17
.SH 1
11.  GNU Info docs
.LP
.TAG gnuinfo
.IX Info files, generating
.IX troff2page2info@.troff2page2info, Troff2page macro
You can call the macro
.EX
    .troff2page2info
.EE
within your document to signal to \fCtroff2page\fP that it should
also create an Info document.
.PP
If the basename of the input groff document is \fCjobname\fP, the
Info file is created in \fCjobname.info\fP, which may be
displayed on any Info viewer.
.PP
.IX troff2pagerc@.troff2pagerc, user macro file
.IX t2p@.t2p, user macro file
A good place to set \fC.troff2page2info\fP without modifying the input groff
document is in \fC.troff2pagerc\fP or \fCjobname.t2p\fP,
described on page \*[TAG:troff2pagerc].
.PP
.IX TROFF2PAGE2INFO, environment variable
If you’re sure you will always want an Info file for whatever document
you give to \fCtroff2page\fP, then you can set the
environment variable \fCTROFF2PAGE2INFO\fP (the value doesn’t
matter):
.EX
    export TROFF2PAGE2INFO=always
.EE
