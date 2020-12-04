.\" last modified 2020-12-04
.SH 1
3. Page layout
.LP
.IX page breaks
.IX bp@.bp, troff request
The page-break command \fC.bp\fP ends the current HTML page and start a new
one.  \fC.bp\fP causes a page-break in both the HTML and the print outputs.
.PP
.TAG cond-bp
.IX conditional for troff2page versus troff
.IX troff2page@.troff2page, number register
.IX if@.if, troff request
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
.PP
As can be seen, the number register \fC\en[.troff2page]\fP has a \fItrue\fP
value, i.e., a number greater than zero, only when troff2page processes the
document.\**
.
.FS
The greater-than-zero number held in the register
\fC\en[.troff2page]\fP
is in fact the version
number of the troff2page program processing the document.  This is a number
such as 20150320, which would be the version number of the troff2page
released on 2015 March 20.  \fC\en[.troff2page]\fP could plausibly be used
to distinguish not just troff2page from troff, but also between various versions
of troff2page.  Thus, one could, if the need were dire, write a document
that translates differently with different versions of troff2page.
.PP
.IX p@.p, number register
If you’d prefer to stick to known groff registers, the read-only
paper-length register \fC\en[.p]\fP is a possibility. groff sets
it to 11 inches, i.e., the length of a US Letter size paper.
Presumably it could vary depending on country of use, but it is
never 0. troff2page, since it doesn't deal in paper, sets
\fC\en[.p]\fP to 0.
.PP
.IX x@.x, number register
.IX y@.y, number register
groff has its own version registers \fC\en[.x]\fP
and \fC\en[.y]\fP, for the major and minor version numbers
respectively. troff2page sets these too, splitting the value of
\fC\en[.troff2page]\fP between month and day. Thus the troff2page
released on 2020 December 2 sets \fC\en[.troff2page]\fP to 20201202,
\fC\en[.x]\fP to 202012, and
\fC\en[.y]\fP to 2. These are all numbers (not strings), so
there’s no 0-left-padding.
.FE
.PP
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
.PP
.IX navigation bar
Each page in a multiple-page HTML output has a navigation bar at its
head and foot.  The bar contains links to the first, previous, and next
page, and the table-of-contents and index pages.  If any of these pages
doesn’t exist, or if it is the same as the page containing the
navigation bar, then the link for it is disabled.
.PP
.SH 2
HTML-style paragraphs
.LP
By default, troff2page sets paragraphs exactly as groff does: the first
lines of paragraphs are indented (unless explicitly disabled via an
\fC.LP\fP), and
the vertical distance between adjacent paragraphs is the same smallish
amount that groff employs.  These two values are given by the number
registers \fCPI\fP and \fCPD\fP, which (for the -ms format) are 0.3n and 0.3v
respectively.\**
.FS
The length unit \fCn\fP (en) is half the width of the letter ‘\fCm\fP’ in
the current font. \fCv\fP is the distance between two consecutive
baselines. Other groff length units that troff2page recognizes
are: \fCi\fP (inch = 1/12 foot), \fCc\fP (cm =
50/127 inch), \fCp\fP (point = 1/72 inch), \fCP\fP (pica = 12
points), \fCm\fP (em = 2 ens), and \fCM\fP (1/100 em).
.FE
.PP
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
Unlike groff -ms, which uses the line length given by the register
\fCLL\fP,
troff2page by default does not restrict the text width on its HTML pages.
Text will narrow or widen to fit the current browser window width.  However, if
you explicitly set \fCLL\fP (instead of relying on -ms’s default), troff2page
will respect that line length, regardless of how wide your
browser gets.\**
.FS
If you prefer troff2page’s default fit-to-width text-width, but
one of the macro files you loaded sets \fCLL\fP, simply reset
\fCLL\fP to 0 inside an \fC.if \En[.troff2page]\fP conditional.
Use the same ploy to set your HTML \fCLL\fP to whatever you want,
without affecting the print output.
.FE
.PP
It is always OK to have the browser window less
wide than \fCLL\fP (as is certainly unavoidable on cell
phones): the text will correspondingly shrink to
fit the window, avoiding the need for horizontal scrolling.
.PP
A good \fCLL\fP value for troff2page should be a bit larger than
-ms’s 6 inches, which is too narrow for a browser.  The following sets it
to 1 millifurlong, but it takes effect only for HTML:
.EX
    .if \n[.troff2page] .nr LL 7.92i
.EE
