.SH 1
3. Page layout

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
such as 20150320, which would be the version number of the troff2page
released on 2015 March 20.  \fC\en[.troff2page]\fP could plausibly be used
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
doesn’t exist, or if it is the same as the page containing the
navigation bar, then the link for it is disabled.

.SH 2
HTML-style paragraphs

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
you explicitly set \fCLL\fP (instead of relying on ms’s default), troff2page
will respect that line length.  Nevertheless, if the user shrinks the
browser window to a width less than \fCLL\fP, the text will correspondingly
shrink too to fit the window.  This is to avoid the need for horizontal
scrolling.

A good \fCLL\fP value for troff2page should be a bit larger than
ms’s 6 inches, which is too narrow for a browser.  The following sets it
to 18 cm, making sure it takes effect only for HTML:

.EX
    .if \n[.troff2page] .nr LL 18c
.EE
