.\" last modified 2020-12-05
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
simply uses the date that it was called. 
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
