.\" last modified 2021-02-10
.SH 1
3.  Page layout
.LP
.IX navigation bar
Each page in a multiple-page HTML output has a navigation bar at its
head and foot.  The bar contains links to the first, previous, and next
page, and the table-of-contents and index pages.  If any of the
first three pages
doesn’t exist, or if it is the same as the page containing the
navigation bar, the link for it is disabled (grayed). If the ToC or
index page doesn’t exist, it is absent from the bar.
.PP
.SH 2
Page breaks
.LP
.IX page breaks
.IX bp@.bp, groff request
Multiple pages are created because the document source implicitly or
explicilty used
the page-break command \fC.bp\fP.  Each call to \fC.bp\fP ends the current HTML page and start a new
one.  Thus \fC.bp\fP causes a page-break in both the HTML and the print outputs.
.PP
.TAG cond-bp
.IX conditional for Troff2page versus groff
.IX troff2page@.troff2page, Troff2page number register
.IX if@.if, groff request
Generally, page-breaks require a different \(aesthetic in HTML than in
print.  You can use groff conditionals to express this difference:
.EX 1
    .if \n[.troff2page] .bp
.EE
causes a page-break only in the HTML, whereas
.EX 1
    .if !\n[.troff2page] .bp
.EE
causes a page-break only in print.
.PP
As can be seen, the number register \fC\en[.troff2page]\fP has a \fItrue\fP
value, i.e., a number greater than zero, only when Troff2page processes the
document.
.PP
.IX page breaks!for HTML only
If may be convenient to define a \fC.HBP\fP macro that causes a page-break
only for HTML:
.EX 1
    .de HBP
    .if \n[.troff2page] .bp
    ..
.EE
Note that Troff2page, like groff, does not automatically cause a page break
at the sectioning commands.  Use \fC.bp\fP or a macro like \fC.HBP\fP to
explicitly to insert breaks as needed, or define your own
sectioning commands
or modify the existing ones
to embed a page break.
.PP
.IX SH@."@SH, -ms macro
.IX SH@.SH, -ms macro
.IX rn@.rn, groff request
.IX de@.de, groff request
.IX nr@.nr, groff request
.IX shift@.shift, groff request
.IX als@.als, groff request
Here’s a way to create pagebreaks in HTML before every top-level \fC.SH\fP, by
redefining the underlying \fC.@SH\fP macro:
.EX 1
    .if \n[.troff2page] \{\
    .
    .  rn @SH __@SH_orig
    .
    .  de @SH
    .    nr __@SH_first_arg \\$1
    .    shift
    .    if '\\n[__@SH_first_arg]'1' .bp
    .    __@SH_orig \\n[__@SH_first_arg] \\$*
    .  .
    .
    .  als SH @SH
    .
    .\}
.EE
.PP
.SH 2
Recognizing when Troff2page is running
.LP
We used the value stored in the number register
\fC\en[.troff2page]\fP to determine
which typesetter — Troff2page or groff — is operating on our
text.  A positive number is considered true. (Perhaps
contrary
to expectation, not just 0 but all negative numbers are false for
groff.)
Unset registers are assumed to contain 0.
.PP
In Troff2page,
the positive number held in this register
is in fact the version
number of the Troff2page program processing the document. This is a number
such as 20150320, which would be the version number of the Troff2page
released on 2015 March 20.  \fC\en[.troff2page]\fP could plausibly be used
to distinguish not just Troff2page from groff, but also between various versions
of Troff2page. Thus, one could, if the need were dire, write a document
that translates differently with different versions of
Troff2page. But don’t do this.
.PP
.IX p@.p, groff number register
If you’d rather stick to known groff registers, the read-only
paper-length register \fC\en(.p\fP is a candidate.  groff sets
it to 11 inches, i.e., the length of a US Letter size paper.
Presumably it could vary depending on country of use, but it is
never going to be non-positive. Troff2page, since it doesn’t deal in paper, sets
\fC\en(.p\fP to 0.
.PP
.IX x@.x, groff number register
.IX y@.y, groff number register
.IX Y@.Y, groff number register
groff has its own version registers \fC\en(.x\fP,
\fC\en(.y\fP, and \fC\en(.Y\fP, which contain the major and minor version numbers
and revision number
respectively. Troff2page sets these too, splitting the value of
\fC\en[.troff2page]\fP between year, month and day. Thus the Troff2page
released on 2020 December 2 sets \fC\en[.troff2page]\fP to 20201202,
\fC\en(.x\fP to 2020, and
\fC\en(.y\fP to 12, and \fC\en(.Y\fP to 2. (These are all numbers (not strings), so
there’s no 0-left-padding.)
.PP
.PP
.SH 2
HTML-style paragraphs
.LP
.IX n, groff scaling factor
.IX v, groff scaling factor
.IX PD, -ms number register
.IX PI, -ms number register
.IX LP@.LP, groff macro
By default, Troff2page sets paragraphs exactly as groff does: the first
lines of paragraphs are indented (unless explicitly disabled via an
\fC.LP\fP), and
the vertical distance between adjacent paragraphs is the same smallish
amount that groff employs.  These two values are given by the number
registers \fCPI\fP and \fCPD\fP, which (for the -ms format) are 0.3n and 0.3v
respectively.
.PP
If you wish to have the kind of block paragraphs customary in HTML, it
is not enough to set \fCPI\fP to 0, for the prevailing value of \fCPD\fP is too
small to comfortably tell adjacent paragraphs apart.  You could set \fCPD\fP
to a larger value, but as a convenience, Troff2page allows you to set \fCPD\fP
to a \fInegative\fP value, which leads to whatever default paragraph
separation that HTML uses.  Note that setting \fCPD\fP to a negative value
should be done only for HTML, as groff will happily overstrike
text in order to respect a negative \fCPD\fP:
.IX p, groff scaling factor
.EX 1
    .if \n[.troff2page] \{\
    .  nr PI 0n
    .  nr PD 0-1p
    .\}
.EE
.PP
.SH 2
Scaling factors
.LP
.IX scaling factor
The scaling factor \fCn\fP (en)
used above is half the width of the letter ‘\fCm\fP’ in
the default font size. \fCv\fP is the distance between two consecutive
baselines.  Scaling factors are generally, but not always, what
you might think of as length units.
.PP
.IX Fu\(ss, length unit
.IX centim\(`etre, length unit
.IX em, length unit
.IX en, length unit
.IX inch, length unit
.IX pica, length unit
.IX point, length unit
.IX M, groff scaling factor
.IX P, groff scaling factor (pica)
.IX c, groff scaling factor (centim\(`etre)
.IX i, groff scaling factor (inch)
.IX m, groff scaling factor
.IX p, groff scaling factor (point)
Other groff scaling factors that Troff2page recognizes
are: \fCi\fP (inch = 1/12 ft), \fCc\fP (cm =
50/127 in., \fCp\fP (point = 1/72 in., \fCP\fP (pica = 12
pt), \fCm\fP (em = 2 ens), and \fCM\fP (1/100 em).
.PP
.IMG inch.jpg 3.5i
.PP
.IX millipoint, length unit
.IX mile, length unit
.IX light year, length unit
.IX u, groff scaling factor
.IX f, groff scaling factor
Internally, both groff and Troff2page store lengths in the scaling
factor \fCu\fP, which
is 1/1000 of a point, i.e., 1 millipoint (mpt). groff keeps all
its lengths as integral multiples of
millipoints, thereby avoiding floating-point arithmetic.
Troff2page uses Lua’s FP, so fractions of a millipoint are allowed.
.PP
The largest
length expressible in groff is 2\*{31\*} \- 1 mpt, which is a shade
over 0.47 miles. Troff2page is a bit more generous, allowing
lengths of up to
6.7 \(mu 10\*{285\*} light years.
.PP
The scaling factor \fCf\fP is simply 2\*{16\*}, so its
coefficients can be used as fractions in a purely integer world.
I.e., groff will let you write the coefficients as decimal rationals,
but the product with \fCf\fP is always reduced to integer.
Troff2page uses Lua’s FP, so its fractions can be finer grained.
.PP
.SH 2
Line length
.LP
.IX LL@.LL, -ms number register
Unlike groff -ms, which uses the line length given by the register
\fCLL\fP,
Troff2page by default does not restrict the text width on its HTML pages.
Text will narrow or widen to fit the current browser window width.  However, if
you explicitly set \fCLL\fP (instead of relying on -ms’s default), Troff2page
will respect that line length as an upper bound, regardless of how wide your
browser gets.
.PP
If you prefer Troff2page’s default fit-to-width text-width, but
one of the macro files you loaded sets \fCLL\fP, simply reset
\fCLL\fP to 0 inside an \fC.if \en[.troff2page]\fP conditional.
Use the same ploy to set your HTML \fCLL\fP to whatever max-width
you want,
without affecting the print output.
.PP
It is always OK to have the browser window less
wide than \fCLL\fP (as is certainly unavoidable on cell
phones): the text will correspondingly shrink to
fit the window, avoiding the need for horizontal scrolling.
.PP
A good \fCLL\fP value for Troff2page should be a bit larger than
-ms’s 6 inches, which is too narrow for a browser. The following sets it
to 1/8000 of a mile, but it takes effect only for HTML:
.EX 1
    .if \n[.troff2page] .nr LL 7.92i
.EE
.PP
.SH 2
Images
.LP
.IX images
.IX IMG@.IMG, groff macro
Troff2page supports a generalized version of the \fC.IMG\fP macro
from groff’s \fCwww.tmac\fP.  It accepts all the usual image file
formats.  An example call:
.EX
    .IMG t2p.png
.EE
This produces:
.IMG t2p.png
.PP
.IX images!alignment
An optional first argument of \fC-L\fP aligns the image to the
left; \fC-R\fP to the right; and \fC-C\fP, the default, centers
it.
.PP
.IX images!width
An optional final argument specifies the width of the image.  The
default is 1 inch.
E.g.,
.EX
    .IMG -L t2p.png 2.718281828i
.EE
produces a left-justified image that’s \fIe\fP inches wide:
.IMG -L t2p.png 2.718281828i
.LP
.IX convert, image program
.IX mkbitmap, image program
.IX potrace, image program
.IX Inkscape, image program
\fC.IMG\fP relies on external programs \fCconvert\fP (from
ImageMagick); \fCmkbitmap\fP and \fCpotrace\fP (both from the
Potrace package); and Inkscape. \fCmkbitmap\fP and
\fCpotrace\fP are needed for PNG images; Inkscape for SVG
images.
