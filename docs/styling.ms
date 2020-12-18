.\" last modified 2020-12-19
.SH 1
8.  Styling
.LP
.IX stylesheet, modifying
.IX ig@.ig, groff request
\fC.ig ##\fP can be used to specify settings that are relevant only
when troff2page is used on a document, e.g., stylesheet changes.
troff2page uses the output-stream \fCCSS\fP to
write out its default style information.  The user can also
append to this stream.  E.g.,
.IX CSS, troff2page Lua output stream
.EX
    .ig ##
    CSS:write([[
        h1,h2,h3,h4,h5,h6 {
            color: #9b3d3d; /* terracotta pink */
        }
    ]])
    .##
.EE
This renders the section headers
with a foreground color
of \m[terracottapink]terracotta pink\m[]\**.
.FS
The color names and values for
terracotta pink
and Venetian red are courtesy \*[url \
https://www.resene.co.nz/swatches]Resene Paints\&.
.FE
.PP
.IX title@.title, CSS class
troff2page makes available many CSS classes that you can modify
in this manner to change the look of your web pages.  For
instance, the HTML element for the document title has class
\fCtitle\fP.  Here’s a way to get a more happening,
Asciidoctor-like title:
.EX
    .ig ##
    CSS:write([[
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
to print from the browser!  To prevent any CSS mods
from leaking into the browser-mediated printout, wrap them inside
\fC@media screen\fP.
.PP
.SH 2
Colophon
.LP
.IX colophon
.IX last-modification time
By default, troff2page places a colophon at the bottom right of the first
page.  The colophon mentions
.PP
i.  the last-modification
time of
the document, and
.PP
ii.  the troff2page version used for the conversion.
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
.IX ND@.ND, -ms macro
.IX DA@.DA, -ms macro
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
.IX TH@.TH, -man macro
As a special case, for man pages, troff2page (like groff -man)
takes the third argument of the titling macro \fC.TH\fP as the
last-mod date.  If there isn’t a third argument, the colophon
won’t mention any date.
.PP
.SH 2
Glyph substition
.LP
CSS isn’t the only recourse to style your document: Interesting
glyphs offer another approach.  troff2page, like groff, allows
you to use UTF-8 characters, either directly or via escape
sequences of the form \fC\e[u\fIxxxx\fP]\fP, where \fIxxxx\fP is
the corresponding hex number (in uppercase).
.PP
.IX char@.char, groff request
.IX U+2621 \s-2CAUTION SIGN\s0 (\[u2621])
.IX U+26A0 \s-2WARNING SIGN\s0 (\[u26A0])
E.g., U+2621 \s-2CAUTION SIGN\s0
and
U+26A0 \s-2WARNING SIGN\s0
— in a suitable color and size — may be used rather than
the pedestrian “\fBCAUTION\fP” and “\fBWARNING\fP” for admonition titles.
.if \n[.troff2page] \{\
.DS C
\M[yellow]\s+4\fB☡\fP\s0\M[]                 \M[red]\m[white]\s+4\fB⚠\fP\s0\m[]\M[]
.DE
.\}
Unfortunately,
while these usually work well on browsers, the fonts
used by groff for printing almost always won’t recognize them.
(You could use fallback fonts, but often they test groff’s
capacity, and it’s not worth loading them only for a couple of
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
.PP
.SH 2
Typing verbatim \\e in displays
.LP
.IX \\@\e, groff escape character
.IX eo@.eo, groff request
.IX ec@.ec, groff request
The display used above brings up another use-case for glyph
translation, even when (and especially if) no exotic characters
are desired.  The display shows the backslash (\fC\e\fP) character, which
is also the default escape character for groff.
.PP
We could use the
escape sequence \fC\ee\fP in our input to stand for a backslash,
but especially in an extended display containing verbatim code,
we would like to input the backslash as-is and have groff and
troff2page temporarily suspend its escape effect.
We could do this by having our display
macros
implicitly turn the escape character off when entering the display and back on when
exiting it.  The requests for these actions are \fC.eo\fP and
\fC.ec\fP respectively:
.IX LD@.LD, -ms macro
.IX DE@.DE, -ms macro
.IX ft@.ft, groff request
.IX EX@.EX, -ms macro
.IX EE@.EE, -ms macro
.PP
.EX
    .de EX
    .  LD
    .  ft C
    .  eo
    ..
    .
    .de EE
    .  ec
    .  DE
    ..
.EE
.PP
We then use the macros \fC.EX\fP and \fC.EE\fP around the code text to
display it, in monospace font and with the escape character
temporarily disabled. (An improved version of these macros are provided
in \fCpca-verb.tmac\fP.)
.PP
This works for short displays that are entirely within a page
(we’re talking printed pages via groff now, not HTML pages). The
various traps that spring into action when groff breaks at a page
rely on the escape character being active, and these will start
failing catastrophically when our display straddles a page
boundary.
.PP
.IX KS@.KS, -ms macro
.IX KF@.KF, -ms macro
.IX DS@.DS, -ms macro
One way out is to
\fIforce\fP code displays to never cross a page boundary by
using groff’s “keep” macros \fC.KS\fP or \fC.KF\fP or the keep
versions of the display macros (e.g., \fC.DS L\fP rather than
\fC.LD\fP). Please see the groff docs for more info about these
macros.  The problem then becomes what to do with large
page-crossing displays.  This is almost unavoidable in computer
technical prose.
.PP
.IX U+29F9 \s-2BIG REVERSE SOLIDUS\s0 (\[u29F9])
.IX U+FE68 \s-2SMALL REVERSE SOLIDUS\s0 (\[uFE68])
.IX U+005C \s-2REVERSE SOLIDUS\s0 (\[u005C])
.IX text editor
Unicode glyph substitution offers another way out.  The Unicode
characters U+29F9 \s-2BIG REVERSE SOLIDUS\s0 and U+FE68 \s-2SMALL REVERSE
SOLIDUS\s0 are passable replacements for the regular backslash
(U+005C \s-2REVERSE SOLIDUS\s0). You can enter these substitute
backslashes with text-editor macros fairly easily.\**
.FS
In the Vim editor, for instance, adding the command \fCexec 'dig
\e\e' 0x29F9\fP to your vimrc lets you use the digraph \fC\e\e\fP
to enter U+29F9.
.FE
.PP
So now your
displayed code has something that \fIlooks\fP like a backslash,
at least on
browsers, but it most probably fails for print, because the print
font lacks the exotic character.  Even in the browser,
close is no cigar: Somebody cutting and pasting your code is in
for a nasty surprise.  You really do want the \fIreal\fP backslash in
there even on the HTML page, but you don’t want to disable
groff’s escape character.
Glyph substitution to the rescue:
.PP
.EX e
    .char \e[u29F9] \e[u005C]
.EE
.PP
This lets you type the exotic backslash in your source but have
groff and troff2page convert it into the regular backslash when
it lands on the page.
Note there is no requirement that the font used by groff or the
browser actually
have the exotic backslash glyph at that Unicode position!
You still have to \fItype\fP the exotic backslash, so you do require a competent text
editor with a Unicode font.
.PP
.SH 2
\\e in a section heading
.LP
This and the previous section’s headers both have a verbatim backslash in the
header.  You could use glyph substitution here too.  However, if
you aren’t, \fIand\fP you’re using the \fC.ToC\fP macro, the fact that
the ToC macros use groff diversions creates a hitch.  You can use
the \fC\\e\fP escape to get a literal backslash, but the
diversion eats an escape, so you have to double it.  Ergo:
\fC\\\\e\fP.
