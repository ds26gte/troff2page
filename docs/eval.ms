.\" last modified 2021-06-17
.SH 1
8.  Extending groff using Lua
.LP
.IX extending groff with Lua
.IX extending groff and Troff2page with Lua
.IX eval@.eval, -mpca macro
.IX endeval@.endeval, -mpca macro
.IX pca-eval.tmac, macro file
To invoke Lua from groff, we use the macro \fC.eval\fP with its closer
\fC.endeval\fP.  These are
defined in the
supplied
groff macro file \fCpca-eval.tmac\fP, which you should put
in a macro directory.
.PP
\&\fC.eval\fP does only one thing: It
allows you to place arbitrary Lua code until the following
\fC.endeval\fP, and the text written to the stream \fCtroff\fP by
this Lua code
is substituted for the \fC.eval\fP ... \fC.endeval\fP.
The usefulness of this tactic will be apparent from an
example.
Consider the following groff document, \fCtau.ms\fP:
.IX mso@.mso, groff request
.IX troff, groff Lua output stream
.IX t@\e(*t, groff glyph name (\(*t)
.IX =@\e(~=, groff glyph name (\(~=)
.EX
    .mso pca-eval.tmac
    .
    The ratio of the circumference of a circle to
    its radius is \(*t \(~=
    .eval
    -- following prints tau, because cos(tau/2) = -1
    troff:write(2*math.acos(-1), '.\n')
    .endeval
.EE
.IX unsafe mode
.IX z@-z, groff command-line option
.IX U@-U, groff command-line option
Run groff in unsafe mode on \fCtau.ms\fP:
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
.PP
.B1
.RS
The ratio of the circumference of a circle to
its radius is \(*t \(~=
.eval
-- following prints tau, because cos(tau/2) = -1
troff:write(2*math.acos(-1), '.\n')
.endeval
.RE
.B2
.PP
The first groff call produces a temp Lua file.
The second groff
call invokes Lua on this temp file to create an auxiliary file
for each \fC.eval\fP, and each \fC.eval\fP sources its assigned
aux file
into the document.
.PP
.IX extending Troff2page with Lua
Lua code via \fC.eval\fP can
serve as a very powerful \fIsecond extension language\fP
for groff.  This benefit is available even when the document
is processed by Troff2page:
We could run Troff2page on the same document, \fCtau.ms\fP, and the
resulting \fCtau.html\fP will show the same content.
.PP
.IX extending Troff2page with Lua!differently from groff
.IX if@.if, groff request
.IX ie@.ie, groff request
.IX el@.el, groff request
Furthermore, we can embed  \fC.eval\fP-enclosed Lua code inside an
\fC.if\fP (or \fC.ie\fP or \fC.el\fP) statement so that it gets executed
only for groff or only for Troff2page. (Recall we used the number register
\fC\en[.troff2page]\fP for this purpose on page \*[TAG:cond-bp].)  In
particular, by calling Lua code only for Troff2page, the
user has the
means to extend Troff2page to deal with things that the core
program as supplied does
not.
.PP
Note that when Troff2page sees
\fC.eval\fP-enclosed Lua
code, it runs it in a Lua environment that has not only the basic
Lua language but also includes the procedures and data structures
defined in Troff2page. These extras are not available (and are arguably
not useful) to the \fC.eval\fP code seen by groff.
.PP
.SH 2
Defining color names using HSL
.LP
.IX color names, defining
.IX defcolor@.defcolor, groff request
For a more substantial example of \fC.eval\fP’s use, consider defining
color names using the HSL (Hue/Saturation/Lightness) scheme rather than the
RGB and CMYK schemes supported by groff’s \fC.defcolor\fP.  For instance, we would like to
define the color Venetian red using its HSL spec (357\(de, 49%,
24%), which to many is a more intuitive description than RGB
(91, 31, 34).
.PP
While there is an \*[url \
https://en.wikipedia.org/wiki/HSL_and_HSV]algorithm\& to convert HSL to RGB,
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
.sp
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
.sp
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
.sp
      function def_hsl_color(name, h, s, l)
        local r, g, b = hsl_to_rgb(h, s, l)
        troff:write(string.format('.defcolor %s rgb %s %s %s\n', name, r, g, b))
      end
    end
    .endeval
.EE
Here, the Lua procedure \fCdef_hsl_color\fP takes an HSL spec and
writes out the equivalent RGB groff definition. (The Troff2page
distribution provides \fCdef_hsl_color\fP in the macro file
\fCdefhsl.tmac\fP.)
.PP
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
.PP
.B1
.sp
.RS
Prismacolor’s burnt ochre pencil is a close match for Derwent’s
\fB\m[venetianred]Venetian red\m[]\fP, and either can be used to
emulate the sanguine chalk drawings of the Old Masters.
.RE
.sp
.B2
.PP
.SH 2
Extending Troff2page only
.LP
.IX extending Troff2page with Lua!without producing output
.IX ig@.ig ##, as Troff2page extender
Troff2page treats groff’s \fC.ig\fP
environment, whenever it uses \fC##\fP as ender, as
containing Lua code that can be used to extend
Troff2page. This syntactic overloading of \fC.ig ##\fP is an innovation introduced by
Oliver Laumann’s \*[url \
http://www-rn.informatik.uni-bremen.de/software/unroff]unroff\&.
.PP
Any Lua code enclosed within
\&\fC.ig ##\fP ... \fC.##\fP will be processed by
Troff2page but not by
groff, which treats it as a multiline comment of course.
Note that \fC.ig ##\fP does not pipe its stdout back into
the document, as \fC.eval\fP does.  This is to maintain the invariant
that as far as output is
concerned, \fC.ig ##\fP, like other \fC.ig\fPs, is \fIalways\fP a
comment.  However, you can add Lua code within \fC.ig ##\fP
to influence how Troff2page — but not groff! — processes the rest of the
document.
.PP
For example, let’s define a
\fC\e*[url ...]\fP string register that simply typesets its URL
argument within angle brackets.
.IX ds@.ds, groff request
.EX 1
    .ds url \(la\fC\\$1\fP\(ra
.EE
This is adequate for the print output.
For Troff2page though, we’d like to
re-define this macro, in Lua, to create a hyperlink.
We enclose this re-definition in a \fC.ig ##\fP, which not
only allows it to be in Lua, but also makes it apply only
when Troff2page reads it:
.IX defstring, Troff2page Lua function
.IX link_start, Troff2page Lua function
.IX link_stop, Troff2page Lua function
.EX
    .ig ##
    defstring('url', function(url)
      return link_start(url) .. url .. link_stop()
    end)
    .##
.EE
The procedures \fCdefstring\fP, \fClink_start\fP, and
\fClink_stop\fP are defined in the Troff2page code.
