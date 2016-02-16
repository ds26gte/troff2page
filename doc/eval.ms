.SH 1
7. Extending troff using Common Lisp

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
Consider the following troff document, \fCtau.ms\fP:

.EX
    .mso eval4troff.tmac
    .
    The ratio of the circumference of a circle to
    its radius is \(*t \(~=
    .eval
    ;following prints tau, because cos(tau/2) = -1
    (princ (* 2 (acos -1)))
    (princ ".")
    (terpri)
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
You will find that the groff call produces a message like
the following:

.EX
.ec
    \f(CI.trofftemp.lisp missing for this run
    Rerun groff with -U
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
;following prints tau, because cos(tau/2) = -1
(princ (* 2 (acos -1)))
(princ ".")
(terpri)
.endeval
.RE
.B2

The first groff call produces a Lisp file
\fC.trofftemp.lisp\fP.\**
.FS
This name may be different based on
your setting of \fC\e*[AUXF]\fP — see page \*[TAG:auxf].
.FE
The second groff
call invokes Lisp to create an auxiliary file for each \fC.eval\fP that gets sourced
back into the document.

It is clear that Lisp code via \fC.eval\fP can
serve as a very powerful \fIsecond extension language\fP
for troff.  This benefit is available even when the document
is processed by troff2page:
We could run troff2page on the same document, \fCtau.ms\fP, and the
resulting \fCtau.html\fP will show the same content.

.IX extending troff and troff2page differently with Common Lisp
Furthermore, we can embed  \fC.eval\fP-enclosed Lisp code inside an
\fC.if\fP (or \fC.ie\fP or \fC.el\fP) statement so that it gets executed
only for troff or only for troff2page.  (Recall we used the number register
\fC\en[.troff2page]\fP for this purpose on page \*[TAG:cond-bp].)  In
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

.IX extending troff2page with Common Lisp without producing output
.IX ig@.ig ##, as troff2page extender
troff2page treats troff’s \fC.ig\fP
environment, whenever it uses \fC##\fP as ender, as
containing Lisp code that can be used to extend
troff2page.  This syntactic overloading of \fC.ig ##\fP is an innovation introduced by
Oliver Laumann’s \*[url \
http://www-rn.informatik.uni-bremen.de/software/unroff]unroff\&.

Any Lisp code enclosed within
\&\fC.ig ##\fP ... \fC.##\fP will be processed by
troff2page but not by
troff, which treats it as a multiline comment of course.
Note that \fC.ig ##\fP does not pipe its stdout back into
the document, as \fC.eval\fP does.  This is to maintain the invariant
that as far as output is
concerned, \fC.ig ##\fP, like other \fC.ig\fPs, is \fIalways\fP a
comment.  However, you can add Lisp code within \fC.ig ##\fP
to influence how troff2page — but not troff! — processes the rest of the
document.

For example, let’s define a
\fC\e*[url]\fP string register that simply typesets its URL
argument within angle brackets.

.EX
    .ds url \(la\fC\\$1\fP\(ra
.EE

This is adequate for the print output.
For troff2page though, we’d like to
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
troff2page uses the output-stream \fC*css-stream*\fP to
write out style information.  The user can also write to this stream, e.g.,

.EX
    .ig ##
    (format *css-stream* "
        h1,h2,h3,h4,h5,h6 {
            color: rgb(61,35,39); /* chocolate */
        }
        ")
    .##
.EE

.ig ##
    (format *css-stream* "
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
http://www.resene.co.nz/swatches]Resene Paints\&.
.FE
