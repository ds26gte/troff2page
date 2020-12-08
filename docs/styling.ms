.\" last modified 2020-12-08
.SH 1
8. Styling
.LP
.IX stylesheet, modifying
\fC.ig ##\fP can be used to specify settings that are relevant only
when troff2page is used on a document, e.g., stylesheet changes.
troff2page uses the output-stream \fCCss_stream\fP to
write out its default style information.  The user can also
append to this stream. E.g.,
.EX
    .ig ##
    Css_stream:write([[
        h1,h2,h3,h4,h5,h6 {
            color: #9b3d3d; /* terracotta pink */
            font-family: sans-serif;
            font-weight: normal;
            margin-top: 1em;
            margin-bottom: 0.5em;
        }
    ]])
    .##
.EE
This sets the HTML headers
with a foreground color
of \m[terracottapink]terracotta pink\m[]\**,
along with some other changes from the default.
.FS
The RGB values used in this manual for
the colors
terracotta pink
and Venetian red are courtesy \*[url \
https://www.resene.co.nz/swatches]Resene Paints\&.
.FE
.PP
.IX title@.title, CSS class
troff2page makes available many CSS classes that you can modify
in this manner to change the look of your web pages. For
instance, the HTML element for the document title has class
\fCtitle\fP. Here’s a way to get a more happening,
Asciidoctor-like title:
.EX
    .ig ##
    Css_stream:write([[
      h1.title {
          color: #333333;
          padding-bottom: 10px;
          border-bottom: 1px solid #dddddf;
      }
    ]])
    .##
.EE
Of course, these CSS mods don’t affect the groff output, but they
do affect the printed output if you choose
to print from the browser! To prevent any CSS mods
from leaking into the browser-mediated printout, wrap them inside
\fC@media screen {...}\fP.
.PP
.SH 2
Colophon
.LP
.IX colophon
.IX last-modification time
By default, troff2page places a colophon at the bottom right of the first
page. The colophon mentions (i) the last-modification
time of the
the document and (ii) the troff2page version used for the conversion.
Either or both can be suppressed via CSS.
.PP
.IX colophon@.colophon, CSS class
.IX advertisement@.advertisement, CSS class
To suppress the mention of troff2page,
.PP
.EX
    .colophon .advertisement {
      display: none;
    }
.EE
.PP
To suppress the entire colophon,
.PP
.EX
    .colophon {
      display: none;
    }
.EE
.PP
troff2page calculates the last-mod time by choosing the timestamp
of the newest of the source documents that make up the document.
Only user content is considered; macro and auxiliary files are
not.
.PP
.IX ND@.ND, macro
.IX DA@.DA, macro
To specify a document timestamp without regard to the actual mod times
of the files in it, use the -ms macros \fC.ND\fP or \fC.DA\fP.
troff2page doesn’t distinguish between them, but groff does.
\fC.ND\fP is probably what you want for both typesetters. (groff
doesn’t really have any notion of the last-mod date anyway: It
simply uses the date that it was called on.
I.e., last-creation-of-printed-output date.)
.PP
For web pages, note that if
either macro is called with an argument, that argument is used as the
last-mod date, overriding the value that troff2page would
have determined.
.PP
.IX lastmod@.lastmod, CSS class
If no argument is given, the colophon doesn’t
include the “Last modified” line at all, something that can also be
accomplished via the CSS fragment:
.EX
    .colophon .lastmod {
      display: none;
    }
.EE
.PP
.SH 2
Glyph substition
.LP
CSS isn't the only recourse to style your document: Interesting
glyphs offer another approach.  troff2page, like groff, allows
you to use UTF-8 characters, either directly or via escape
sequences of the form \fC\e[u\fIxxxx\fP]\fP, where \fIxxxx\fP is
the corresponding hex number (in uppercase).
.PP
.IX char@.char, groff request
.IX U+2621, CAUTION SIGN
.IX U+26A0, WARNING SIGN
E.g., U+2621 (CAUTION SIGN)
.if \n[.troff2page] (☡)
and
U+26A0 (WARNING SIGN)
.if \n[.troff2page] (⚠)
— in a suitable color and size — may be used rather than
the pedestrian “\fBCAUTION\fP” and “\fBWARNING\fP” for admonition titles. Unfortunately,
while these usually work well on browsers, the fonts
used by groff for printing almost always won't recognize them.
(You could use fallback fonts, but often they test groff's
capacity, and it's not worth loading them only for a couple of
exotic glyphs.) A more reasonable workaround is to use
the \fC.char\fP request to conditionally translate special characters into their
boring equivalents for print:
.PP
.EX
  .if !\n[.troff2page] \{\
  .  char \[u2621] \fBCAUTION\fP
  .  char \[u26A0] \fBWARNING\fP
  .\}
.EE
.PP
The display used above brings up another use-case for glyph
translation, even when (and especially if) no exotic characters
are desired. The display shows the \fC\e\fP character, which
is an escape character for groff. In a display, we want to
suppress its effect. We could do this by having our display
macros
implicitly turn the control character off when entering the display and back on when
exiting it. The requests for these actions are \fC.eo\fP and
\fC.ec\fP respectively.
.PP
This works for short displays that are entirely within a page
(we're talking printed pages via groff now, not HTML pages). The
various traps that spring into action when groff breaks at a page
rely on the control character being active, and these will start
failing catastrophicaly when our display straddles a page
boundary.
.PP
.IX KS@.KS, macro
.IX KF@.KF, macro
.IX DS@.DS, macro
.IX LD@.LD, macro
One way out is to
\fIforce\fP code displays to never cross a page boundary by
using groff's “keep” macros \fC.KS\fP or \fC.KF\fP or the keep
versions of the display macros (e.g., \fC.DS L\fP rather than
\fC.LD\fP). Please see the groff docs for more info about these
macros. The problem then becomes what to do with large
page-crossing displays. This is almost unavoidable in computer
technical prose.
.PP
.IX U+29F9, BIG REVERSE SOLIDUS
.IX U+FE68, SMALL REVERSE SOLIDUS
.IX U+005C, REVERSE SOLIDUS
Unicode glyph substitution offers another way out. The Unicode
characters U+29F9 (BIG REVERSE SOLIDUS) and U+FE68 (SMALL REVERSE
SOLIDUS) are passable replacements for the regular backslash (aka
REVERSE SOLIDUS, U+005C). You can enter these substitute
backslashes with text-editor macros fairly easily. So now your
displayed code now has something that looks like a backslash,
at least on
browsers, but it most probably fails for print. Even in the browser,
close is no cigar: Somebody cutting and pasting your code is in
for a nasty surprise. You really do want the \fIreal\fP backslash in
there even in the HTML page, but you don't want to disable groff's control character.
Glyph substitution to the rescue:
.PP
.EX i
  .char \e[u29F9] \e[u005C]
.EE
.PP
This lets you type the exotic backslash in your source but have
groff and troff2page convert it into the regular backslash when
the it lands on the page.
Even better, there is no requirement that the font used actually
have the exotic backslash glyph at that Unicode position! 
You still have to type the exotic backslash but a competent text
editors (with a Unicode font!) can help you do this.
