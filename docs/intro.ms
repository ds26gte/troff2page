.SH 1
1. Introduction

.IX troff2page, script
troff2page is a \*[url http://www.lua.org]Lua\& scrit that converts troff (man and ms) documents into HTML web pages.

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
OS X, and Solaris.  

Copy the script \fCtroff2page\fP to your \fCPATH\fP.


For more information,
please see the file \*[url \
https://github.com/ds26gte/troff2page/blob/master/INSTALL]INSTALL\&
in the distribution.

.SH 2
Calling troff2page from within Lua

.TAG calling_troff2page_within_lua
.IX calling troff2page from Lua
It is not necessary to run the file \fCtroff2page\fP as a
Unix script.  You can simply load \fCtroff2page.lua\fP (\fCtroff2page\fP is a soft link
to the Lua file \fCtroff2page.lua\fP) into Lua, and then call the
Lua procedure \fCtroff2page\fP on your source document.  E.g.,

.EX
    dofile('troff2page.lua')
    troff2page('my-troff-document.ms')
.EE

The procedure \fCtroff2page\fP can be called
several times, on the same or different documents, from
within the same Lua session.
