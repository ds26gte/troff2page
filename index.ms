.\" vi:ft=nroff
.so troff2page-doc-macs.ms
.
.ND 2011-11-24  \"last modified
.
.TL
troff2page
.AU
.ie \n[.troff2page] \{\
\*[url ../index.html "Dorai Sitaram"]
\*[url troff2page.tar.bz2  "Download the \*[troff2page_version_th] version"]
.\}
.el \{\ Dorai Sitaram
\*(DY
.\}
.RT
.
.LK

.SH 1. Introduction
troff2page converts troff (man and ms) documents into HTML web pages.

.IX calling troff2page from the command-line
To convert an input troff document named \fCjobname.ms\fP, type

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
etc.

The script \fCtroff2page\fP runs on the Unix command-line on Cygwin,
Linux, Mac
OS X, and Solaris.  It uses the Common Lisp implementation mentioned in
the shell environment variable \fCLISP\fP, which can currently be set to
either \fCclisp\fP, \fCclozure\fP, \fCcmu\fP, \fCecl\fP, or \fCsbcl\fP:
the corresponding Lisp implementations being
\*[url http://clisp.sf.net CLISP],
\*[url http://ccl.clozure.com "Clozure CL"],
\*[url http://cmucl.org CMUCL],
\*[url http://ecls.sf.net ECL], and
\*[url http://sbcl.sf.net SBCL].

If \fCLISP\fP is not
set, some default Lisp implementation is assumed.

For more information,
please see the file \*[url INSTALL]
in the distribution.

.SS Calling troff2page from within Lisp
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

.SH 2. troff and troff2page commands
.IX drop caps in color
.defcolor terracottapink rgb #9b3d3d
.DC T ROFF2PAGE terracottapink
recognizes most of the commands (requests, macros,
diversions, strings, escapes, glyphs) of raw troff and its
ms and man macro packages, including such rather
recherch\('e macros as \fC.DC\fP, here used to produce a drop cap
colored terracotta pink.
The syntax recognized is the improved kind
supported by \*[url http://groff.ffii.org groff] and \*[url \
http://heirloom.sf.net/doctools.html "Heirloom troff"], i.e., macro, string,
and glyph names can be arbitrarily long, and strings can
have arguments.  Most of the commands are converted to their
obvious HTML equivalent.\**
.
.FS
.IX footnotes
E.g., ms's footnotes (\fC\e**\fP and \fC.FS\fP/\fC.FE\fP) have a
straightforward translation in the HTML, with the footnote text set at the
bottom of the HTML page, and with the footnote markers in the body and the
footnote hyperlinking to each other.
.FE
Please consult troff and groff documentation for these commands.  We will
concentrate here on those commands whose HTML counterpart is not immediately
obvious.

.IX macro files provided with troff2page
.IX m@-m, groff option
.IX url.tmac, macro file
.IX index.tmac, macro file
.IX eval4troff.tmac, macro file
.IX mso@.mso, groff request
The troff2page distribution includes several files with
extension \fCtmac\fP, viz., \fCurl.tmac\fP for inserting
hyperlinks; \fCindex.tmac\fP for index generation;
\fCeval4troff.tmac\fP
for extending troff using Common Lisp; and
\fCdefhsl.tmac\fP for defining color names using the HSL scheme.
You should put these \fC.tmac\fP files in one of your
macro directories, i.e., the directories that are searched by groff's
\fC-m\fP option and \fC.mso\fP request.  (See the section for ``Macro
Directories'' in the groff info file for details.  In a pinch, your home
directory works as a macro directory.)

.IX macro files, loading of
Note that it is best to load these \fC.tmac\fP files into
your document with an \fC.mso\fP request rather than through
groff's command-line option \fC-m\fP.  This is because
troff2page doesn't support the same kind of command-line
arguments that groff does.

.SS Auxiliary files
.IX unsafe mode
.IX auxiliary files
.IX U@-U, groff option
Many of the macros defined in these \fC.tmac\fP files write
auxiliary files that are absorbed into the document during a
second run.  Note that in order to write these aux files,
groff must be run with the \fC-U\fP option for ``unsafe''
mode.

.IX t@-t, groff option
.IX z@-z, groff option
As an example, consider \fCindex.ms\fP (the groff source for the
document you're reading).  The following is one
way to get the correct PostScript output:

.EX
    % groff -t -U -z index.ms
.ft CI
    defhsl.tmac:8: can't open `.trofftemp_lisp_1.tmp' ...
    Rerun groff with -U
    index.ms:187: can't open `.trofftemp.aux' ...
    index.ms:799: can't open `.trofftemp.ind' ...

.ft C
    % groff -t -U index.ms > index.ps
.EE

The \fC-t\fP option (which calls the tbl
preprocessor) is needed because the
document \fCindex.ms\fP
uses a table.  The first run uses the \fC-z\fP option to disable
writing an output file, which we don't need until the second
run.

In both runs, we use the \fC-U\fP option: The first run
needs unsafe mode to write the aux files, and the second run
needs it to process some of them with external programs to
create additional aux files.  Subsequent runs may dispense
with the \fC-U\fP, as all the required aux files are made.
(You will need the option again, if the aux files' content
changes.)

troff2page is also run twice on the document to absorb
information from the aux files.  However, troff2page doesn't
need any special option as it is always run in what groff
would consider ``unsafe'' mode, and it processes tables by
itself.

.EX
    % troff2page index.ms
.ft CI
    Missing: (.troff2page_temp_index.ind .troff2page_temp_index.aux
    LAST-PAGE-NUMBER TOC TITLE .troff2page_temp_index_lisp_1.tmp)
    Rerun: troff2page index.ms

.ft C
    % troff2page index.ms
.EE

.TAG auxf
.IX auxiliary files, naming of
.IX troff2page@.troff2page, number register
The groff string \fC\e*[AUXF]\fP is used to construct the
names of the
auxiliary files.  By default it
will be quietly set to \fC.trofftemp\fP for groff and something slightly
different for troff2page.  You can change it to anything else in
your document before the first use of any macros that use or
write aux files.  It is a good idea to set it so that it
remains
different for troff and troff2page, so that the two
programs' aux files don't clash.  The number register
\fC\en[.troff2page]\fP (page \*[cond-bp]) suggests a way
to do this.

.SS Simulating troff options
.IX troff options, translation of
The program \fCtroff2page\fP just takes a single argument.  Typically
this is a filename specifying
the input document file.  If the file so named does not exist, \fCtroff2page\fP
exits with a ``could not find'' message.

.IX help@--help, troff2page option
.IX version@--version, troff2page option
The only exceptions are when the argument is \fC--help\fP or \fC--version\fP,
in which case \fCtroff2page\fP displays an appropriate informative
text and exits.  For example,

.EX
    % troff2page --help
.ft CI
    troff2page version 20111124
    Copyright (C) ...
    For full details, please see http://www...
.EE

While this is intentionally similar to groff's
\fC--help\fP and \fC--version\fP options, \fCtroff2page\fP cannot process true options as \fCgroff\fP
can.  Indeed, if \fC--help\fP and \fC--version\fP happen to be the names of input documents, \fCtroff2page\fP will
process them as
such.

In contrast, \fCgroff\fP options allow you to specify on the command-line not just the input file but also
additional information, e.g., \fC-m\fP to load macro files;
\fC-r\fP to pre-set number registers;
\fC-d\fP to pre-define strings;
\fC-f\fP to set default font family; etc. (Please see the groff man page
for details on all the provided options.)
The options can be usefully varied
with each call to \fCgroff\fP.

For options that do not make sense for HTML \*- e.g., the setting of
\fCPO\fP (adjusting the left margin to suit a particular printer) \*-, it is fine
that they cannot also be fed to \fCtroff2page\fP.  For the options
that \fIare\fP valid for both print and HTML \*- e.g., loading a macro
file that works for both output formats \*-, you
may need to add this information explicitly within the input document.
Thus, a \fC-m\fP command-line option would be replaced by an explicit call
to \fC.mso\fP within the document.

.IX init file for troff2page
.IX .troff2pagerc.tmac, troff2page init file
However, this will not be a workable approach for some options that do
not quite belong to the document, or that may potentially need to
be varied for the same document, when processed by different users or
in different environments, e.g., settings for registers like
\fCGROWPS\fP and \fCPSINCR\fP.  For such cases, you may place the
information in a troff macro file \fC.troff2pagerc.tmac\fP in your
home directory.  \fCtroff2page\fP will load this file, if it exists,
before processing its argument file.

(Note that groff or troff
will not load \fC.troff2pagerc.tmac\fP automatically.  But that is
presumably OK, since you are using command-line options to specify the
same information anyway.  If you do want groff to pick up this file,
you can use the option \fC-m.troff2pagerc\fP.)

.IX man.local, -man init file
If the input file is recognizably a man page (i.e., it has the command
\fC.TH\fP), both troff2page and groff will load, if it exists, the init file
\fCman.local\fP in the home directory.

.SH 3. Page layout
.IX page breaks
.IX bp@.bp, troff request
The page-break command \fC.bp\fP ends the current HTML page and start a new
one.  \fC.bp\fP causes a page-break in both the HTML and the print outputs.

.TAG cond-bp
.IX conditional for troff2page versus troff
.IX troff2page@.troff2page, number register
Generally, page-breaks require a different aesthetic in HTML than in
print.  You can use troff conditionals to express this difference:

.EX
    .if \n[.troff2page] .bp
.EE

causes a page-break only in the HTML, whereas

.EX
    .if !\n[.troff2page] .bp
.EE

causes a page-break only in print.

As can be seen, the number register \fC\en[.troff2page]\fP has a \fItrue\fP
value, i.e., a number greater than zero, only when troff2page processes the
document.\**
.
.FS
The greater-than-zero number held in the register
\fC\en[.troff2page]\fP
is in fact the version
number of the troff2page program processing the document.  This is a number
such as 20050327, which would be the version number of the troff2page
released on 2005 March 27.  \fC\en[.troff2page]\fP could plausibly be used
to distinguish not just troff2page from troff, but also between various versions
of troff2page.  Thus, one could, if the need were dire, write a document
that translates differently with different versions of troff2page.
.FE

.IX page breaks for HTML only
If may be convenient to define a \fC.HBP\fP macro that causes a page-break
only for HTML:

.EX
    .de HBP
    .if \n[.troff2page] .bp
    ..
.EE

Note that troff2page, like troff, does not automatically cause a page break
at the sectioning commands.  Use \fC.bp\fP or a macro like \fC.HBP\fP to
explicitly to insert breaks as needed.

.IX navigation bar
Each page in a multiple-page HTML output has a navigation bar at its
head and foot.  The bar contains links to the first, previous, and next
page, and the table-of-contents and index pages.  If any of these pages
doesn't exist, or if it is the same as the page containing the
navigation bar, then the link for it is disabled.

.SS HTML-style paragraphs
By default, troff2page sets paragraphs exactly as groff does: the first
lines of paragraphs are indented (unless explicitly disabled via an
\fC.LP\fP), and
the vertical distance between adjacent paragraphs is the same smallish
amount that groff employs.  These two values are given by the number
registers \fCPI\fP and \fCPD\fP, which (for the ms format) are 0.3n and 0.3v
respectively.

If you wish to have the kind of block paragraphs customary in HTML, it
is not enough to set \fCPI\fP to 0, for the prevailing value of \fCPD\fP is too
small to comfortably tell adjacent paragraphs apart.  You could set \fCPD\fP
to a larger value, but as a convenience, troff2page allows you to set \fCPD\fP
to a \fInegative\fP value, which leads to whatever default paragraph
separation that HTML uses.  Note that setting \fCPD\fP to a negative value
should be done only for HTML, as groff will happily overstrike
text in order to respect a negative \fCPD\fP:

.EX
    .if \n[.troff2page] \{\
    .nr PI 0n
    .nr PD 0-1p
    .\}
.EE

Unlike groff ms, which uses the line length given by the register
\fCLL\fP,
troff2page by default does not restrict the width of its HTML pages.
Text will narrow or widen to fit the current browser window width.  However, if
you explicitly set \fCLL\fP (instead of relying on ms's default), troff2page
will respect that line length.  Nevertheless, if the user shrinks the
browser window to a width less than \fCLL\fP, the text will correspondingly
shrink too to fit the window.  This is to avoid the need for horizontal
scrolling.

A good \fCLL\fP value for troff2page should be a bit larger than
ms's 6 inches, which is too narrow for a browser.  The following sets it
to 18 cm, making sure it takes effect only for HTML:

.EX
    .if \n[.troff2page] .nr LL 18c
.EE

.SH 4. Table of contents
.IX table of contents
When converting man documents, troff2page automatically generates an
untitled table of contents (toc) at the top of the output.  Toc entries are
generated for each \fC.SH\fP in the input.  The toc entry for a section and
that section's header are hyperlinks to each other.

.IX TAG@.TAG, macro
.IX url.tmac, macro file
For ms documents, you will need to generate your own table of
contents.  \fCurl.tmac\fP supplies the macro \fC.TAG\fP for capturing page
numbers. (This overrides the \fC.TAG\fP macro of
groff's \fCwww.tmac\fP, in order to allow forward references.)

.EX
    .TAG sec:troffcl
.EE

associates the label \fCsec:troffcl\fP with the number of
the current page.  The string \fC\e*[sec:troffcl]\fP
is defined to typeset as that page number.
Thus, in your hand-crafted toc, you could
use

.EX
    Extending troff using Common Lisp, \*[sec:troffcl]
.EE

In the HTML output, the string \fC\e*[sec:troffcl]\fP
furthermore is a link to where \fC.TAG sec:troffcl\fP was
called.

\fC.TAG\fP takes an optional second argument.  The label is
then associated with the text of the second argument instead
of the current page number.

.SH 5. Making an index
.IX index
.IX index.tmac, macro file
.IX makeindex
The supplied macro file \fCindex.tmac\fP
creates a sorted
index, with the aid of the external program makeindex.
makeindex is included with TeX distributions, but you can
obtain just the makeindex distribution from \*[url \
http://stuff.mit.edu/afs/sipb/project/tex-dev/src/tar/makeindex.tar.gz].

Note that the indexes created by groff and troff2page are
necessarily different, because the respective paginations
are different.  In addition, the index generated for
troff2page has the additional feature of hyperlinking to the
appropriate locations in the body text.

.IX IX@.IX, macro
The call

.EX
    .IX item
.EE

marks the text ``item'' as an indexable item.  The metacharacters \fC@\fP,
\fC!\fP, \fC"\fP, and \fC|\fP can be used to respectively specify (a)
alternate alphabetization, (b) subitems, (c) literal metacharacters, and
(d) encapsulation of the page number.  Please see the
makeindex
documentation for all the details.  Essentially, the syntax for entering
index entries is the same \*[url \
http://tex.loria.fr/bibdex/makeindex.pdf "as for LaTeX"], except that in troff we use
``\fC.IX item\fP'' where in LaTeX one would use
\%``\fC\eindex{item}\fP''.

\fCindex.tmac\fP will call makeindex to create a
sorted index in the auxiliary file \fC\e*[AUXF].ind\fP, which can be
slurped back into the input document:

.EX
    .so \*[AUXF].ind
.EE

Adding a section header on top is up to you.

.SH 6. Slideshows
.IX slideshow
To cause your troff source to be converted into slideshow-ready HTML, have
it source the provided macro file \fCt2pslides.tmac\fP.
This macro file uses a version of the \*[url \
http://mozpoint.mozdev.org MozPoint] library to
produce the appropriate JavaScript and style sheets to
convert your sequence of HTML pages into a Web presentation.

HTML pages meant for presentation use larger, bolder fonts, and do not have
navigation bars.

The following table describes the keys used to control the
presentation:

.TS
tab(#), center, allbox;
cb cb
l l.
Action # Effect
n, space, mouse-click # Next slide
p, backspace # Previous Slide
t, 0 # Title, or 0pening, slide
\fIn\fP (integer \(>= 0) # \fIn\fPth slide
b # toggle current slide with Black screen
w # toggle current slide with White screen
.TE

Note that the slides are numbered from 0 onward (rather than
1).  Also, when
typing a number \fIn\fP that's two or more digits long to
get the \fIn\fPth slide, the digits should be pressed
fairly rapidly so they are interpreted together.

.SH 7. Extending troff using Common Lisp
.IX extending troff and troff2page with Common Lisp
.IX eval@.eval, macro
.IX endeval@.endeval, macro
.IX eval4troff.tmac, macro file
To invoke Common Lisp from troff, we use the macro \fC.eval\fP with its closer
\fC.endeval\fP.   These are
defined in the
supplied
troff macro file \fCeval4troff.tmac\fP, which you should put
in a macro directory.

\&\fC.eval\fP does only one thing: It
allows you to place arbitrary Lisp code until the following
\fC.endeval\fP, and the text written to standard output by
this Lisp code
is substituted for the \fC.eval\fP ... \fC.endeval\fP.
The usefulness of this tactic will be apparent from an
example.
Consider the following troff document, \fCpi.1\fP:

.EX
    .mso eval4troff.tmac
    .
    The ratio of the circumference of a circle to
    its diameter is \(*p \(~=
    .eval
    ;following prints pi, because cos(pi) = -1
    (princ (acos -1))
    (princ ".")
    (terpri)
    .endeval
.EE

.IX unsafe mode
.IX z@-z, groff option
.IX U@-U, groff option
Run troff (actually groff, and in unsafe mode too) on \fCpi.1\fP:

.EX
    groff -z -U -ms pi.1
.EE

(The \fC-z\fP avoids generating output, because we are not ready for it
yet.  The \fC-U\fP runs in ``unsafe'' mode, i.e., it allows the writing of
aux files.)
You will find that the groff call produces a message like
the following:

.EX
.ec
    \f(CI.trofftemp.lisp missing for this run
    Rerun groff with -U
.EE

Call groff again as follows:

.EX
    groff -U -ms pi.1 > pi.ps
.EE

\fCpi.ps\fP will now look like:

.B1
.RS
The ratio of the circumference of a circle to
its diameter is \(*p \(~=
.eval
;following prints pi, because cos(pi) = -1
(princ (acos -1))
(princ ".")
(terpri)
.endeval
.RE
.B2

The first groff call produces a Lisp file
\fC.trofftemp.lisp\fP.\**
.FS
This name may be different based on
your setting of \fC\e*[AUXF]\fP \*- see page \*[auxf].
.FE
The second groff
call invokes Lisp to create an auxiliary file for each \fC.eval\fP that gets sourced
back into the document.

It is clear that Lisp code via \fC.eval\fP can
serve as a very powerful \fIsecond extension language\fP
for troff.  This benefit is available even when the document
is processed by troff2page:
We could run troff2page on the same document, \fCpi.1\fP, and the
resulting \fCpi.html\fP will show the same content.

.IX extending troff and troff2page differently with Common Lisp
Furthermore, we can embed  \fC.eval\fP-enclosed Lisp code inside an
\fC.if\fP (or \fC.ie\fP or \fC.el\fP) statement so that it gets executed
only for troff or only for troff2page.  (Recall we used the number register
\fC\en[.troff2page]\fP for this purpose on page \*[cond-bp].)  In
particular, by calling Lisp code only for troff2page, the
user has the
means to extend troff2page to deal with things that the core
program as supplied does
not.

Note that when troff2page sees
\fC.eval\fP-enclosed Lisp
code, it runs it in a Lisp environment that has not only the basic
Common Lisp language but also includes the procedures and data structures
defined in troff2page.  These extras are not available (and are arguably
not useful) to the \fC.eval\fP code seen by troff.

.SS Defining color names using HSL
.IX color names, defining
For a more substantial example of \fC.eval\fP's use, consider defining
color names using the HSL (hue/saturation/lightness) scheme rather than the
RGB and CMYK schemes provided by groff.  For instance, we would like to
define the color Venetian red using its HSL spec (357\(de, 49%,
24%), which to many is a more intuitive description than RGB
(91, 31, 34).

While there is an \*[url \
http://en.wikipedia.org/wiki/HSL_color_space \
algorithm] to convert HSL to RGB,
implementing it using groff's limited arithmetic is tedious.  Instead,
we'll define a
much easier Lisp procedure to do the same, and put it inside an \fC.eval\fP:

.EX
    .mso eval4troff.tmac
    .
    .eval
    (defun between-0-and-1 (n)
      (cond ((< n 0) (+ n 1))
            ((> n 1) (- n 1))
            (t n)))
    
    (defun tc-to-c (tc p q)
      (cond ((< tc 1/6)
             (+ p (* (- q p) 6 tc)))
            ((and (<= 1/6 tc) (< tc 1/2))
             q)
            ((and (<= 1/2 tc) (< tc 2/3))
             (+ p (* (- q p) 6 (- 2/3 tc))))
            (t p)))
    
    (defun hsl-to-rgb (h s l)
      (setq h (/ (mod h 360) 360))
      (let* ((q (cond ((< l 1/2) (* l (+ 1 s)))
                      (t (+ l s (* -1 l s)))))
             (p (- (* 2 l) q))
             (tr (between-0-and-1 (+ h 1/3)))
             (tg (between-0-and-1 h))
             (tb (between-0-and-1 (- h 1/3))))
        (values (tc-to-c tr p q)
                (tc-to-c tg p q)
                (tc-to-c tb p q))))
    
    (defun def-hsl-color (name h s l)
      (multiple-value-bind (r g b) (hsl-to-rgb h s l)
        (format t ".defcolor ~a rgb ~a ~a ~a~%" name r g b)))
    .endeval
.EE

Here, the Lisp procedure \fCdef-hsl-color\fP takes an HSL spec and
writes out the equivalent RGB groff definition. (The troff2page
distribution provides \fCdef-hsl-color\fP in the macro file
\fCdefhsl.tmac\fP.)

We can call this Lisp procedure inside another \fC.eval\fP to define
\fCvenetianred\fP using its HSL spec:

.EX
    .eval
    (def-hsl-color "venetianred" 357 .49 .24)
    .endeval
.EE

.eval
    (def-hsl-color "venetianred" 357 .49 .24)
.endeval
The color name \fCvenetianred\fP can now be used like any other groff color name:

.EX
    Prismacolor's burnt ochre pencil is a close match for Derwent's
    \fB\m[venetianred]Venetian red\m[]\fP, and either can be used to
    emulate the sanguine chalk drawings of the Old Masters.
.EE

which produces:

.sp 1v
.B1
.RS
Prismacolor's burnt ochre pencil is a close match for Derwent's
\fB\m[venetianred]Venetian red\m[]\fP, and either can be used to
emulate the sanguine chalk drawings of the Old Masters.
.RE
.B2

.SS Extending troff2page only
.IX extending troff2page with Common Lisp without producing output
.IX ig@.ig ##, as troff2page extender
troff2page treats troff's \fC.ig\fP
environment, whenever it uses \fC##\fP as ender, as
containing Lisp code that can be used to extend
troff2page.  This syntactic overloading of \fC.ig ##\fP is an innovation introduced by
Oliver Laumann's \*[url \
http://www-rn.informatik.uni-bremen.de/software/unroff \
unroff].

Any Lisp code enclosed within
\&\fC.ig ##\fP ... \fC.##\fP will be processed by
troff2page but not by
troff, which treats it as a multiline comment of course.
Note that \fC.ig ##\fP does not pipe its stdout back into
the document, as \fC.eval\fP does.  This is to maintain the invariant
that as far as output is
concerned, \fC.ig ##\fP, like other \fC.ig\fPs, is \fIalways\fP a
comment.  However, you can add Lisp code within \fC.ig ##\fP
to influence how troff2page \*- but not troff! \*- processes the rest of the
document.

For example, let's define a
\fC\e*[url]\fP string register that simply typesets its URL
argument within angle brackets.

.EX
    .ds url \(la\fC\\$1\fP\(ra
.EE

This is adequate for the print output.
For troff2page though, we'd like to
re-define this macro, in Lisp, to create a hyperlink.
We enclose this re-definition in a \fC.ig ##\fP, which not
only allows it to be in Lisp, but also makes it apply only
when troff2page reads it:

.EX
    .ig ##
    (defstring "url"
      (lambda (url)
        (concatenate 'string
          (link-start url)
          url
          (link-stop))))
    .##
.EE

The procedures \fCdefstring\fP, \fClink-start\fP, and
\fClink-stop\fP are defined in the troff2page code.

.IX stylesheet, modifying
\fC.ig ##\fP can be used to specify settings that are relevant only
when troff2page is used on a document, e.g., stylesheet changes.
troff2page uses the output-port \fC*css-port*\fP to
write out style information.  The user can also write to this port, e.g.,

.EX
    .ig ##
    (format *css-port* "
        h1,h2,h3,h4,h5,h6 {
            color: rgb(61,35,39); /* chocolate */
        }
        ")
    .##
.EE

.ig ##
    (format *css-port* "
        h1,h2,h3,h4,h5,h6 {
            color: rgb(61,35,39); /* chocolate */
        }
        ")
.##
This sets the HTML headers
with a foreground color
of chocolate.\**
.FS
The RGB values used in this manual for
the colors chocolate,
terracotta pink,
and Venetian red are all courtesy \*[url \
http://www.resene.co.nz/swatches "Resene Paints"].
.FE

.SH 8. Recovery from errors
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

In the second line, troff2page offers to fire up a text editor with the cursor
approximately close to the
offending line.

.IX errors, editing location of
If you type \fCe\fP at the \fC?\fP prompt, troff2page starts the editor specified in your
\fCEDITOR\fP environment variable, or if that is not set, the editor named
\fCvi\fP on your system.  troff2page calls the editor with two arguments:
the first argument is \fC+\fP followed by the line number, and the second
argument is the filename.
(This argument style works for \fIall\fP
vi and emacs clones and I suspect most modern editors take care
to recognize it, so it isn't as restrictive as it sounds.)

.SS SBCL's warnings
.IX SBCL, disabling warnings in
When running troff2page on SBCL, you can get several
screenfuls of diagnostic warnings.  The conditions warned
about are benign, but the verbosity of the messages
can be daunting.  If you'd rather they weren't there, add
the lines

.EX
    #+sbcl
    (declaim (sb-ext::muffle-conditions style-warning))
.EE

either toward the beginning of the \fCtroff2page\fP script; or
to your SBCL user-init file, which is the file \fC.sbclrc\fP
in your home directory.  If adding to \fC.sbclrc\fP, the
feature expression \fC#+sbcl\fP may be omitted.

.if t \{\
.SH Index
.\"rs
.\"if \n(.H .sp .8v
.2C
.\"sp -1v
.so \*[AUXF].ind
.\"1C
.\}
