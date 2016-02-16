.SH 1
9. GNU Info docs

.IX Info files
The troff2page distribution includes a couple of scripts for
generating GNU Info docs.

The script \fChtml2info\fP converts an HTML document, which must
be produced by troff2page, into an Info doc.

.EX
    html2info jobname.html
.EE

Here \fCjobname.html\fP is the opening file of the HTML document
(which may consist of other \fCjobname-Z-H-i.html\fP files, as
described on page \*[TAG:html-output]). The result is a single
file \fCjobname.info\fP that may then be displayed on any
Info viewer.

The script \fCtroff2info\fP converts an input troff document to
Info.

.EX
    troff2info jobname.ms
.EE

It first calls \fCtroff2page\fP on \fCjobname.ms\fP,
then passes the resultant \fCjobname.html\fP to \fChtml2info\fP,
which produces \fCjobname.info\fP.
