.\" last modified 2020-11-12
.SH 1
8. Recovery from errors
.LP
.IX errors
If troff2page fails on your document, it will display a message giving its
best guess on what the problem is and where it occurred in the source
document, and will offer to take you there so you can fix it immediately.
.EX
.ec
    \&\f(CIfilename:lineno: error description\fP
    Type e to edit file filename at line lineno; x to quit
    ?
.EE
In the first line, or the error diagnostic line,
\f(CIfilename\fP is the particular source file (which need not be the
main document file) and \f(CIlineno\fP is the estimated number of the line in
that file that caused the error.  (This is a popular error-reporting format
and is exploited by text editors for helping the debugging process.)
.PP
In the second line, troff2page offers to fire up a text editor with the cursor
approximately close to the
offending line.
.PP
.IX errors, editing location of
If you type \fCe\fP at the \fC?\fP prompt, troff2page starts the editor specified in your
\fCEDITOR\fP environment variable, or if that is not set, the editor named
\fCvi\fP on your system.  troff2page calls the editor with two arguments:
the first argument is \fC+\fP followed by the line number, and the second
argument is the filename.
(This argument style works for \fIall\fP
vi and emacs clones and I suspect most modern editors take care
to recognize it, so it isn’t as restrictive as it sounds.)
