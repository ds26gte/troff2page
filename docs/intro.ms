.\" last modified 2019-09-29
.SH 1
1. Introduction
.LP
.IX troff2page, script
troff2page is a \*[url http://www.lua.org]Lua\& script that converts troff (man and ms) documents into HTML web pages.
.PP
.TAG html-output
.IX calling troff2page from the command-line
To convert an input troff document named \fCjobname.ms\fP, use
the script \fCtroff2page\fP on the operating-system command line.
.PP
.EX
    troff2page jobname.ms
.EE
.PP
at your operating-system prompt.  This creates an output HTML file
\fCjobname.html\fP in the current directory.  (This HTML file has the same basename as the
input troff file (i.e., \fCjobname\fP), but its extension is
\fC.html\fP.)
.PP
.IX page breaks
If the input troff uses the page-break request
\fC.bp\fP,
then the output
HTML consists of a series of interlinked files: The first file is named
\fCjobname.html\fP;
the rest are
\fCjobname-Z-H-1.html\fP,
\fCjobname-Z-H-2.html\fP,
etc.
.PP
The script \fCtroff2page\fP runs on the Unix command-line on Cygwin,
Linux, Mac
OS X, and Solaris.
.PP
Copy the script \fCtroff2page\fP to your \fCPATH\fP.
.PP
For more information,
please see the file \*[url \
https://github.com/ds26gte/troff2page/blob/master/INSTALL.adoc]INSTALL.adoc\&
in the distribution.
.PP
.SH 2
Calling troff2page from within Lua
.LP
.TAG calling_troff2page_within_lua
.IX calling troff2page from Lua
.
It is not necessary to run the file \fCtroff2page\fP as a
Unix script.  You can simply load \fCtroff2page.lua\fP (\fCtroff2page\fP is a soft link
to the Lua file \fCtroff2page.lua\fP) into Lua, and then call the
Lua procedure \fCtroff2page\fP on your source document.  E.g.,
.PP
.EX
    dofile('troff2page.lua')
    troff2page('my-troff-document.ms')
.EE
.PP
The procedure \fCtroff2page\fP can be called
several times, on the same or different documents, from
within the same Lua session.
.PP
.SH 2
Calling troff2page from Neovim
.LP
.TAG calling_troff2page_from_neovim
.IX calling troff2page from Neovim
.
The text editor Neovim embeds Lua, so you can
run \fCtroff2page\fP directly during an editor session.
This can be a convenient way to convert your troff source while
you're editing it, or even to automate the process using
appropriate autocommands.
.PP
To set up, first copy the files \fClua/troff2page.lua\fP and
\fCplugin/troff2page.vim\fP to subdirectories \fClua\fP and
\fCplugin\fP respectively, somewhere in your Neovim
\fC'runtimepath'\fP.  Alternatively, simple place a clone of the
\fCtroff2page\fP repo in a \fCpack\fP subdirectory, somewhere in
your \fC'runtimepath'\fP or \fC'packpath'\fP.
.PP
You now have the command \fCTroff2page\fP that you can call with
no argument or with a single filename argument (completion is
provided).
.PP
.EX
    :Troff2page
    :Troff2page filename
.EE
.PP
Without an argument, \fCTroff2page\fP runs \fCtroff2page\fP on
the file in the current window.  With an filename argument, it
runs \fCtroff2page\fP on that file.
