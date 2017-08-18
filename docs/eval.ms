.SH 1
7. Extending troff using Lua

.IX extending troff and troff2page with Lua
.IX eval@.eval, macro
.IX endeval@.endeval, macro
.IX pca-eval.tmac, macro file
To invoke Lua from troff, we use the macro \fC.eval\fP with its closer
\fC.endeval\fP.   These are
defined in the
supplied
troff macro file \fCpca-eval.tmac\fP, which you should put
in a macro directory.

\&\fC.eval\fP does only one thing: It
allows you to place arbitrary Lua code until the following
\fC.endeval\fP, and the text written to standard output by
this Lua code
is substituted for the \fC.eval\fP ... \fC.endeval\fP.
The usefulness of this tactic will be apparent from an
example.
Consider the following troff document, \fCtau.ms\fP:

.EX
    .mso pca-eval.tmac
    .
    The ratio of the circumference of a circle to
    its radius is \(*t \(~=
    .eval
    -- following prints tau, because cos(tau/2) = -1
    io.write(2*math.acos(-1), '.\n')
    .endeval
.EE

.IX unsafe mode
.IX z@-z, groff option
.IX U@-U, groff option
Run troff (actually groff, and in unsafe mode too) on \fCtau.ms\fP:

.EX
    groff -z -U -ms tau.ms
.EE

(The \fC-z\fP avoids generating output, because we are not ready for it
yet.  The \fC-U\fP runs in “unsafe” mode, i.e., it allows the writing of
aux files.)
You will find that the groff asks you to run it again:

.EX
.ec
    \f(CIRerun groff with -U
.EE

Call groff again as follows:

.EX
    groff -U -ms tau.ms > tau.ps
.EE

\fCtau.ps\fP will now look like:

.B1
.RS
The ratio of the circumference of a circle to
its radius is \(*t \(~=
.eval
-- following prints tau, because cos(tau/2) = -1
io.write(2*math.acos(-1), '.\n')
.endeval
.RE
.B2

The first groff call produces a Lua file
\fC.trofftemp.lua\fP.\**
.FS
This name may be different based on
your setting of \fC\e*[AUXF]\fP — see page \*[TAG:auxf].
.FE
The second groff
call invokes Lua to create an auxiliary file for each \fC.eval\fP that gets sourced
back into the document.

It is clear that Lua code via \fC.eval\fP can
serve as a very powerful \fIsecond extension language\fP
for troff.  This benefit is available even when the document
is processed by troff2page:
We could run troff2page on the same document, \fCtau.ms\fP, and the
resulting \fCtau.html\fP will show the same content.

.IX extending troff and troff2page differently with Lua
Furthermore, we can embed  \fC.eval\fP-enclosed Lua code inside an
\fC.if\fP (or \fC.ie\fP or \fC.el\fP) statement so that it gets executed
only for troff or only for troff2page.  (Recall we used the number register
\fC\en[.troff2page]\fP for this purpose on page \*[TAG:cond-bp].)  In
particular, by calling Lua code only for troff2page, the
user has the
means to extend troff2page to deal with things that the core
program as supplied does
not.

Note that when troff2page sees
\fC.eval\fP-enclosed Lua
code, it runs it in a Lua environment that has not only the basic
Lua language but also includes the procedures and data structures
defined in troff2page.  These extras are not available (and are arguably
not useful) to the \fC.eval\fP code seen by troff.

.SH 2
Defining color names using HSL

.IX color names, defining
For a more substantial example of \fC.eval\fP’s use, consider defining
color names using the HSL (hue/saturation/lightness) scheme rather than the
RGB and CMYK schemes provided by groff.  For instance, we would like to
define the color Venetian red using its HSL spec (357\(de, 49%,
24%), which to many is a more intuitive description than RGB
(91, 31, 34).

While there is an \*[url \
http://en.wikipedia.org/wiki/HSL_color_space]algorithm\& to convert HSL to RGB,
implementing it using groff’s limited arithmetic is tedious.  Instead,
we’ll define a
much easier Lua procedure to do the same, and put it inside an \fC.eval\fP:

.EX
    .mso pca-eval.tmac
    .
    .eval
    do
      local function between_0_and_1(n)
        if n < 0 then
          return n + 1
        elseif n > 1 then
          return n - 1
        else
          return n
        end
      end

      local function tc_to_c(tc, p, q)
        if tc < 1/6 then
          return p + (q - p)*6*tc
        elseif 1/6 <= tc and tc < 1/2 then
          return q
        elseif 1/2 <= tc and tc < 2/3 then
          return p + (q - p)*6*(2/3 - tc)
        else
          return p
        end
      end

      local function hsl_to_rgb(h, s, l)
        h = (h % 360) / 360
        local q
        if l < 1/2 then
          q = l * (s + 1)
        else
          q = 1 + s - l*s
        end
        local p = 2*l - q
        local tr = between_0_and_1(h + 1/3)
        local tg = between_0_and_1(h)
        local tb = between_0_and_1(h - 1/3)
        return tc_to_c(tr, p, q),
          tc_to_c(tg, p, q),
          tc_to_c(tb, p, q)
      end

      function def_hsl_color(name, h, s, l)
        local r, g, b = hsl_to_rgb(h, s, l)
        io.write(string.format('.defcolor %s rgb %s %s %s\n', name, r, g, b))
      end
    end
    .endeval
.EE

Here, the Lua procedure \fCdef-hsl-color\fP takes an HSL spec and
writes out the equivalent RGB groff definition. (The troff2page
distribution provides \fCdef-hsl-color\fP in the macro file
\fCdefhsl.tmac\fP.)

We can call this Lua procedure inside another \fC.eval\fP to define
\fCvenetianred\fP using its HSL spec:

.EX
    .eval
    def_hsl_color('venetianred', 357, .49, .24)
    .endeval
.EE

.eval
    def_hsl_color('venetianred', 357, .49, .24)
.endeval
The color name \fCvenetianred\fP can now be used like any other groff color name:

.EX
.ec
    Prismacolor’s burnt ochre pencil is a close match for Derwent’s
    \\fB\\m[venetianred]Venetian red\\m[]\\fP, and either can be used to
    emulate the sanguine chalk drawings of the Old Masters.
.EE

This produces:

.B1
.RS
Prismacolor’s burnt ochre pencil is a close match for Derwent’s
\fB\m[venetianred]Venetian red\m[]\fP, and either can be used to
emulate the sanguine chalk drawings of the Old Masters.
.RE
.B2

.SH 2
Extending troff2page only

.IX extending troff2page with Lua without producing output
.IX ig@.ig ##, as troff2page extender
troff2page treats troff’s \fC.ig\fP
environment, whenever it uses \fC##\fP as ender, as
containing Lua code that can be used to extend
troff2page.  This syntactic overloading of \fC.ig ##\fP is an innovation introduced by
Oliver Laumann’s \*[url \
http://www-rn.informatik.uni-bremen.de/software/unroff]unroff\&.

Any Lua code enclosed within
\&\fC.ig ##\fP ... \fC.##\fP will be processed by
troff2page but not by
troff, which treats it as a multiline comment of course.
Note that \fC.ig ##\fP does not pipe its stdout back into
the document, as \fC.eval\fP does.  This is to maintain the invariant
that as far as output is
concerned, \fC.ig ##\fP, like other \fC.ig\fPs, is \fIalways\fP a
comment.  However, you can add Lua code within \fC.ig ##\fP
to influence how troff2page — but not troff! — processes the rest of the
document.

For example, let’s define a
\fC\e*[url ...]\fP string register that simply typesets its URL
argument within angle brackets.

.EX
    .ds url \(la\fC\\$1\fP\(ra
.EE

This is adequate for the print output.
For troff2page though, we’d like to
re-define this macro, in Lua, to create a hyperlink.
We enclose this re-definition in a \fC.ig ##\fP, which not
only allows it to be in Lua, but also makes it apply only
when troff2page reads it:

.EX
    .ig ##
    defstring('url', function(url)
      return link_start(url) .. url .. link_stop()
    end)
    .##
.EE

The procedures \fCdefstring\fP, \fClink_start\fP, and
\fClink_stop\fP are defined in the troff2page code.

.IX stylesheet, modifying
\fC.ig ##\fP can be used to specify settings that are relevant only
when troff2page is used on a document, e.g., stylesheet changes.
troff2page uses the output-stream \fCCss_stream\fP to
write out style information.  The user can also write to this stream, e.g.,

.EX
    .ig ##
    Css_stream:write([[
        h1,h2,h3,h4,h5,h6 {
            color: rgb(61,35,39); /* chocolate */
        }
    ]])
    .##
.EE

.ig ##
    Css_stream:write([[
        h1,h2,h3,h4,h5,h6 {
            color: rgb(61,35,39); /* chocolate */
        }
    ]])
.##
This sets the HTML headers
with a foreground color
of chocolate.\**
.FS
The RGB values used in this manual for
the colors chocolate,
terracotta pink,
and Venetian red are all courtesy \*[url \
http://www.resene.co.nz/swatches]Resene Paints\&.
.FE
