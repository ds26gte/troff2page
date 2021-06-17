.\" last modified 2021-06-17
.SH 1
9.  Styling
.LP
.IX stylesheet, modifying
.IX ig@.ig, groff request
\fC.ig ##\fP can be used to specify settings that are relevant only
when Troff2page is used on a document, e.g., stylesheet changes.
Troff2page uses the output-stream \fCCSS\fP to
write out its default style information.  The user can also
append to this stream.  E.g.,
.IX CSS, Troff2page Lua output stream
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
Troff2page makes available many CSS classes that you can modify
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
By default, Troff2page places a colophon at the bottom right of
the first page.  The colophon mentions: (1) the last-modification
time of the document; and (2) the Troff2page version used for the
conversion. Either or both can be suppressed via CSS.
.PP
.IX colophon@.colophon, CSS class
.IX advertisement@.advertisement, CSS class
To suppress the mention of Troff2page,
.EX
    .colophon .advertisement {
      display: none;
    }
.EE
To suppress the entire colophon,
.EX
    .colophon {
      display: none;
    }
.EE
Troff2page calculates the last-mod time by choosing the timestamp
of the newest of the source documents that make up the document.
Only user content is considered; macro and auxiliary files are
not.
.PP
.IX ND@.ND, -ms macro
.IX DA@.DA, -ms macro
To specify a document timestamp without regard to the actual mod times
of the files in it, use the -ms macros \fC.ND\fP or \fC.DA\fP.
Troff2page doesn’t distinguish between them, but groff does.
\fC.ND\fP is probably what you want for both typesetters. (groff
doesn’t really have any notion of the last-mod date anyway: It
simply uses the date that it was called on.
I.e., last-creation-of-printed-output date.)
.PP
For web pages, note that if
either macro is called with an argument, that argument is used as the
last-mod date, overriding the value that Troff2page would
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
.IX TH@.TH, -man macro
As a special case, for man pages, Troff2page (like groff -man)
takes the third argument of the titling macro \fC.TH\fP as the
last-mod date.  If there isn’t a third argument, the colophon
won’t mention any date.
.PP
.SH 2
Glyph substitution
.LP
CSS isn’t the only way to style your document: Interesting glyphs
offer another approach. Troff2page, like groff, allows you to use
UTF-8 characters, either directly or via escape sequences of the
form \fC\e[u\fIxxxx\fC_\fIyyyy\fC...]\fR, where the \fIxxxx\fP
and \fIyyyy\fP are hex numbers in uppercase. \fIxxxx\fP is the
code point of the base glyph, and each optional \fC_\fIyyyy\fR is
a code point for a combining diacritic.
.PP
.IX U+00E9 \s-2LATIN SMALL LETTER E WITH ACUTE\s0
.IX U+0065 \s-2LATIN SMALL LETTER E\s0
.IX U+0301 \s-2COMBINING ACUTE ACCENT\s0
Thus U+00E9 \s-2LATIN SMALL LETTER E WITH ACUTE\s0 (é) can be
entered (1) directly as \fCé\fP; (2) as the Unicode escape
\fC\e[u00E9]\fP; or (3) as the Unicode \fIcombining\fP escape
\fC\e[u0065_0301]\fP, because U+0065 is \s-2LATIN SMALL LETTER
E\s0 and U+0301 is \s-2COMBINING ACUTE ACCENT\s0.
.PP
.IX char@.char, groff request
.IX U+00B6 \s-2PILCROW SIGN\s0
.IX U+2761 \s-2CURVED STEM PARAGRAPH SIGN ORNAMENT\s0
The \fC.char\fP request is a convenient way to transliterate
a character available in your text editor to something available
in either your groff and/or browser font. E.g., the plain pilcrow
or paraph
character U+00B6 \s-2PILCROW SIGN\s0 (\[u00B6]) is commonly available while
text editing,
because it’s 8-bit ascii.  In contrast, the fancier
U+2761 \s-2CURVED STEM PARAGRAPH SIGN ORNAMENT\s0 (\[u2761]) may not be
present. To automatically transliterate the
former to the latter:
.EX 1
    .char \[u00B6] \[u2761]
.EE
Usually, this works on the browser (because UTF-8 encoding is widespread),
but fails for print, as the typical text font in
groff does not have a glyph at code point U+2761. groff does have
the glyph
in its Zapf Dingbats (\fCZD\fP) font but at a different code point, which
you can snag using a further \fC.char\fP
call:
.EX 1
    .if !\n[.troff2page] \{\
      .char \[u2761] \f(ZD\N'161'\fP
    .\}
.EE
.IX U+2621 \s-2CAUTION SIGN\s0
.IX U+26A0 \s-2WARNING SIGN\s0
Here’s a more elaborate use case: You may want to use U+2621 \s-2CAUTION SIGN\s0
and
U+26A0 \s-2WARNING SIGN\s0
rather than
the pedestrian “\fBCAUTION\fP” and “\fBWARNING\fP” for admonition
titles.
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
exotic glyphs.) A more reasonable workaround is to
conditionally translate special characters into their
boring equivalents for print:
.PP
.EX 1
    .if !\n[.troff2page] \{\
    .  char \[u2621] \fBCAUTION\fP
    .  char \[u26A0] \fBWARNING\fP
    .\}
.EE
If you used color and sizing to jazz up the icons, and you don’t
want these apply to the non-icon versions (or if you want to
modify the latter in a different way), trivial admonition macros
may be written that expand differently for HTML and print, e.g.,
.EX 1
    .de CAUTION
    .  if \n[.troff2page] \{\
    .    \M[yellow]\s+4\fB\[u2621]\fP\s0\M[]
    .  \}
    .  el \fBCAUTION\fP
    ..
.EE
.EX 1
    .de WARNING
    .  if \n[.troff2page] \{\
    .    \M[red]\m[white]\s+4\fB\[u26A0]\fP\s0\m[]\M[]
    .  \}
    .  el \fBWARNING\fP
    ..
.EE
.PP
.SH 2
Typing verbatim \\e in displays
.LP
.IX \\@\e, groff escape character
The display used above brings up another use-case for glyph
translation, even when (and especially if) no exotic characters
are desired.  The display shows the backslash (\fC\e\fP) character, which
is also the default escape character for groff.
.PP
A display environment could be fenced by a pair of macros
\fC.EX\fP/\fC.EE\fP defined as follows:
.IX EX@.EX, -ms macro
.IX EE@.EE, -ms macro
.IX LD@.LD, -ms macro
.IX DE@.DE, -ms macro
.IX ft@.ft, groff request
.EX
    .de EX
    .  LD
    .  ft C
    ..
    .
    .de EE
    .  DE
    ..
.EE
.IX e@\ee, groff escape (\e)
We could use the
escape sequence \fC\ee\fP in our input to stand for a backslash,
but especially in an extended display containing verbatim code,
we would like to input the backslash as-is and have groff and
Troff2page temporarily suspend its escape effect.
.IX eo@.eo, groff request
.IX ec@.ec, groff request
We could do this by having our \fC.EX\fP/\fC.EE\fP
macros
implicitly turn the escape character off when entering the display and back on when
exiting it.
The requests for these actions are \fC.eo\fP and
\fC.ec\fP respectively:
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
.IX U+29F9 \s-2BIG REVERSE SOLIDUS\s0
.IX U+FE68 \s-2SMALL REVERSE SOLIDUS\s0
.IX U+005C \s-2REVERSE SOLIDUS\s0
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
.EX 1
    .char \[u29F9] \[u005C]
.EE
This lets you type the exotic backslash in your source but have
groff and Troff2page convert it into the regular backslash when
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
