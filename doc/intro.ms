.SH 1
1. Introduction

.IX troff2page, script
troff2page converts troff (man and ms) documents into HTML web pages.

.TAG html-output
.IX calling troff2page from the command-line
To convert an input troff document named \fCjobname.ms\fP, use
the script \fCtroff2page\fP on the operating-system command line.

.EX
    troff2page jobname.ms
.EE

at your operating-system prompt.  This creates an output HTML file
\fCjobname.html\fP in the current directory.  (This HTML file has the same basename as the
input troff file (i.e., \fCjobname\fP), but its extension is
\fC.html\fP.)

.IX page breaks
If the input troff uses the page-break request
\fC.bp\fP,
then the output
HTML consists of a series of interlinked files: The first file is named
\fCjobname.html\fP;
the rest are
\fCjobname-Z-H-1.html\fP,
\fCjobname-Z-H-2.html\fP,
&c.

The script \fCtroff2page\fP runs on the Unix command-line on Cygwin,
Linux, Mac
OS X, and Solaris.  It uses the Common Lisp implementation mentioned in
the shell environment variable \fCLISP\fP, which can currently be set to
either \fCclisp\fP, \fCclozure\fP, \fCcmu\fP, \fCecl\fP, or \fCsbcl\fP:
the corresponding Lisp implementations being
\*[url http://clisp.sf.net]CLISP\&,
\*[url http://ccl.clozure.com]Clozure CL\&,
\*[url http://cmucl.org]CMUCL\&,
\*[url http://ecls.sf.net]ECL\&, and
\*[url http://sbcl.sf.net]SBCL\&.

Copy the script \fCtroff2page\fP to your \fCPATH\fP.

If \fCLISP\fP is not
set, some default Lisp implementation is assumed.

For more information,
please see the file \*[url \
https://github.com/ds26gte/troff2page/blob/master/INSTALL]INSTALL\&
in the distribution.

.SH 2
Calling troff2page from within Lisp

.TAG calling_troff2page_within_cl
.IX calling troff2page from Common Lisp
It is not necessary to run the file \fCtroff2page\fP as a
Unix script.  You can simply load \fCtroff2page\fP (it is
a Lisp file) into your Common Lisp, and then call the
Lisp procedure \fCtroff2page:troff2page\fP (i.e., the
procedure named \fCtroff2page\fP in the package
\fCtroff2page\fP) on your source document.  E.g.,

.EX
    (load "pathname/of/troff2page")
    (troff2page:troff2page "my-troff-document.ms")
.EE

The procedure \fCtroff2page:troff2page\fP can be called
several times, on the same or different documents, from
within the same Lisp session.
