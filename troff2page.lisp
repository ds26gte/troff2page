":"; export T2PARG=$1
":"; if test "$LISP" = abcl; then exec abcl --load $0 --eval '(ext::quit)'
":"; elif test "$LISP" = allegro; then exec alisp -L $0 -kill
":"; elif test "$LISP" = clisp; then exec clisp -q $0
":"; elif test "$LISP" = clozure; then exec ccl -l $0 -e '(ccl:quit)'
":"; elif test "$LISP" = cmucl; then exec lisp -quiet -load $0 -eval '(ext::quit)'
":"; elif test "$LISP" = ecl; then exec ecl -shell $0
":"; else exec sbcl --script $0
":"; fi

#+sbcl
(declaim (sb-ext:muffle-conditions style-warning))

(defpackage :troff2page
  (:use :cl)
  (:export :troff2page))

(in-package :troff2page)

(defparameter *troff2page-version* 20150713) ;last change

(defparameter *troff2page-website*
  ;for details, please see
  "http://ds26gte.github.io/troff2page/index.html")

(defparameter *troff2page-copyright-notice*
  (format nil "Copyright (C) 2003-~a Dorai Sitaram"
          (subseq (format nil "~a" *troff2page-version*) 2 4)))

(defun retrieve-env (s)
  (or #+clisp (ext::getenv s)
      #+clozure (ccl::getenv s)
      #+cmu (cdr (assoc s ext::*environment-list* :test #'string=))
      #+ecl (si::getenv s)
      #+sbcl (sb-ext::posix-getenv s)
      nil))

(defvar *troff2page-file-arg*
  (or #-(or clisp clozure cmu ecl sbcl)
      (progn
        (format t "! Don't know how to read your Common Lisp's command-line.~%")
        (format t "! Please load the file troff2page into your CL and then~%")
        (format t "!   call the procedure troff2page:troff2page on your troff document(s)~%")
        t)
      (retrieve-env "T2PARG")))

(defun os-execute (s)
  (or #+clisp (ext::shell s)
      #+clozure (ccl::os-command s)
      #+cmu (ext::run-program "sh" (list "-c" s) :output t)
      #+ecl (si::system s)
      #+sbcl
      (let ((p (sb-ext::run-program "sh" (list "-c" s) :search t :output t)))
        (sb-ext::process-exit-code p))
      nil))

(defun retrieve-pid ()
  (or #+clisp
      (funcall (if (find-package :linux)
                 ;CLISP has different names for this function in Ubuntu and Darwin
                 (find-symbol "GETPID" :linux)
                 (find-symbol "GETPPID" :posix)))
      #+clozure (ccl::getpid)
      #+cmu (unix::unix-getpid)
      #+ecl (si::getpid)
      #+sbcl (sb-unix::unix-getpid)
      999))

;

(defparameter *operating-system*
  ;change if you need a better OS identifier.
  ;We only need distinguish between Unix and Windows.
  ;Cygwin on Windows qualifies as Unix
  (or #+unix :unix
      #+darwin :unix  ;ECL on Unix doesn't have #+unix
      (if (retrieve-env "COMSPEC") :windows :unix)))

(setq *load-verbose* nil)

(defparameter *ghostscript*
  ;the name of the Ghostscript executable.  You
  ;may need to modify for Windows
  (case *operating-system*
    (:windows (or (some
                      (lambda (f)
                        (and (probe-file f) f))
                      '("g:\\cygwin\\bin\\gs.exe"
                        "c:\\aladdin\\gs6.01\\bin\\gswin32c.exe"
                        "d:\\aladdin\\gs6.01\\bin\\gswin32c.exe"
                        "d:\\gs\\gs8.00\\bin\\gswin32.exe"
                        "g:\\gs\\gs8.00\\bin\\gswin32.exe"
                        ))
                    "gswin32.exe"))
    (t "gs")))

;*** The following defparameters not to be changed lightly ***

(defparameter *ghostscript-options*
  " -q -dBATCH -dNOPAUSE -dNO_PAUSE -sDEVICE=ppmraw")

(defparameter *groff-image-options*
  "-fN -rPS=20 -rVS=24")

(defparameter *path-separator*
  (if (eq *operating-system* :windows) #\; #\:))

(defparameter *aux-file-suffix* "-Z-A.lisp")
(defparameter *css-file-suffix* "-Z-S.css")
(defparameter *html-conversion-by* "HTML conversion by")
(defparameter *html-node-prefix* "node_")
(defparameter *html-page-suffix* "-Z-H-")
(defparameter *image-file-suffix* "-Z-G-")
(defparameter *last-modified* "Last modified: ")
(defparameter *navigation-contents-name* "contents")
(defparameter *navigation-first-name* "first")
(defparameter *navigation-index-name* "index")
(defparameter *navigation-next-name* "next")
(defparameter *navigation-page-name* " page")
(defparameter *navigation-previous-name* "previous")
(defparameter *navigation-sentence-begin* "Go to ")
(defparameter *navigation-sentence-end* "")
(defparameter *output-extension* ".html")
(defparameter *pso-file-suffix* "-Z-T.1")

;

(defvar *standard-glyphs*
  '(
    ;refer groff_char(7)

    " " #xa0 ; &nbsp;
    "!=" #x2260
    "%" #x200c
    "%0" #x2030
    "&" #x200c
    "'A" #xc1
    "'C" #x106
    "'E" #xc9
    "'I" #xcd
    "'O" #xd3
    "'U" #xda
    "'Y" #xdd
    "'a" #xe1
    "'c" #x107
    "'e" #xe9
    "'i" #xed
    "'o" #xf3
    "'u" #xfa
    "'y" #xfd
    "**" #x2217
    "*A" #x391
    "*B" #x392
    "*C" #x39e
    "*D" #x394
    "*E" #x395
    "*F" #x3a6
    "*G" #x393
    "*H" #x398
    "*I" #x399
    "*K" #x39a
    "*L" #x39b
    "*M" #x39c
    "*N" #x39d
    "*O" #x39f
    "*P" #x3a0
    "*Q" #x3a8
    "*R" #x3a1
    "*S" #x3a3
    "*T" #x3a4
    "*U" #x3a5
    "*W" #x3a9
    "*X" #x3a7
    "*Y" #x397
    "*Z" #x396
    "*a" #x3b1
    "*b" #x3b2
    "*c" #x3be
    "*d" #x3b4
    "*e" #x3b5
    "*f" #x3c6
    "*g" #x3b3
    "*h" #x3b8
    "*i" #x3b9
    "*k" #x3ba
    "*l" #x3bb
    "*m" #x3bc
    "*n" #x3bd
    "*o" #x3bf
    "*p" #x3c0
    "*q" #x3c8
    "*r" #x3c1
    "*s" #x3c3
    "*t" #x3c4
    "*u" #x3c5
    "*w" #x3c9
    "*x" #x3c7
    "*y" #x3b7
    "*z" #x3b6
    "+-" #xb1
    "+e" #x3f5
    "+f" #x3d5
    "+h" #x3d1
    "+p" #x3d6
    "," #x200c
    ",C" #xc7
    ",c" #xe7
    "-" #x2212
    "-+" #x2213
    "->" #x2192
    "-D" #xd0
    "-h" #x210f
    ".i" #x131
    "/" #x200c
    "/L" #x141
    "/O" #xd8
    "/_" #x2220
    "/l" #x142
    "/o" #xf8
    "0" #x2007
    "12" #xbd
    "14" #xbc
    "18" #x215b
    "34" #xbe
    "38" #x215c
    "3d" #x2234
    "58" #x215d
    "78" #x215e
    ":" #x200c
    ":A" #xc4
    ":E" #xcb
    ":I" #xcf
    ":O" #xd6
    ":U" #xdc
    ":Y" #x178
    ":a" #xe4
    ":e" #xeb
    ":i" #xef
    ":o" #xf6
    ":u" #xfc
    ":y" #xff
    "<-" #x2190
    "<<" #x226a
    "<=" #x2264
    "<>" #x2194
    "==" #x2261
    "=~" #x2245
    ">=" #x2265
    ">>" #x226b
    "AE" #xc6
    "AN" #x2227
    "Ah" #x2135
    "Bq" #x201e
    "CL" #x2663
    "CR" #x21b5
    "Cs" #xa4
    "DI" #x2666
    "Do" #x24
    "Eu" #x20ac
    "Fc" #xbb
    "Fi" #xfb03
    "Fl" #xfb04
    "Fn" #x192
    "Fo" #xab
    "HE" #x2265
    "IJ" #x132
    "Im" #x2111
    "OE" #x152
    "OK" #x2713
    "OR" #x2228
    "Of" #xaa
    "Om" #xba
    "Po" #xa3
    "Re" #x211c
    "S1" #xb9
    "S2" #xb2
    "S3" #xb3
    "SP" #x2660
    "Sd" #xf0
    "TP" #xde
    "Tp" #xfe
    "Ye" #xa5
    "^" #x2009
    "^A" #xc2
    "^E" #xca
    "^I" #xce
    "^O" #xd4
    "^U" #xdb
    "^a" #xe2
    "^e" #xea
    "^i" #xee
    "^o" #xf4
    "^u" #xfb
    "`A" #xc0
    "`E" #xc8
    "`I" #xcc
    "`O" #xd2
    "`U" #xd9
    "`a" #xe0
    "`e" #xe8
    "`i" #xec
    "`o" #xf2
    "`u" #xf9
    "ae" #xe6
    "an" #x23af
    "ap" #x223c
    "aq" #x27
    "at" #x40
    "ba" #x7c
    "bb" #xa6
    "bq" #x201a
    "br" #x2502
    "braceex" #x23aa
    "braceleftbt" #x23a9
    "braceleftex" #x23aa
    "braceleftmid" #x23a8
    "bracelefttp" #x23a7
    "bracerightbt" #x23ad
    "bracerightex" #x23aa
    "bracerightmid" #x23ac
    "bracerighttp" #x23ab
    "bracketleftbt" #x23a3
    "bracketleftex" #x23a2
    "bracketlefttp" #x23a1
    "bracketrightbt" #x23a6
    "bracketrightex" #x23a5
    "bracketrighttp" #x23a4
    "bu" #x2022
    "bv" #x23aa
    "c*" #x2297
    "c+" #x2295
    "ca" #x2229
    "ci" #x25cb
    "co" #xa9
    "coproduct" #x2210
    "cq" #x2019
    "ct" #xa2
    "cu" #x222a
    "dA" #x21d3
    "da" #x2193
    "dd" #x2021
    "de" #xb0
    "dg" #x2020
    "di" #xf7
    "dq" #x22
    "em" #x2014
    "en" #x2013
    "eq" #x3d
    "es" #x2205
    "eu" #x20ac
    "f/" #x2044
    "fa" #x2200
    "fc" #x203a
    "ff" #xfb00
    "fi" #xfb01
    "fl" #xfb02
    "fm" #x2032
    "fo" #x2039
    "gr" #x2207
    "hA" #x21d4
    "hbar" #x210f
    "hy" #x2010
    "ib" #x2286
    "if" #x221e
    "ij" #x133
    "integral" #x222b
    "ip" #x2287
    "is" #x222b
    "lA" #x21d0
    "lB" #x5b
    "lC" #x7b
    "la" #x2329 ; #x27e8 doesn't seem to work
    "lb" #x23a9
    "lc" #x2308
    "lf" #x230a
    "lh" #x261a ; groff_char(7) wants #x261c
    "lk" #x23a8
    "lq" #x201c
    "lt" #x23a7
    "lz" #x25ca
    "mc" #xb5
    "md" #x22c5
    "mi" #x2212
    "mo" #x2208
    "mu" #xd7
    "nb" #x2284
    "nc" #x2285
    "ne" #x2262
    "nm" #x2209
    "no" #xac
    "oA" #xc5
    "oa" #xe5
    "oe" #x153
    "oq" #x2018
    "or" #x7c
    "parenleftbt" #x239d
    "parenleftex" #x239c
    "parenlefttp" #x239b
    "parenrightbt" #x23a0
    "parenrightex" #x239f
    "parenrighttp" #x239e
    "pc" #xb7
    "pd" #x2202
    "pl" #x2b
    "pp" #x22a5
    "product" #x220f
    "ps" #xb6
    "pt" #x221d
    "r!" #xa1
    "r?" #xbf
    "rA" #x21d2
    "rB" #x5d
    "rC" #x7d
    "ra" #x232a ; #x27e9 doesn't work
    "rb" #x23ad
    "rc" #x2309
    "rf" #x230b
    "rg" #xae
    "rh" #x261b ; groff_char(7) wants #x261e
    "rk" #x23ac
    "rn" #x203e
    "rq" #x201d
    "rs" #x5c
    "rt" #x23ab
    "ru" #x5f
    "sb" #x2282
    "sc" #xa7
    "sd" #x2033
    "sh" #x23
    "sl" #x2f
    "sp" #x2283
    "sq" #x25a1
    "sqrt" #x221a
    "sr" #x221a
    "ss" #xdf
    "st" #x220d ;groff_char(7) wants #x220b but that's too big
    "sum" #x2211
    "t+-" #xb1
    "tdi" #xf7
    "te" #x2203
    "tf" #x2234
    "tm" #x2122
    "tmu" #xd7
    "tno" #xac
    "ts" #x3c2
    "uA" #x21d1
    "ua" #x2191
    "ul" #x5f
    "vA" #x21d5
    "vS" #x160
    "vZ" #x17d
    "va" #x2195
    "vs" #x161
    "vz" #x17e
    "wp" #x2118
    "|" #x2006
    "|=" #x2243
    "~" #xa0 ; &nbsp;
    "~=" #x2248
    "~A" #xc3
    "~N" #xd1
    "~O" #xd5
    "~a" #xe3
    "~n" #xf1
    "~o" #xf5
    "~~" #x2248

    ))

;

(defvar *escape-table* (make-hash-table :test #'eql))
(defvar *it* :anaphora)
(defvar *nroff-image-p* nil)
(defvar *request-table* (make-hash-table :test #'equal))

;

(defvar *afterpar*)
(defvar *aux-port*)
(defvar *blank-line-macro*)
(defvar *cascaded-if-p*)
(defvar *cascaded-if-stack*)
(defvar *color-table*)
(defvar *control-char*)
(defvar *css-port*)
(defvar *current-diversion*)
(defvar *current-pageno*)
(defvar *current-source-file*)
(defvar *current-troff-input*)
(defvar *diversion-table*)
(defvar *end-macro*)
(defvar *escape-char*)
(defvar *ev-stack*)
(defvar *ev-table*)
(defvar *exit-status*)
(defvar *font-alternating-style-p*)
(defvar *footnote-buffer*)
(defvar *footnote-count*)
(defvar *glyph-table*)
(defvar *groff-tmac-path*)
(defvar *html-head*)
(defvar *html-page*)
(defvar *image-file-count*)
(defvar *input-line-no*)
(defvar *inside-table-text-block-p*)
(defvar *jobname*)
(defvar *just-after-par-start-p*)
(defvar *keep-newline-p*)
(defvar *last-input-milestone*)
(defvar *last-page-number*)
(defvar *leading-spaces-macro*)
(defvar *leading-spaces-number*)
(defvar *lines-to-be-centered*)
(defvar *macro-args*)
(defvar *macro-copy-mode-p*)
(defvar *macro-package*)
(defvar *macro-spill-over*)
(defvar *macro-table*)
(defvar *main-troff-file*)
(defvar *margin-left*)
(defvar *missing-pieces*)
(defvar *no-break-control-char*)
(defvar *node-table*)
(defvar *num-of-times-th-called*)
(defvar *numreg-table*)
(defvar *out*)
(defvar *output-streams*)
(defvar *outputting-to*)
(defvar *previous-line-exec-p*)
(defvar *pso-temp-file*)
(defvar *reading-quoted-phrase-p*)
(defvar *reading-string-call-p*)
(defvar *reading-table-p*)
(defvar *saved-escape-char*)
(defvar *sourcing-ascii-file-p*)
(defvar *string-table*)
(defvar *stylesheets*)
(defvar *table-align*)
(defvar *table-cell-number*)
(defvar *table-colsep-char*)
(defvar *table-default-format-line*)
(defvar *table-format-table*)
(defvar *table-number-of-columns*)
(defvar *table-options*)
(defvar *table-row-number*)
(defvar *temp-string-count*)
(defvar *this-footnote-is-numbered-p*)
(defvar *title*)
(defvar *turn-off-escape-char-p*)
(defvar *verbatim-apostrophe-p*)

;

(defstruct bport* (port nil) (buffer '()))
(defstruct counter* (value 0) (format "1") (thunk nil))
(defstruct diversion* port return)
(defstruct footnote* tag number text)

(defstruct ev*
  (name nil)
  (fill t)
  (font nil)
  (size nil)
  (color nil)
  (bgcolor nil)
  (prevfont nil)
  (prevsize nil)
  (prevcolor nil)
  (prevbgcolor nil))

(defun defrequest (w th)
  (setf (gethash w *request-table*) th))

(defun defescape (c th)
  (setf (gethash c *escape-table*) th))

(defun defglyph (w s)
  (setf (gethash w *glyph-table*) s))

(defun defnumreg (w ctr)
  (setf (gethash w *numreg-table*) ctr))

(defun defstring (w th)
  (setf (gethash w *string-table*) th))

;

(defun flag-missing-piece (mp)
  (pushnew mp *missing-pieces*))

;link generation

(defun anchor (lbl)
  (concatenate 'string
               (verbatim "<a name=\"")
               (verbatim lbl)
               (verbatim "\"></a>")))

(defun link-start (link &key internal-node-p)
  (concatenate 'string
    (verbatim "<a")
    (verbatim (if internal-node-p
		" class=hrefinternal"
		""))
    (verbatim " href=\"")
    (verbatim link)  ;verbatim?
    (verbatim "\"><span class=hreftext>")))

(defun link-stop ()
    (verbatim "</span></a>"))

(defun page-link (pageno)
    (page-node-link pageno nil))

(defun page-node-link (link-pageno node)
  (let ((curr-pageno *current-pageno*))
    (when (not link-pageno) (setq link-pageno curr-pageno))
    (concatenate 'string
      (if (= link-pageno curr-pageno) ""
        (concatenate 'string
          *jobname*
          (if (= link-pageno 0) ""
            (concatenate 'string
              *html-page-suffix*
              (write-to-string link-pageno)))
          *output-extension*))
      (if node "#" "")
      node)))

(defun link-url (url)
  (cond ((not (char= (char url 0) #\#)) (values url nil))
	((setq url (subseq url 1)
	       *it* (gethash url *node-table*))
	 (values (page-node-link *it* url) t))
        (t (values "[???]" nil))))

(defun man-url ()
  (let ((url "")
        url-more c c2)
    (loop
      (setq url-more (read-till-chars '(#\space #\tab #\newline
                                         #\, #\" #\' #\)
                                         #\: #\.)))
      (setq url (concatenate 'string url url-more))
      (setq c (snoop-char))
      (cond ((not c) (return))
            ((member c '(#\: #\.))
             (get-char)
             (setq c2 (snoop-char))
             (cond ((or (not c2)
                        (member c2 '(#\space #\tab #\newline))
                        (and (char= c #\.)
                             (member c2 '(#\" #\' #\)))))
                    (toss-back-char c)
                    (return))
                   (t (setq url (concatenate 'string url (string c))))))
            (t (return))))
    (concatenate 'string
                (link-start url)
                 url
                 (link-stop))))

(defun url-string-value (url &optional link-text)
  (let (internal-node-p)
    (if link-text
      (multiple-value-setq (url internal-node-p) (link-url url))
      (setq link-text url))
    (concatenate 'string
                 (link-start url :internal-node-p internal-node-p)
                 link-text
                 (link-stop))))

(defun urlh-string-value (url)
  (let (internal-node-p
         (link-text "")
         link-text-more
         c)
    (loop
      (setq link-text-more (read-till-char #\\ :eat-delim-p t))
      (setq link-text (concatenate 'string link-text link-text-more))
      (setq c (snoop-char))
      (cond ((not c)
             (setq link-text (concatenate 'string link-text "\\"))
             (return))
            ((char= c #\&)
             (get-char)
             (return))
            (t (setq link-text (concatenate 'string link-text "\\")))))
    (multiple-value-setq (url internal-node-p) (link-url url))
    (concatenate 'string
                 (link-start url :internal-node-p internal-node-p)
                 (expand-args link-text)
                 (link-stop))))

;** environments

(defun ev-copy (lhs rhs)
  (setf (ev*-fill lhs) (ev*-fill rhs)
        (ev*-font lhs) (ev*-font rhs)
        (ev*-color lhs) (ev*-color rhs)
	(ev*-bgcolor lhs) (ev*-bgcolor rhs)
        (ev*-prevfont lhs) (ev*-prevfont rhs)
        (ev*-prevcolor lhs) (ev*-prevcolor rhs)))

(defun ev-pop ()
  (let ((ev-stack-rest (cdr *ev-stack*)))
    (unless (null ev-stack-rest)
      (let ((ev-curr (car *ev-stack*)))
        (setq *ev-stack* ev-stack-rest)
        (ev-switch ev-curr (car *ev-stack*))))))

(defun ev-push (new-ev-name)
    (let ((new-ev (ev-named new-ev-name))
          (curr-ev (car *ev-stack*)))
      (push new-ev *ev-stack*)
      (ev-switch curr-ev new-ev)))

(defun ev-switch (ev-old ev-new)
  (unless (eql ev-new ev-old)
    (let ((old-font (ev*-font ev-old))
          (old-color (ev*-color ev-old))
	  (old-bgcolor (ev*-bgcolor ev-old))
          (old-size (ev*-size ev-old))
          (new-font (ev*-font ev-new))
          (new-color (ev*-color ev-new))
	  (new-bgcolor (ev*-bgcolor ev-new))
          (new-size (ev*-size ev-new)))
      (when (or old-font old-color old-bgcolor old-size)
        (emit-verbatim "</span>"))
      (when (or new-font new-color new-bgcolor new-size)
        (emit (make-span-open :font new-font
                              :color new-color
			      :bgcolor new-bgcolor
                              :size new-size))))))

(defun ev-named (s)
  (or (gethash s *ev-table*)
      (setf (gethash s *ev-table*)
            (make-ev* :name s))))

;** input

(defun get-char ()
  (cond ((consp (bport*-buffer *current-troff-input*))
         (pop (bport*-buffer *current-troff-input*)))
        ((setq *it* (bport*-port *current-troff-input*))
         (let ((c (read-char *it* nil)))
           (when c
             (when (char= c #\return)
               (setq c #\newline)
               (let ((c2 (peek-char nil *it*)))
                 (when (and c2
                            (char= c2 #\newline))
                   (read-char *it*))))
             (when (char= c #\newline) (incf *input-line-no*)))
           c))
        (t nil)))

(defun toss-back-char (c)
  (push c (bport*-buffer *current-troff-input*)))

(defun snoop-char ()
  (let ((c (get-char)))
    (toss-back-char c)
    c))

(defun twarning (fstr &rest args)
  (format t "~a:~a: " *current-source-file* *input-line-no*)
  (apply #'format t fstr args)
  (terpri))

(defun edit-offending-file ()
  (format t "Type e to edit file ~a at line ~a; x to quit.~%"
          *current-source-file* *input-line-no*)
  (princ "? ")
  (force-output)
  (let ((c (read-char)))
    (when (and c (char-equal c #\e))
      (os-execute
        (format nil "~a +~a ~a"
                (or (retrieve-env "EDITOR") "vi")
                *input-line-no*
                *current-source-file*)))))

(defun terror (&rest args)
  (apply #'twarning args)
  (close-all-open-ports)
  (edit-offending-file)
  (error "troff2page fatal error"))

(defun read-till-chars (delims &key eat-delim-p)
  (let ((newline-is-delim-p (member #\newline delims :test #'char=))
        (r ""))
    (loop
      (let ((c (snoop-char)))
        (cond ((not c)
               (if newline-is-delim-p
                 (if (string= r "") c r)
                 (progn
                 (terror "read-till-chars: could not find closer ~a" r)
                 (return))))
              ((member c delims :test #'char=)
               (when eat-delim-p (get-char))
               (return r))
              (t (get-char)
                 (setq r (concatenate 'string r (string c)))))))))

(defun read-till-char (delim &key eat-delim-p)
  (read-till-chars (list delim) :eat-delim-p eat-delim-p))

(defun read-one-line ()
  (read-till-char #\newline :eat-delim-p t))

(defun toss-back-string (s)
  (setf (bport*-buffer *current-troff-input*)
        (nconc (concatenate 'list s)
               (bport*-buffer *current-troff-input*))))

(defun toss-back-line (s)
  (setf (bport*-buffer *current-troff-input*)
        (nconc (concatenate 'list s)
               (cons #\newline
                     (bport*-buffer *current-troff-input*)))))

(defun ignore-spaces ()
  (loop
    (let ((c (snoop-char)))
      (cond ((not c) (return))
            ((or (char= c #\space) (char= c #\tab))
             (get-char))
            (t (return))))))

(defun ignore-char (c)
  (unless (or (char= c #\space) (char= c #\tab))
    (ignore-spaces))
  (let ((d (snoop-char)))
    (cond ((not d) t)
          ((char= d c) (get-char)))))

(defun escape-char-p (c)
  (and (not *turn-off-escape-char-p*)
       (char= c *escape-char*)))

(defun read-word ()
  (ignore-spaces)
  (let ((c (snoop-char)))
    (cond ((or (not c) (char= c #\newline)) nil)
          ((char= c #\") (read-quoted-phrase))
          ((escape-char-p c)
           (get-char)
           (let ((c2 (snoop-char)))
             (cond ((not c2) (string *escape-char*))
                   ((char= c2 #\newline) (get-char) (read-word))
                   (t (toss-back-char c)
                      (read-bare-word)))))
          (t (read-bare-word)))))

(defun read-rest-of-line ()
  (ignore-spaces)
  (let ((r '()))
    (loop
      (let ((c (snoop-char)))
        (cond ((or (not c) (char= c #\newline))
               (get-char) (return))
              (t (get-char) (push c r)))))
    (expand-args
      (concatenate 'string (nreverse r)))))

(defun read-quoted-phrase ()
  (get-char) ;read the "
  (let ((*reading-quoted-phrase-p* t)
        (read-escape? nil)
        (r '()))
    (loop
      (let ((c (snoop-char)))
        (cond (read-escape?
                (setq read-escape? nil)
                (get-char)
                (cond ((char= c #\newline) t)
                      (t (push *escape-char* r)
                         (push c r))))
              ((escape-char-p c)
               (setq read-escape? t)
               (get-char))
              ((or (char= c #\") (char= c #\newline))
               (when (char= c #\") (get-char))
               (return))
              (t (get-char)
                 (push c r)))))
    (concatenate 'string (nreverse r))))

(defun read-bare-word ()
  (let ((read-escape-p nil) (bracket-nesting 0) (r '()))
    (loop
      (let ((c (snoop-char)))
        (cond (read-escape-p (setq read-escape-p nil)
                             (cond ((not c) (return))
                                   ((char= c #\newline) (get-char))
                                   (t (get-char) (push *escape-char* r)
                                      (push c r))))
              ((or (not c)
                   (member c '(#\space #\tab #\newline))
                   (and *reading-table-p* (member c '(#\( #\, #\; #\.)))
                   (and *reading-string-call-p*
                        (char= c #\]) (= bracket-nesting 0)))
               (return))
              ((escape-char-p c) (setq read-escape-p t)
                                 (get-char))
              (t (get-char)
                 (when *reading-string-call-p*
                   (cond ((char= c #\[) (incf bracket-nesting))
                         ((char= c #\]) (decf bracket-nesting))))
                 (push c r)))))
    (concatenate 'string (nreverse r))))

(defun read-troff-line (&key stop-before-newline-p)
  (let ((read-escape-p nil)
        (r '()))
    (loop (let ((c (snoop-char)))
            (when (not c) (return))
            (when (and (char= c #\newline) (not read-escape-p))
              (unless stop-before-newline-p (get-char))
              (return))
            (cond (read-escape-p
                    (setq read-escape-p nil)
                    (cond ((char= c #\newline) (get-char))
                          (t (get-char)
                             (push *escape-char* r)
                             (push c r))))
                  ((escape-char-p c) (setq read-escape-p t)
                                     (get-char))
                  (t (get-char)
                     (push c r)))))
    (concatenate 'string (nreverse r))))

(defun read-troff-string-line ()
  (ignore-spaces)
  (let ((c (snoop-char)))
    (cond ((not c) "")
          (t (when (char= c #\") (get-char))
             (read-troff-line)))))

(defun collect-macro-body (w ender)
  (let ((m '()))
    (loop
      (when (not (snoop-char))
        (setq *exit-status* :done)
        (setq *macro-spill-over*
              (concatenate 'string (string *control-char*) "am "
                w " " ender))
        (return))
      (let* ((ln (expand-args (read-troff-line)))
             (*current-troff-input* (make-bport*)))
        (toss-back-line ln)
        (let ((c (snoop-char)))
          (cond ((char= c *control-char*)
                 (get-char)
                 (ignore-spaces)
                 (let ((w (read-bare-word)))
                   (when (and (stringp w) (string= w ender))
                     (return))
                   (push ln m)))
                (t (push ln m))))))
    (nreverse m)))

(defun expand-args (s)
  (if (not s) ""
    (with-output-to-string (o)
      (let ((*current-troff-input* (make-bport* :buffer (concatenate 'list s)))
            (*macro-copy-mode-p* t)
            (*outputting-to* :troff)
            (*out* o))
        (generate-html '(:return :nx :ex))))))

;** .TS ... .TE

(defun string-trim-blanks (s)
 (string-trim '(#\space #\tab #\newline #\return) s))

(defun table-do-global-options ()
  (loop
    (let* ((x (string-trim-blanks (read-one-line)))
           (xn (length x)))
        (table-do-global-option-1 x)
        (when (and (> xn 0) (char= (char x (- xn 1)) #\;))
          (return)))))

(defun table-do-global-option-1 (x)
  (let ((*current-troff-input*
          (make-bport* :buffer (concatenate 'list x))))
    (loop
      (ignore-char #\,)
      (let ((w (read-word)))
        (unless (and w (not (string= w ""))) (return))
        (cond ((string= w "tab")
               (ignore-char #\( )
               (ignore-spaces)
               (setq *table-colsep-char* (get-char))
               (ignore-char #\) ))
              ((or (string= w "box")
                   (string= w "frame")
                   (string= w "doublebox")
                   (string= w "doubleframe"))
               (setq *table-options*
                     (concatenate 'string *table-options*
                                  " border=1"
                       ;" border=1 rules=none"
                       )))
              ((string= w "allbox")
               (setq *table-options*
                     (concatenate 'string *table-options*
                       " border=1")))
              ((string= w "expand")
               (setq *table-options*
                     (concatenate 'string *table-options*
                       " width=\"100%\"")))
              ((string= w "center")
               (setq *table-align* "center")))))))

(defun table-do-format-section ()
  (setq *table-default-format-line* 0)
  (loop
    (let* ((x (string-trim-blanks (read-one-line)))
           (xn (length x)))
      (incf *table-default-format-line*)
      (table-do-format-1 x)
      (when (and (> xn 0) (char= (char x (- xn 1)) #\.))
        (return)))))

(defun table-do-format-1 (x)
  (let ((*current-troff-input*
          (make-bport* :buffer (concatenate 'list x)))
        (row-hash-table (make-hash-table))
        (cell-number 0)
        (w nil)
        (align nil)
        (font nil))
    (loop
      ;(ignore-char #\,)
      (setq w (concatenate 'list (read-word)))
      (setq align nil) (setq font nil)
      (unless w (return))
      (incf cell-number)
      (when (member #\b w :test #'char-equal) (setq font "B"))
      (when (member #\i w :test #'char-equal) (setq font "I"))
      (when (member #\c w :test #'char-equal) (setq align "center"))
      (when (member #\l w :test #'char-equal) (setq align "left"))
      (when (member #\r w :test #'char-equal) (setq align "right"))
      (setf (gethash cell-number row-hash-table)
            (list :align align :font font)))
    (when (> cell-number *table-number-of-columns*)
      (setq *table-number-of-columns* cell-number))
    (setf (gethash *table-default-format-line* *table-format-table*)
          row-hash-table)))

(defun table-do-rows ()
  (let ((*inside-table-text-block-p* nil)
        (*table-row-number* 1)
        (*table-cell-number* 0))
    (loop
      (when (= *table-cell-number* 0)
        (emit-verbatim "<tr>"))
      ;(ignore-spaces) ;?
      (let ((c (snoop-char)))
        (cond ((and (= *table-cell-number* 0) (char= c *control-char*))
               (get-char)
               (let ((w (read-word)))
                 (cond ((and (stringp w) (string= w "TE"))
                        (return))
                       (t (when w (toss-back-string w))
                          (toss-back-char *control-char*)
                          ;(check-row-started)
                          (table-do-cell)))))
              ((and (= *table-cell-number* 0)
                    (member c '(#\_ #\- #\=) :test #'char=))
               (read-troff-line)
               (emit-verbatim "<td valign=top colspan=")
               (emit-verbatim *table-number-of-columns*)
               (emit-verbatim "><hr></td>"))
              ((and (not *inside-table-text-block-p*) (char= c #\T))
               (get-char)
               (setq c (snoop-char))
               (cond ((char= c #\{)
                      (get-char)
                      (setq *inside-table-text-block-p* t)
                      (ignore-char #\newline)
                      (table-do-cell))
                     (t (toss-back-char #\T)
                        (table-do-cell))))
              ((char= c *table-colsep-char*)
               (get-char))
              ((char= c #\newline)
               (get-char)
               (emit-verbatim "</tr>")
               (emit-newline)
               (incf *table-row-number*)
               (setq *table-cell-number* 0))
              (t (table-do-cell))))))
  (emit-newline))

(defun table-do-cell ()
  (incf *table-cell-number*)
  (let* ((cell-format-info
           (gethash *table-cell-number*
                    (gethash (min *table-row-number* *table-default-format-line*)
                             *table-format-table*)))
         (align (cadr (member :align cell-format-info)))
         (font (cadr (member :font cell-format-info))))
    (emit-verbatim "<td valign=top")
    (when align
      (emit-verbatim " align=")
      (emit-verbatim align))
    (emit-verbatim ">")
    (when font
      (emit (switch-font font)))
    (loop
      (let ((c (snoop-char)))
        (cond ((and *inside-table-text-block-p* (char= c #\T))
               (get-char)
               (setq c (snoop-char))
               (cond ((char= c #\})
                      (get-char)
                      (setq *inside-table-text-block-p* nil))
                     (t (toss-back-char #\T)
                        (troff2page-line (read-one-line)))))
              (*inside-table-text-block-p*
                (troff2page-line (read-one-line)))
              ((setq *it*
                     (read-till-chars
                       (list *table-colsep-char* #\newline)))
               (troff2page-line *it*)
               (return)))))
    (when font
      (emit (switch-font nil)))
    (emit-verbatim "</td>")))

;**

(defun read-possible-troff2page-specific-escape (i)
  (let ((c (peek-char nil i nil)))
    (cond ((not c) "")
          ((char= c #\[)
           (read-char i)
           (concatenate 'string
             (nreverse
               (let ((r (list c)))
                 (loop
                   (let ((c (peek-char nil i)))
                     (cond ((alpha-char-p c) (read-char i)
                                             (push c r))
                           ((char= c #\]) (read-char i)
                                          (push c r) (return r))
                           (t (return r)))))))))
          (t ""))))

(defun read-until-past-char-from-port (delim i)
  (let ((r '()))
    (loop
      (let ((c (read-char i)))
        (cond ((not c) (terror "read-until-past-char-from-port"))
              ((char= c delim)
               (return
                 (concatenate 'string (nreverse r))))
              (t (push c r)))))))

(defun emit-quote (q i)
  (if *verbatim-apostrophe-p* (princ q *out*)
    (let* ((double-quote-p nil)
           (fixed-width-p
             (let ((f (ev*-font (car *ev-stack*))))
               (and f (search "monospace" f)))))
      (unless fixed-width-p
        (let ((q2 (peek-char nil i nil)))
          (when (and q2
                     (or (char= q q2 #\`)
                         (char= q q2 #\')))
            (read-char i)
            (setq double-quote-p t))))
      (princ
        (ecase q
          (#\` (if double-quote-p "&#x201c;" "&#x2018;"))
          (#\' (if double-quote-p "&#x201d;" "&#x2019;")))
        *out*))))

(defun check-verbatim-apostrophe-status ()
  (when (eq *outputting-to* :html)
    (unless *verbatim-apostrophe-p*
      (let ((fixed-width-p (let ((f (ev*-font (car *ev-stack*))))
                             (and f (search "monospace" f)))))
        (unless fixed-width-p
          (!verbatim-apostrophe))))))

(defun emit (s)
  (with-input-from-string (i s)
    (let ((inside-html-angle-brackets-p nil) it)
      (loop
        (let ((c (read-char i nil)))
          (when (not c) (return))
          (ecase *outputting-to*
            ((:html :title)
             (cond ((setq it (gethash c *glyph-table*))
                    (emit it))
                   ((char= c #\\)
                    (let ((e (read-possible-troff2page-specific-escape i)))
                      (cond ((string= e "[htmllt]")
                             (if (eq *outputting-to* :title)
                               (setq inside-html-angle-brackets-p t)
                               (write-char #\< *out*)))
                            ((string= e "[htmlgt]")
                             (if (eq *outputting-to* :title)
                               (setq inside-html-angle-brackets-p nil)
                               (write-char #\> *out*)))
                            ((and (eq *outputting-to* :title)
                                  inside-html-angle-brackets-p) nil)
                            ((string= e "[htmlamp]")
                             (write-char #\& *out*))
                            ((string= e "[htmlquot]")
                             (write-char #\" *out*))
                            ((string= e "[htmlbackslash]")
                             (write-char #\\ *out*))
                            ((string= e "[htmlspace]")
                             (write-char #\space *out*))
                            ((string= e "[htmlnbsp]")
                             (princ "&#xa0;" *out*))
                            ((string= e "[htmleightnbsp]")
                             (dotimes (i 8)
                               (princ "&#xa0;" *out*)))
                            ((string= e "[htmlempty]") nil)
                            (t (write-char c *out*)
                               (princ e *out*)))))
                   ((and (eq *outputting-to* :title)
                         inside-html-angle-brackets-p) nil)
                   ((char= c #\<) (princ "&#x3c;" *out*))
                   ((char= c #\>) (princ "&#x3e;" *out*))
                   ((char= c #\&) (princ "&#x26;" *out*))
                   ((char= c #\")
                    (princ "&#x22;" *out*)
                    ;(check-verbatim-apostrophe-status)
                    ;do this in expand-line
                    )
                   ((or (char= c #\`) (char= c #\'))
                    (emit-quote c i))
                   ((fillp) (write-char c *out*))
                   ((char= c #\space) (emit-nbsp 1))
                   ((char= c #\tab) (emit-nbsp 8))
                   (t (write-char c *out*))))
            (:troff
             (write-char c *out*))))))))

(defun fillp ()
  (ev*-fill (car *ev-stack*)))

(defun emit-verbatim (s)
  (emit (verbatim s)))

(defun emit-newline ()
  (terpri *out*))

(defun emit-nbsp (n)
  (dotimes (i n)
    (emit "\\[htmlnbsp]")))

(defun verbatim-nbsp (n)
  (let ((r ""))
    (dotimes (i (ceiling n) r)
      (setq r (concatenate 'string
                r "\\[htmlnbsp]")))))

(defun verbatim (s)
  (cond ((numberp s) (write-to-string s)) ;??
        (t (let ((r ""))
             (dolist (c (concatenate 'list s) r)
               (setq r (concatenate 'string r
                         (case c
                           (#\< "\\[htmllt]")
                           (#\> "\\[htmlgt]")
                           (#\" "\\[htmlquot]")
                           (#\& "\\[htmlamp]")
                           (#\\ "\\[htmlbackslash]")
                           (#\space "\\[htmlspace]")
                           (t (string c))))))))))

;**

(defun emit-expanded-line ()
  (let ((r "")
        (num-leading-spaces 0)
        (blank-line-p t)
        (count-leading-spaces-p (and (fillp)
                                     (not *reading-table-p*)
                                     (not *macro-copy-mode-p*)
                                     (not (eql *outputting-to* :troff))))
        (insert-line-break-p (and (not *macro-copy-mode-p*)
                                  (eql *outputting-to* :html)
                                  (not *just-after-par-start-p*))))
    (when *just-after-par-start-p* (setq *just-after-par-start-p* nil))
    (loop
      (let ((c (get-char)))
        (when (not c)
          (setq *keep-newline-p* nil) ;?
          (setq c #\newline))
        (cond ((char= c #\newline)
               ;(setq *keep-newline-p* nil)
               (return))
              ((and count-leading-spaces-p (char= c #\space))
               (incf num-leading-spaces))
              ((and count-leading-spaces-p (char= c #\tab))
               (incf num-leading-spaces 8))
              ((escape-char-p c)
               (when blank-line-p (setq blank-line-p nil))
               (setq c (snoop-char))
               (unless c (setq c #\newline))
               (cond ((and count-leading-spaces-p
                           (not *reading-quoted-phrase-p*)
                           (member c '(#\" #\#)))
                      (expand-escape c)
                      ;(setq num-leading-spaces 0)
                      ;(setq insert-line-break-p nil)
                      (setq r "")
                      (return))
                     ((and *macro-copy-mode-p*
                           (member c '(#\newline #\{ #\} #\h) :test #'char=))
                      (setq r (concatenate 'string r (string *escape-char*))))
                     (t (when count-leading-spaces-p
                          (setq count-leading-spaces-p nil)
                          (emit-leading-spaces num-leading-spaces
                                             :insert-line-break-p insert-line-break-p))
                        (setq r (concatenate 'string r
                                             (expand-escape c)))
                        (when (member c '(#\{ #\newline)) (return)))))
              (t (when blank-line-p
                   (setq blank-line-p nil))
                 (when count-leading-spaces-p
                   (setq count-leading-spaces-p nil)
                  (emit-leading-spaces num-leading-spaces
                                     :insert-line-break-p insert-line-break-p)
                   )
                 (when (char= c #\") (check-verbatim-apostrophe-status))
                 (setq r (concatenate 'string r (string c)))))))
    (if blank-line-p (emit-blank-line)
      (emit r))))

(defun expand-escape (c)
  ;c is the char after escape -- it is still un-got
  (cond ((not c) (setq c #\newline))
        (t (get-char)))
  (cond (*turn-off-escape-char-p* (s-string *escape-char* c)) ;shdnt be needed
        ((setq *it* (gethash c *escape-table*)) (funcall *it*))
        ((setq *it* (gethash (string c) *glyph-table*)))
        (t (verbatim (string c)))))

(defun emit-navigation-bar (&key headerp)
  (cond ((and headerp (= *last-page-number* -1))
	 ;will put out some vertical space here, so when the correct header navbar
	 ;does get calculated in the next run, it will occupy the space without
	 ;the browser shifting the other text.
	 ;We don't need this phantom navbar for single-page output, but css takes
	 ;care of taking it out, even in the first run
	 (emit-verbatim "<div class=navigation>&#xa0;</div>"))
	((/= *last-page-number* 0)
	 (let* ((pageno *current-pageno*)
		(first-page-p (= pageno 0))
		(last-page-p (= pageno *last-page-number*))
                (toc-page (gethash "TAG_troff2page_toc" *node-table*))
		(toc-page-p (and toc-page (= pageno toc-page)))
		(index-page (gethash "TAG_troff2page_index" *node-table*))
		(index-page-p (and index-page (= pageno index-page))))
	   ;(emit-para)
	   (emit-verbatim "<div align=right class=navigation><i>")
	   ;(emit-newline)
	   (emit-verbatim "[")
	   (emit *navigation-sentence-begin*)
	   ;
	   (emit-verbatim "<span")
	   (when first-page-p (emit-verbatim " class=disable"))
	   (emit-verbatim ">")
	   (unless first-page-p  (emit (link-start (page-link 0))))
	   (emit *navigation-first-name*)
	   (unless first-page-p (emit (link-stop)))
	   (emit-verbatim ", ")
	   ;
	   (unless first-page-p  (emit (link-start (page-link (- pageno 1)))))
	   (emit *navigation-previous-name*)
	   (unless first-page-p (emit (link-stop)))
	   ;(emit ", ")
	   (emit-verbatim "</span>")
	   ;
	   (emit-verbatim "<span")
	   (when last-page-p (emit-verbatim " class=disable"))
	   (emit-verbatim ">")
	   (when first-page-p (emit-verbatim "<span class=disable>"))
	   (emit-verbatim ", ")
	   (when first-page-p (emit-verbatim "</span>"))
	   (unless last-page-p  (emit (link-start (page-link (+ pageno 1)))))
	   (emit *navigation-next-name*)
	   (unless last-page-p (emit (link-stop)))
	   (emit-verbatim "</span>")
	   ;
	   (emit *navigation-page-name*)
	   ;
	   (when (or toc-page index-page)
	     (emit-verbatim "<span")
	     (when (or (and toc-page-p (not index-page) (not index-page-p))
		       (and index-page-p (not toc-page) (not toc-page-p)))
	       (emit-verbatim " class=disable"))
	     (emit-verbatim ">; ")
	     (emit-nbsp 2)
	     (emit-verbatim "</span>")
	     ;
	     (when toc-page
	       (emit-verbatim "<span")
	       (when toc-page-p (emit-verbatim " class=disable"))
	       (emit-verbatim ">")
	       (unless toc-page-p
		 (emit (link-start (page-node-link
				     toc-page
                                     "TAG_troff2page_toc"))))
	       (emit *navigation-contents-name*)
	       (unless toc-page-p (emit (link-stop)))
	       (emit-verbatim "</span>"))
	     ;
	     (when index-page
	       (emit-verbatim "<span")
	       (when index-page-p (emit-verbatim " class=disable"))
	       (emit-verbatim ">")
	       (emit-verbatim "<span")
	       (unless (and toc-page (not toc-page-p))
		 (emit-verbatim " class=disable"))
	       (emit-verbatim ">")
	       (when toc-page
		 (emit-verbatim "; ")
		 (emit-nbsp 2))
	       (emit-verbatim "</span>")
	       (unless index-page-p
		 (emit (link-start (page-node-link
				     index-page
				     "TAG_troff2page_index"))))
	       (emit *navigation-index-name*)
	       (unless index-page-p (emit (link-stop)))
	       (emit-verbatim "</span>")))
	   (emit *navigation-sentence-end*)
	   (emit-verbatim "]")
	   ;(emit-newline)
	   (emit-verbatim "</i></div>")
	   ))))

(defun link-stylesheets ()
  (emit-verbatim "<link rel=\"stylesheet\" href=\"")
  (emit-verbatim *jobname*) (emit-verbatim *css-file-suffix*)
  (emit-verbatim "\" title=default>") (emit-newline)
  (dolist (css (nreverse *stylesheets*))
    (emit-verbatim "<link rel=\"stylesheet\" href=\"")
    (emit-verbatim css)
    (emit-verbatim "\" title=default>")
    (emit-newline)))

(defun emit-external-title ()
  (emit-verbatim "<title>")
  (emit-newline)
  (let ((*outputting-to* :title))
    (emit-verbatim (or *title* *jobname*)))
  (emit-newline)
  (emit-verbatim "</title>")
  (emit-newline))

#|
;let's not do this -- takes up time and not necessarily all that helpful

(defun emit-edit-source-doc (&key (interval 0))
  ;the first call for any file will always have interval=0,
  ;so it doesn't matter if *last-input-milestone* is corrupt
  ;when entering a file
  (when (or (= interval 0) (>= *input-line-no* (+ *last-input-milestone* interval)))
    (emit-verbatim "<!-- ")
    (emit-verbatim "edit +")
    (emit-verbatim *input-line-no*)
    (emit-verbatim " ")
    (emit-verbatim *current-source-file*)
    (emit-verbatim " -->")
    (setq *last-input-milestone* *input-line-no*)))
|#

(defun emit-html-preamble ()
  (emit-verbatim "<!DOCTYPE html>")
  (emit-newline)
  (let ((pageno *current-pageno*))
    (emit-verbatim "<html>")
    (emit-newline)
    (emit-verbatim "<!--")
    (emit-newline)
    (emit-verbatim "Generated from ")
    (emit-verbatim *main-troff-file*)
    (emit-verbatim " by troff2page, ")
    (emit-verbatim "v. ") (emit-verbatim *troff2page-version*)
    (emit-newline)
    (emit-verbatim *troff2page-copyright-notice*)
    (emit-newline)
    (emit-verbatim "(running on ")
    (emit-verbatim (lisp-implementation-type))
    (emit-verbatim " ")
    (emit-verbatim (lisp-implementation-version))
    (emit-verbatim ", ")
    (emit-verbatim (machine-type))
    (emit-verbatim ")")
    (emit-newline)
    (emit-verbatim *troff2page-website*)
    (emit-newline)
    (emit-verbatim "-->")
    (emit-newline)
    ;(emit-edit-source-doc)
    (emit-newline)
    (emit-verbatim "<head>")
    (emit-newline)
    (emit-verbatim "<meta charset=\"utf-8\">")
    (emit-newline)
    (emit-external-title)
    (link-stylesheets)
    (emit-verbatim "<meta name=robots content=\"index,follow\">")
    (emit-newline)
    (mapc #'emit-verbatim *html-head*)
    (emit-verbatim "</head>")
    (emit-newline)
    (emit-verbatim "<body>")
    (emit-newline)
    (emit-verbatim "<div id=")
    (emit-verbatim (if (= pageno 0) "title" "content"))
    (emit-verbatim ">")
    (emit-newline)))

(defun emit-html-postamble ()
  (emit-para)
  (emit-verbatim "</div>") (emit-newline)
  (emit-verbatim "</body>") (emit-newline)
  (emit-verbatim "</html>") (emit-newline))

;

(defun emit-blank-line ()
  (cond ((eq *outputting-to* :troff) (emit-newline))
        (*blank-line-macro*
          (setq *keep-newline-p* nil)
          (setq *previous-line-exec-p* t)
          (cond ((setq *it* (gethash *blank-line-macro* *macro-table*))
                 (execute-macro-body *it*))
                ((setq *it* (gethash *blank-line-macro* *request-table*))
                 (toss-back-char #\newline)
                 (funcall *it*))))
        (t (emit-verbatim "<P>")
           ;(emit-para)
           ;(emit-verbatim "&#xa0;<br>")
           (emit-newline))))

(defun emit-leading-spaces (num-leading-spaces &key insert-line-break-p)
  (when (> num-leading-spaces 0)
    (setq *leading-spaces-number* num-leading-spaces)
    (cond (*leading-spaces-macro*
            (cond ((setq *it* (gethash *leading-spaces-macro* *macro-table*))
                   (execute-macro-body *it*))
                  ((setq *it* (gethash *leading-spaces-macro* *request-table*))
                   (funcall *it*))))
          (t (when insert-line-break-p
               (emit-verbatim "<!---***---><Br>"))
             (dotimes (i *leading-spaces-number*)
               (emit "\\[htmlnbsp]"))))))

(defun do-afterpar ()
  (when (setq *it* *afterpar*)
    (setq *afterpar* nil)
    (funcall *it*)))

(defun emit-para (&key parstartp indentp)
  (do-afterpar)
  (setq *margin-left* 0)
  (when (setq *it* (gethash "par@reset" *request-table*))
    (funcall *it*))
  (emit (switch-style :font nil :color nil :bgcolor nil :size nil))
  (fill-mode)
  ;(emit-newline)
  (emit-verbatim "<p")
  (when indentp
    (emit-verbatim " class=indent"))
  (emit-verbatim ">")
  (setq *just-after-par-start-p* parstartp)
  ;(emit-edit-source-doc :interval 10)
  (emit-newline))

(defun ensure-file-deleted (f)
  (if (probe-file f) (delete-file f)))

(defun emit-start ()
  (let ((html-page-count (incf *current-pageno*)))
    (when (and (= html-page-count 1) (= *last-page-number* -1))
      (flag-missing-piece :last-page-number))
    (when (eql *macro-package* :ms)
      (setf (counter*-value (get-counter-named "PN")) html-page-count))
    (setq *html-page*
	  (concatenate 'string
		       *jobname*
		       (if (= html-page-count 0) ""
			 (concatenate 'string *html-page-suffix*
				      (write-to-string html-page-count)))
		       *output-extension*))
    (setq *out* (open *html-page* :direction :output
		      :if-exists :supersede))
    (emit-html-preamble)
    (emit-navigation-bar :headerp t)
    (emit-para)))

(defun get-counter-named (name)
  (or (gethash name *numreg-table*)
      (setf (gethash name *numreg-table*) (make-counter*))))

(defun increment-section-counter (lvl)
  (when lvl
    (let* ((h-lvl (concatenate 'string "H" (write-to-string lvl)))
           (c-lvl (get-counter-named h-lvl)))
      (incf (counter*-value c-lvl))
      (loop
        (incf lvl)
        (setq c-lvl (gethash (concatenate 'string "H" (write-to-string lvl)) *numreg-table*))
        (when (not c-lvl) (return))
        (setf (counter*-value c-lvl) 0)))))

(defun section-counter-value ()
  (let ((lvl (raw-counter-value "nh*hl")))
    (and (> lvl 0)
         (let ((r (formatted-counter-value "H1"))
               (i 2))
           (loop
             (if (> i lvl) (return r))
             (setq r
                   (concatenate 'string r "."
                     (formatted-counter-value
                       (concatenate 'string "H" (write-to-string i)))))
             (incf i))))))

(defun gen-temp-string () ;doesn't CL have a prim for this
  (concatenate 'string "Temp_"
    (write-to-string (incf *temp-string-count*))))

(defun get-header (k &key man-header-p)
  (if (not man-header-p)
    (let ((old-*out* *out*)
          (o (make-string-output-stream)))
      (setq *out* o)
      (setq *afterpar*
            (lambda ()
              (setq *out* old-*out*)
              (funcall k (string-trim-blanks (get-output-stream-string o))))))
    (funcall k
             (with-output-to-string (o)
               (let ((*out* o)
                     (*exit-status* nil)
                     (firstp t))
                 (loop
                   (let ((w (read-word)))
                     (cond ((not w) (read-troff-line) (return))
                           (t (if firstp (setq firstp nil) (emit " "))
                              (emit (expand-args w)))))))))))

(defun emit-section-header (level &key numberedp man-header-p)
  (let* ((this-section-no nil)
         (growps (raw-counter-value "GROWPS")))
    (emit-para)
    (when numberedp
      (setf (counter*-value (get-counter-named "nh*hl")) level)
      (increment-section-counter level)
      (setq this-section-no (section-counter-value))
      (setf (gethash "SN-NO-DOT" *string-table*)
            (lambda () this-section-no))
      (let ((this-section-no-dot
              (concatenate 'string this-section-no ".")))
        (setf (gethash "SN-DOT" *string-table*) (lambda () this-section-no-dot)
              (gethash "SN" *string-table*) (lambda () this-section-no-dot)))) ; without dot?
    (ignore-spaces)
    ;(emit-edit-source-doc)
    (get-header
      (lambda (header)
        (let ((hnum (write-to-string (max 1 (min 6 level)))))
          (emit-verbatim "<h")
          (emit hnum)
          (when (eq *macro-package* :man)
            (emit-verbatim
             (case level
               (1 " class=sh")
               (2 " class=ss")
               (t ""))))
	  (let ((psincr-per-level (raw-counter-value "PSINCR"))
            (ps 10))
	    (when (> psincr-per-level 0)
          (when (< level growps)
            (setq ps (raw-counter-value "PS"))
            (emit-verbatim " style=\"font-size: ")
            (emit-verbatim (floor
                             (* 100 (/ (+ ps (* (- growps level) psincr-per-level))
                                       ps))))
            (emit-verbatim "%\""))))
          (emit-verbatim ">")
          (when this-section-no
            (emit this-section-no) (emit-verbatim ".") (emit-nbsp 2))
          (emit-verbatim header)
          (emit-verbatim "</h")
          (emit hnum)
          (emit-verbatim ">")
          (emit-newline)
          ;(emit-para)
          ))
      :man-header-p man-header-p)))

(defun emit-end-page ()
  (emit-footnotes)
  (emit-navigation-bar)
  (when (= *current-pageno* 0)
    (emit-colophon)
    (collect-css-info-from-preamble))
  (emit-html-postamble)
  (close *out*))

(defun collect-css-info-from-preamble ()
  (let ((ps (raw-counter-value "PS"))
	(p-i (raw-counter-value "PI"))
	(pd (raw-counter-value "PD"))
	(ll (raw-counter-value "LL"))
	(html1 (raw-counter-value "HTML1")))
    (unless (= ps 10)
      (format *css-port* "~&body { font-size: ~a%; }~%" (* ps 10)))
    (unless (= ll 0)
      (format *css-port* "~%body { max-width: ~apx; }~%" ll))
    (unless (eq *macro-package* :man)
      (unless (= p-i 0)
        (format *css-port* "~&p.indent { text-indent: ~apx; }~%" p-i))
      (unless (< pd 0)
        (let ((p-margin pd) ; not pd/2
              (display-margin (* pd 2))
              ;(h-margin (* pd 2))
              (fnote-rule-margin (* pd 2))
              (navbar-margin (* ps 2))) ;2*pd can be too small
          (format *css-port* "~&p { margin-top: ~apx; margin-bottom: ~apx; }~%"
                  p-margin p-margin)
          (format *css-port* "~&.display { margin-top: ~apx; margin-bottom: ~apx; }~%"
                  display-margin display-margin)
          '(format *css-port* "~&h1,h2,h3,h4,h5,h6 { margin-bottom: ~apx; }~%"
                   h-margin)
          (format *css-port* "~&.footnote { margin-top: ~apx; }~%"
                  fnote-rule-margin)
          (format *css-port* "~&.navigation { margin-top: ~apx; margin-bottom: ~apx; }~%"
                  navbar-margin navbar-margin)
          (format *css-port* "~&.colophon { margin-top: ~apx; margin-bottom: ~apx; }~%"
                  display-margin display-margin)
          )))
    (unless (= html1 0)
      ;browsers can't deal with these CSS3 features yet
      (format *css-port* "~&@media print {~%")
      (format *css-port* "~&a.hrefinternal::after { content: target-counter(attr(href), page); }~%")
      (format *css-port* "~&a.hrefinternal .hreftext { display: none; }~%")
      (format *css-port* "~&}~%")
      )
    ))

(defun emit-colophon ()
    (emit-para)
    (emit-verbatim "<div align=right class=colophon>")
    (emit-newline)
    (when (setq *it* (gethash "DY" *string-table*))
      (emit *last-modified*)
      (emit (funcall *it*)) (emit-verbatim "<br>")
      (emit-newline))
    (unless
      nil
      ;(eql *macro-package* :man) ;no colophon for man pages
      (= *last-page-number* 0) ;no col. for 1-page docs
      (emit-verbatim "<div align=right class=advertisement>")
      (emit-newline)
      (emit-verbatim *html-conversion-by*)
      (emit-verbatim " ")
      (emit (link-start *troff2page-website*))
      (emit-verbatim "troff2page ")
      (emit-verbatim *troff2page-version*)
      (emit (link-stop))
      (emit-newline)
      (emit-verbatim "</div>")
      (emit-newline))
    (emit-verbatim "</div>")
    (emit-newline)
    )

(defun write-aux (e)
  (prin1 e *aux-port*)
  (terpri *aux-port*))

(defun do-end-macro ()
  (when (and *end-macro*
             (setq *it* (gethash *end-macro* *macro-table*)))
    (troff2page-lines *it*)))

(defun do-bye ()
  (let ((*blank-line-macro* nil))
    (emit-blank-line))
  (do-end-macro)
  (let ((pageno *current-pageno*))
    (!last-page-number pageno)
    (write-aux `(!last-page-number ,pageno)))
  (emit-end-page)
  (when *verbatim-apostrophe-p* (write-aux `(!verbatim-apostrophe)))
  (write-aux `(!macro-package ,*macro-package*))
  (when *title* (write-aux `(!title ,*title*)))
  (when (= *last-page-number* 0)
    ;remove unsightly placeholder vert space for header navbar
    (format *css-port* "~&.navigation { display: none; }~%"))
  (clear-per-doc-hash-tables)
  (close-all-open-ports)
  (when *missing-pieces*
    (format t "Missing: ~a~%" *missing-pieces*)
    (format t "Rerun: troff2page ~a~%" *main-troff-file*)))

(defun !macro-package (m)
  (setq *macro-package* m))

(defun !last-page-number (n)
  (setq *last-page-number* n))

(defun !node (node pageno tag-value)
  (setf (gethash node *node-table*) pageno)
  (defstring node
    (lambda ()
      (concatenate 'string
        (link-start
          (page-node-link pageno node))
        (verbatim tag-value)
        (link-stop)))))

(defun !header (s)  ;will it show in reverse
  (push s *html-head*))

(defun !verbatim-apostrophe ()
  (setq *verbatim-apostrophe-p* t))

(defun !title (title)
  (setq *title* title))

(defun !stylesheet (css)
  (push css *stylesheets*))

(defun store-title (title &key preferredp emitp)
  (cond (preferredp
          (when (or (not *title*)
                    (not (string= *title* title)))
            (flag-missing-piece :title))
          (setq *title* title))
        (t (unless *title*
             (flag-missing-piece :title))
           (setq *title* title)))
  (when emitp
    (emit-verbatim "<h1 align=center class=title>")
    (emit title)
    (emit-verbatim "</h1>")
    (emit-newline) ;necessary?
    ))

(defun clear-per-doc-hash-tables ()
  ;shouldn't be necessary
  ;but i'm getting stack overflow *between* two calls to
  ;troff2page at the repl -- don't know why
  (clrhash *color-table*)
  (clrhash *diversion-table*)
  (clrhash *ev-table*)
  (clrhash *glyph-table*)
  (clrhash *macro-table*)
  (clrhash *node-table*)
  (clrhash *numreg-table*)
  (clrhash *string-table*)
  )

(defun close-all-open-ports ()
  (when *aux-port* (close *aux-port*))
  (when *css-port* (close *css-port*))
  (dolist (c *output-streams*)
    (close (cdr c))))

(defun do-eject ()
  (let ((page-break-p t))
    (cond ((= *last-page-number* 0) (setq page-break-p nil))
	  ((/= (raw-counter-value "HTML1") 0)
	   (setq *last-page-number* 0) (setq page-break-p nil)))
    (cond (page-break-p (emit-end-page)
			(emit-start))
	  (t (emit-verbatim "<div class=pagebreak></div>")
	     (emit-newline)))))

(defun execute-macro-body (ss)
  (let ((*macro-spill-over* nil))
    (let ((*current-troff-input* (make-bport*))
          (i (- (length ss) 1)))
      (loop (when (< i 0) (return))
            (toss-back-line (elt ss i))
            (decf i))
      (generate-html '(:nx :ex)))
    (when *macro-spill-over*
      (toss-back-line *macro-spill-over*))))

(defun read-macro-name ()
  (get-char) ;eat the control char
  (expand-args (read-word)))

(defun execute-macro (w)
  (cond ((not w)
         nil)
        ((setq *it* (gethash w *diversion-table*))
         (read-troff-line)
         (princ (get-output-stream-string (diversion*-port *it*)) *out*))
        ((setq *it* (gethash w *macro-table*))
         (let* ((mac *it*)
                (args (read-args))
                (*macro-args* (cons w args)))
           (execute-macro-body mac)))
        ((setq *it* (gethash w *string-table*))
         (let ((str *it*))
           (read-troff-line)
           (toss-back-string (funcall str))))
        ((setq *it* (gethash w *request-table*))
         (funcall *it*))
        (t
          (read-troff-line))))

(defun generate-html (percolatable-status-values)
  (let ((returned-status-value
          (let ((*exit-status* nil))
            (loop
              (when *exit-status* (return *exit-status*))
              (process-line)))))
    (when (member returned-status-value percolatable-status-values)
      (setq *exit-status* returned-status-value))))

(defun process-line ()
  (let* ((c (snoop-char))
         (*keep-newline-p* t))
    (cond ((not c) (setq *keep-newline-p* nil)
                   (setq *exit-status* :done))
          ((and (or (char= c *control-char*)
                    (char= c *no-break-control-char*))
                (not *macro-copy-mode-p*)
                (not *sourcing-ascii-file-p*)
                (setq *it* (read-macro-name)))
           (setq *keep-newline-p* nil)
           (unless (eq *it* t)
             (execute-macro *it*)
             (setq *previous-line-exec-p* t)))
          (t (emit-expanded-line)
             (setq *previous-line-exec-p* nil)))
    ;ugly centering code
    (when (and (or (not (fillp))
                   (> *lines-to-be-centered* 0))
               (not *macro-copy-mode-p*)
               (eq *outputting-to* :html)
               *keep-newline-p*
               (not *previous-line-exec-p*))
      (emit-verbatim "<Br>"))
    (when (and *keep-newline-p* (> *lines-to-be-centered* 0))
      (decf *lines-to-be-centered*)
      (when (= *lines-to-be-centered* 0)
        (emit-verbatim "</div>")))
    (when *keep-newline-p* (emit-newline))))

(defun troff2page-lines (ss)
  (let ((*current-troff-input* (make-bport*)))
    (dolist (s ss) (toss-back-line s))
    (generate-html '(:return :nx :ex))))

(defun troff2page-chars (cc)
  (let ((*current-troff-input* (make-bport* :buffer cc)))
    (generate-html '(:return :nx :ex))))

(defun troff2page-string (s)
  (let ((*current-troff-input* (make-bport*)))
    (toss-back-string s)
    (generate-html '(:return :nx :ex))))

(defun troff2page-line (s)
  (let ((*current-troff-input* (make-bport*)))
    (toss-back-line s)
    (generate-html '(:return :nx :ex))))

(defun troff2page-file (f)
  (cond ((or (not f) (not (probe-file f)))
         (twarning "can't open `~a': No such file or directory" f)
         ;(twarning 'ignoring-file f)
	 (flag-missing-piece f))
        (t (with-open-file (i f :direction :input)
             (let* ((*current-troff-input* (make-bport* :port i))
                    (*input-line-no* 1)
                    (*current-source-file* f))
               ;(emit-edit-source-doc)
               (generate-html '(:ex))))
           ;(emit-edit-source-doc)
	   )))

(defun troff2page-help (f)
  (let ((situation (cond ((or (not f)
                              (string= f "")) :no-arg)
                         ((probe-file f) nil)
                         ((or (string= f "--help")
                              (string= f "-h")) :help)
                         ((string= f "--version") :version)
                         (t :file-not-found))))
    (prog1 situation
      (case situation
        (:no-arg (format t "troff2page called with no argument~%"))
        (:file-not-found (format t "troff2page could not find file ~s~%" f))
        ((:help :version)
         (format t "troff2page version ~a~%" *troff2page-version*)
         (format t "~a~%" *troff2page-copyright-notice*)
         (when (eq situation :help)
           (format t "For full details, please see ~a~%" *troff2page-website*)))))))

(defun read-args ()
  (let ((ln (expand-args (read-troff-line)))
        (r '()))
    (toss-back-line ln)
    (loop
      (ignore-spaces)
      (let ((c (snoop-char)))
        (when (or (not c) (char= c #\newline))
          (get-char)
          (return (nreverse r)))
        (push  (read-word) r)))))

(defun start-css-file ()
  (let ((css-file (concatenate 'string *jobname* *css-file-suffix*)))
    (setq *css-port* (open css-file :direction :output
                           :if-exists :supersede))
    (princ "
           body {
           /* color: black;
           background-color: #ffffff; */
           margin-top: 2em;
	   margin-bottom: 2em;
           }

           /*
           p.noindent {
           text-indent: 0;
           }
           */

           .title {
           font-size: 200%;
           /* font-weight: normal; */
           margin-top: 2.8em;
           text-align: center;
           }

           .dropcap {
           line-height: 80%; /* was 90 */
           font-size: 410%;  /* was 400 */
           float: left;
           padding-right: 5px;
           }

           pre {
           margin-left: 2em;
           }

           blockquote {
           margin-left: 2em;
           }

           ol {
           list-style-type: decimal;
           }

           ol ol {
           list-style-type: lower-alpha;
           }

           ol ol ol {
           list-style-type: lower-roman;
           }

           ol ol ol ol {
           list-style-type: upper-alpha;
           }

           tt i {
           font-family: serif;
           }

           .verbatim em {
           font-family: serif;
           }

           .troffbox {
           background-color: lightgray;
           }

           .navigation {
           color: #72010f; /* venetian red */
           text-align: right;
           font-size: medium;
           font-style: italic;
           }

           .disable {
           color: gray;
           }

           .footnote hr {
           text-align: left;
           width: 40%;
           }

           .colophon {
           color: gray;
           font-size: 80%;
           font-style: italic;
           text-align: right;
           }

           .colophon a {
           color: gray;
           }

           @media screen {

           body {
           margin-left: 8%;
           margin-right: 8%;
           }

           /*
           this ruins paragraph spacing on Firefox -- don't know why
           a {
           padding-left: 2px; padding-right: 2px;
           }

           a:hover {
           padding-left: 1px; padding-right: 1px;
           border: 1px solid #000000;
           }
           */

           } /* media screen */

           @media print {

           body {
           text-align: justify;
           }

           a:link, a:visited {
           text-decoration: none;
           color: black;
           }

           /*
           p {
           margin-top: 1ex;
           margin-bottom: 0;
           }
           */

	   .pagebreak {
	   page-break-after: always;
	   }

           .navigation {
           display: none;
           }

           .colophon .advertisement {
           display: none;
           }

           } /* media print */
           "
           *css-port*)))

(defun initialize-glyph-number-and-string-registers ()
  ;
  (defglyph "htmllt" "\\[htmllt]")
  (defglyph "htmlgt" "\\[htmlgt]")
  (defglyph "htmlquot" "\\[htmlquot]")
  (defglyph "htmlamp" "\\[htmlamp]")
  (defglyph "htmlbackslash" "\\[htmlbackslash]")
  (defglyph "htmlspace" "\\[htmlspace]")
  ;
  (dotimes (i (length *standard-glyphs*))
    (when (evenp i)
      (defglyph (elt *standard-glyphs* i)
        (verbatim
          (concatenate 'string "&#x"
            (write-to-string (elt *standard-glyphs* (1+ i)) :base 16)
            ";")))))
  ;
  (defnumreg ".F" (make-counter* :format "s"
                                 :thunk (lambda () *current-source-file*)))
  (defnumreg ".z" (make-counter* :format "s"
                                 :thunk (lambda () *current-diversion*)))
  (defnumreg "%" (make-counter* :thunk (lambda () *current-pageno*)))
  (defnumreg ".$" (make-counter* :thunk
                                 (lambda () (- (length *macro-args*) 1))))
  (defnumreg ".c" (make-counter* :thunk (lambda () *input-line-no*)))
  (defnumreg "c." (make-counter* :thunk (lambda () *input-line-no*)))
  (defnumreg ".i" (make-counter* :thunk (lambda () *margin-left*)))
  (defnumreg ".u" (make-counter* :thunk
                                 (lambda ()
                                   (if (ev*-fill (car *ev-stack*)) 1 0))))
  (defnumreg ".ce" (make-counter* :thunk (lambda () *lines-to-be-centered*)))
  ;current-time -related registers
  (multiple-value-bind (seconds minutes hours dy mo year dw dst tz)
    (get-decoded-time)
    (declare (ignore dst tz))
    (incf dw 2) (when (> dw 7) (decf dw 7))
    (defnumreg "seconds" (make-counter* :value seconds))
    (defnumreg "minutes" (make-counter* :value minutes))
    (defnumreg "hours" (make-counter* :value hours))
    (defnumreg "dw" (make-counter* :value dw))
    (defnumreg "dy" (make-counter* :value dy))
    (defnumreg "mo" (make-counter* :value mo))
    (defnumreg "year" (make-counter* :value year))
    (defnumreg "yr" (make-counter* :value (- year 1900))))
  ;
  (defnumreg "$$" (make-counter* :value (retrieve-pid)))
  (defnumreg ".g" (make-counter* :value 1))
  (defnumreg ".U" (make-counter* :value 1))
  (defnumreg ".troff2page" (make-counter* :value *troff2page-version*))
  (defnumreg "systat" (make-counter* :value 0))
  (defnumreg "www:HX" (make-counter* :value -1))
  (defnumreg "GROWPS" (make-counter* :value 1))
  (defnumreg "PS" (make-counter* :value 10))
  (defnumreg "PSINCR" (make-counter* :value 0))
  (defnumreg "PI" (make-counter* :value (* 5 (point-equivalent-of #\n))))
  (defnumreg "DI" (make-counter* :value (raw-counter-value "PI")))
  (defnumreg "PD" (make-counter* :value (* .3 (point-equivalent-of #\v))))
  ;(defnumreg "LL" (make-counter* :value (* 6.5 (point-equivalent-of #\i))))
  (defnumreg "lsn" (make-counter* :thunk (lambda () *leading-spaces-number*)))
  (defnumreg "lss" (make-counter* :thunk (lambda ()  (* *leading-spaces-number* (point-equivalent-of #\n)))))
  ;
  ;
  (defstring ".T" (lambda () "webpage"))
  (defstring "-" (lambda () (verbatim "&#x2014;")))
  ;
  (defstring "{" (lambda () (verbatim "<sup>")))
  (defstring "}" (lambda () (verbatim "</sup>")))
  ;
  (defstring "AUXF"
    (lambda () (verbatim (concatenate 'string ".troff2page_temp_" *jobname*))))
  ;
  (defstring "*"
    (lambda ()
      (setq *this-footnote-is-numbered-p* t)
      (incf *footnote-count*)
      (let ((n (write-to-string *footnote-count*)))
        (concatenate 'string
          (anchor (concatenate 'string *html-node-prefix*
                    "call_footnote_" n))
          (link-start (page-node-link
			nil (concatenate 'string *html-node-prefix* "footnote_" n)))
          (verbatim "<sup><small>")
          (verbatim n)
          (verbatim "</small></sup>")
          (link-stop)))))
  ;
  (defstring ":" #'man-url)
  (defstring "url" #'url-string-value)
  (defstring "urlh" #'urlh-string-value)
  ;
  )

(defun load-aux-file ()
  (initialize-glyph-number-and-string-registers)
  ;
  (setq *pso-temp-file* (concatenate 'string *jobname* *pso-file-suffix*))
  (let ((aux-file (concatenate 'string *jobname* *aux-file-suffix*)))
    (when (probe-file aux-file)
      (load-troff2page-data-file aux-file)
      (delete-file aux-file))
    (when *html-head* (setq *html-head* (nreverse *html-head*)))
    (setq *aux-port* (open aux-file :direction :output)))
  (start-css-file))

(defun next-html-image-file-stem ()
  (incf *image-file-count*)
  (concatenate 'string *jobname* *image-file-suffix*
               (write-to-string *image-file-count*)))

(defun call-with-image-port (p)
  (let* ((img-file-stem (next-html-image-file-stem))
         (aux-file (concatenate 'string img-file-stem ".troff")))
    (with-open-file (o aux-file :direction :output
                       :if-exists :supersede)
      (funcall p o))
    (cond (*nroff-image-p*
            (troff-to-ascii img-file-stem)
            (source-ascii-file img-file-stem))
          (t (troff-to-image img-file-stem)
             (source-image-file img-file-stem)))))

(defun ps-to-image/png (f)
  (os-execute
    (concatenate 'string *ghostscript* *ghostscript-options* " -sOutputFile=" f ".ppm.1 "
      f ".ps quit.ps"))
  (os-execute
    (concatenate 'string "pnmcrop " f ".ppm.1 > " f ".ppm.tmp"))
  ;(os-execute
  ;   (concatenate 'string "ppmquant 256 < " f ".ppm.tmp > " f ".ppm"))
  (os-execute
    (concatenate 'string "pnmtopng -interlace -transparent \"nilFFFFF\" "
      " < " f ".ppm.tmp > " f ".png"))
  (dolist (e '(".ppm.1" ".ppm.tmp" ".ppm"))
    (ensure-file-deleted (concatenate 'string f e))))

(defun ps-to-image/gif (f)
    (os-execute
      (concatenate 'string *ghostscript* *ghostscript-options*
                     " -sOutputFile=" f ".ppm.1 "
                     f ".ps quit.ps"))
    (os-execute
      (concatenate 'string "pnmcrop " f ".ppm.1 > " f ".ppm.tmp"))
    (os-execute
      (concatenate 'string "ppmquant 256 < " f ".ppm.tmp > " f ".ppm"))
    (os-execute
      (concatenate 'string "ppmtogif -transparent rgb:ff/ff/ff < "
                     f ".ppm > " f ".gif")))

(defun source-image-file (f)
    (emit-verbatim "<img src=\"")
    (emit-verbatim f)
    (emit-verbatim ".gif\" border=\"0\" alt=\"[")
    (emit-verbatim f)
    (emit-verbatim ".gif]\">"))

(defun source-ascii-file (f)
    (let ((f.ascii (concatenate 'string f ".ascii")))
      (start-display "I")
      (emit (switch-font "C"))
      (let ((*turn-off-escape-char-p* t)
                  (*sourcing-ascii-file-p* t))
        (troff2page-file f.ascii))
      (stop-display)
      ))

(defun troff-to-image (f)
  (let ((f.img (concatenate 'string f ".gif")))
    (unless (probe-file f.img)
      (os-execute
       (concatenate 'string
                    "groff -pte -ms -Tps "
                    *groff-image-options*
                    " " f ".troff > " f ".ps"))
      (ps-to-image/gif f))))

(defun troff-to-ascii (f)
  (let ((f.ascii (concatenate 'string f ".ascii")))
    (unless nil ;(probe-file f.ascii)
      (os-execute
        (concatenate 'string
          "groff -pte -ms -Tascii " f ".troff > " f.ascii)))))

(defun make-image (env endenv)
  (let ((i (bport*-port *current-troff-input*)))
    (call-with-image-port
     (lambda (o)
       (princ env o) (terpri o)
       (loop
         (let* ((x (read-line i))
                (j (search endenv x)))
           (when (and j (= j 0)) (return))
           (princ x o) (terpri o)))
       (princ endenv o) (terpri o)))))

(defun emit-footnotes ()
  (when *footnote-buffer*
    (emit-para)
    (emit-verbatim "<div class=footnote><hr align=left width=\"40%\">")
    (dolist (fn (nreverse *footnote-buffer*))
      (emit-para)
      (let ((fntag (footnote*-tag fn))
            (fno (footnote*-number fn))
            (fnc (footnote*-text fn)))
        (cond (fntag (troff2page-line fntag))
              (fno
                (let ((fno-str (write-to-string fno)))
                  (let ((node-name
                          (concatenate 'string *html-node-prefix*
                            "footnote_" fno-str)))
                    (emit (anchor node-name)))
                  (emit (link-start (page-node-link
				      nil (concatenate 'string
						       *html-node-prefix* "call_footnote_"
						       fno-str))))
                  (emit-verbatim "<sup><small>")
                  (emit-verbatim fno-str)
                  (emit-verbatim "</small></sup>")
                  (emit (link-stop))
                  (emit-newline))))
        (troff2page-chars fnc)))
    (emit-verbatim "</div>")
    (emit-newline)
    (setq *footnote-buffer* '())))

(defun read-escaped-word ()
  (let ((c (get-char)))
    (case c
      (#\[ (read-till-char #\] :eat-delim-p t))
      (#\( (let* ((c1 (get-char)) (c2 (get-char)))
                (s-string c1 c2)))
      (t (string c)))))

(defun read-troff-string-args ()
  (let ((c (get-char)))
    (case c
      (#\( (let* ((c1 (get-char)) (c2 (get-char)))
             (list (s-string c1 c2))))
      (#\[ (let* ((*reading-string-call-p* t)
                  (r (list (expand-args (read-word))))) ;or read-bare-word?
             (loop
               (ignore-spaces)
               (let ((c (snoop-char)))
                 (cond ((not c) (terror "read-troff-string-args: string too long"))
                       ((char= c #\newline) (get-char))
                       ((char= c #\]) (get-char) (return))
                       (t (push (expand-args (read-word)) r)))))
             (nreverse r)))
      (t (list (string c))))))

(defun read-opt-sign ()
  (ignore-spaces)
  (let ((c (snoop-char)))
    (cond ((not c) nil)
          ((member c '(#\+ #\-)) (get-char))
          (t nil))))

(defun read-opt-pipe ()
  (ignore-spaces)
  (let ((c (snoop-char)))
    (cond ((not c) nil)
          ((char= c #\|) (get-char))
          (t nil))))

(defun switch-style (&key font color bgcolor size)
  (let* ((ev-curr (car *ev-stack*))
	 (new-font font)
	 (new-color color)
	 (new-bgcolor bgcolor)
	 (new-size size)
	 (revert-font (ev*-prevfont ev-curr))
	 (revert-color (ev*-prevcolor ev-curr))
	 (revert-bgcolor (ev*-prevbgcolor ev-curr))
	 (revert-size (ev*-prevsize ev-curr)) ;?
	 (curr-font (ev*-font ev-curr))
	 (curr-color (ev*-color ev-curr))
	 (curr-bgcolor (ev*-bgcolor ev-curr))
	 (curr-size (ev*-size ev-curr))
	 (r "")
	 (open-new-span-p (or font color bgcolor size)))
    (when (or curr-font curr-color curr-bgcolor curr-size)
      (setq r (concatenate 'string (verbatim "</span>"))))
    (case new-font
      (:previous (setf new-font revert-font
		       (ev*-prevfont ev-curr) nil))
      ((nil) (when open-new-span-p (setf new-font curr-font)))
      (t (setf (ev*-prevfont ev-curr) curr-font)))
    (case new-color
      (:previous (setf new-color revert-color
		       (ev*-prevcolor ev-curr) nil))
      ((nil) (when open-new-span-p (setq new-color curr-color)))
      (t (setf (ev*-prevcolor ev-curr) curr-color)))
    (case new-bgcolor
      (:previous (setf new-bgcolor revert-bgcolor
		       (ev*-prevbgcolor ev-curr) nil))
      ((nil) (when open-new-span-p (setq new-bgcolor curr-bgcolor)))
      (t (setf (ev*-prevbgcolor ev-curr) curr-bgcolor)))
    (case new-size
      (:previous (setf new-size revert-size
		       (ev*-prevsize ev-curr) nil))
      ((nil) (when open-new-span-p (setq new-size curr-size)))
      (t (setf (ev*-prevsize ev-curr) curr-size)))
    (setf (ev*-font ev-curr) new-font
	  (ev*-color ev-curr) new-color
	  (ev*-bgcolor ev-curr) new-bgcolor
	  (ev*-size ev-curr) new-size)
    (unless open-new-span-p
      (setf (ev*-prevfont ev-curr) nil
	    (ev*-prevcolor ev-curr) nil
	    (ev*-prevbgcolor ev-curr) nil
	    (ev*-prevsize ev-curr) nil))
    (when open-new-span-p
      (setq r (concatenate 'string r
			   (make-span-open :font new-font
					   :color new-color
					   :bgcolor new-bgcolor
					   :size new-size))))
    r))

(defun make-span-open (&key font color bgcolor size)
  (cond ((not (or font color bgcolor size))
         ;dead code?
         "")
        (t (concatenate 'string
             (verbatim "<span style=\"")
             (when font (concatenate 'string (verbatim font)
                          (verbatim "; ")))
             (when color (concatenate 'string (verbatim color)
                           (verbatim "; ")))
             (when bgcolor (concatenate 'string (verbatim bgcolor)
                           (verbatim "; ")))
             (when size (concatenate 'string (verbatim size)))
             (verbatim "\">")))))

(defun switch-font (f)
  (setq f
        (cond ((not f) f)
              ((string= f "I") "font-style: italic")
              ((string= f "B") "font-weight: bold")
              ((member f '("C" "CR" "CW") :test #'string=) "font-family: monospace")
              ((string= f "CB") "font-weight: bold; font-family: monospace")
              ((string= f "CI") "font-style: oblique; font-family: monospace")
              ((string= f "P") :previous)
              (t nil)))
  (switch-style :font f))

(defun switch-font-family (f)
  (setq f
        (cond ((not f) f)
              ((string= f "C") "font-family: monospace")
              (t nil)))
  (switch-style :font f))

(defun switch-glyph-color (c)
  (cond ((not c))
        ((string= c "") (setq c :previous))
        ((setq *it* (gethash c *color-table*))
         (setq c *it*)))
  (when (stringp c)
    (setq c (concatenate 'string "color: " c)))
  (switch-style :color c))

(defun switch-fill-color (c)
  (cond ((not c))
        ((string= c "") (setq c :previous))
        ((setq *it* (gethash c *color-table*))
         (setq c *it*)))
  (when (stringp c)
    (setq c (concatenate 'string "background-color: " c)))
  (switch-style :bgcolor c))

(defun switch-size (n)
  (setq n
	(cond ((not n) n)
	      ((string= n "0") :previous)
	      (t
		(case (char n 0)
		  (#\+ (setq n (subseq n 1))
		   (let ((m (read-from-string n)))
		     (setq n  (* 100 (+ 1 (/ m 10))))))
		  (#\- (setq n (subseq n 1))
		   (let ((m (read-from-string n)))
		     (setq n  (* 100 (- 1 (/ m 10))))))
		  (t (let ((m (read-from-string n)))
		       (setq n (* 10 m)))))
		(setq n (round n))
		(when (= n 100) (setq n nil))
		(when n
		  (setq n (concatenate 'string "font-size: "
				       (write-to-string n)
				       "%"))))))
  (switch-style :size n))

(defun ms-font-macro (f)
  (let* ((args (read-args))
         (w (car args))
         (post (cadr args))
         (pre (caddr args)))
    (when pre (emit pre))
    (emit (switch-font f))
    (when w
      (emit w)
      (emit (switch-font nil))
      (when post (emit post))
      (emit-newline))))

(defun man-alternating-font-macro (f1 f2)
  (let ((first-font-p t))
    (loop (let ((arg (read-word)))
            (when (not arg) (return))
            (emit (switch-font (if first-font-p f1 f2)))
            (emit (expand-args arg))
            (emit (switch-font nil))
            (setf first-font-p (not first-font-p))))
    (read-troff-line)
    (emit-newline)))

(defun man-font-macro (f)
  (ignore-spaces)
  (let ((e (read-troff-line)))
    (when (string= e "")
      (setq e (read-troff-line)))
    (emit (switch-font f))
    (emit (expand-args e))
    (emit (switch-font nil))
    (emit-newline)))

(defun font-macro (f)
  (case *macro-package*
    (:man (man-font-macro f))
    (t (ms-font-macro f))))

(defun troff-align-to-html (i)
  (when (not i) (setq i "I"))
  (cond ((string= i "C") "center")
        ((string= i "B") "block")
        ((string= i "R") "right")
        ((string= i "L") "left")
        (t "indent")))

(defun start-display (w)
    (setq w (troff-align-to-html w))
    (read-troff-line)
    (emit-para)
    (emit-verbatim "<div class=display align=")
    (emit-verbatim
      (cond ((string= w "block") "center")
            ((string= w "indent") "left")
            (t w)))
    (when (string= w "indent")
      (emit-verbatim " style=\"margin-left: ")
      (emit-verbatim (raw-counter-value "DI"))
      (emit-verbatim "px;\"")
      )
    (emit-verbatim ">")
    ;(emit-edit-source-doc)
    (emit-newline)
    ;
    ;(emit-verbatim "<table")
;    (unless (string= w "block")
;      (emit-verbatim " align=")
;      (emit-verbatim
;        (cond ((string= w "indent") "left")
;              (t w))))
    ;(emit-verbatim ">")
    ;
;    (emit-verbatim "<tr>")
;    (when (string= w "indent")
;      (emit-verbatim "<td class=princindent>&#xa0;</td>")
;      (emit-newline))
;    ;
;    (emit-verbatim "<td align=")
;    (emit-verbatim
;      (cond ((string= w "block") "left")
;            ((string= w "indent") "left")
;            (t w)))
;    (emit-verbatim ">")
    (ev-push "display_environment")
    (unfill-mode)
    ;(setf (ev*-fill (car *ev-stack*)) nil)
    )

(defun stop-display ()
  (emit (switch-style))
  (ev-pop)
  ;(set!ev*-fill (car *ev-stack*) t)
  ;(emit-verbatim "</td></tr></table>")
  (emit-newline)
  (emit-verbatim "</div>")
  ;(emit-edit-source-doc)
  (emit-newline)
  (emit-para))

(defun number-to-roman (n &key downcasep)
  (format nil (if downcasep "~(~@R~)" "~@R") n))

(defun s-string (&rest cc)
  (concatenate 'string cc))

(defun left-zero-pad (n reqd-length)
  (let* ((n (write-to-string n))
         (length-so-far (length n)))
    (if (>= length-so-far reqd-length) n
      (dotimes (i (- reqd-length length-so-far) n)
        (setq n (concatenate 'string "0" n))))))

(defun get-counter-value (c)
  (let ((v (counter*-value c))
        (f (counter*-format c))
        (thk (counter*-thunk c)))
    (cond (thk (write-to-string (funcall thk)))
          ((string= f "s") v)
          ((string= f "A")
           (if (= v 0) "0"
             (string (code-char (+ (char-code #\A) -1 v)))))
          ((string= f "a")
           (if (= v 0) "0"
             (string (code-char (+ (char-code #\a) -1 v)))))
          ((string= f "I") (number-to-roman v))
          ((string= f "i") (number-to-roman v :downcasep t))
          ((and (string-to-number f)
                (setq *it* (length f))
                (and (> *it* 1) *it*))
           (left-zero-pad v *it*))
          (t (write-to-string v)))))

(defun raw-counter-value (str)
  (counter*-value (get-counter-named str)))

(defun formatted-counter-value (str)
  (get-counter-value (get-counter-named str)))

(defun load-troff2page-data-file (f)
  (let ((*input-line-no* 0)
        (*package* (find-package :troff2page)))
    (load f)))

(defun unicode-escape (s)
  (and (= (length s) 5)
       (char= (char s 0) #\u)
       (let* ((s (subseq s 1))
              (*read-base* 16)
              (n (read-from-string s)))
         (and (integerp n)
              (code-char n)))))

;* requests

(defrequest "bp"
  (lambda ()
    (read-troff-line)
    (unless *current-diversion*
      (do-eject))))

(defrequest "rm"
  (lambda ()
    (let ((w (car (read-args))))
      (remhash w *request-table*)
      (remhash w *macro-table*)
      (remhash w *string-table*))))

(defrequest "blm"
  (lambda ()
    (let ((w (car (read-args))))
      (setq *blank-line-macro*
        (if (not w) nil w)))))

(defrequest "lsm"
  (lambda ()
    (let ((w (car (read-args))))
      (setq *leading-spaces-macro*
            (if (not w) nil w)))))

(defrequest "em"
  (lambda ()
    (let ((w (car (read-args))))
      (setq *end-macro* w))))

(defun call-ender (ender)
  (unless *exit-status*
    (unless (string= ender ".")
      (toss-back-char #\newline)
      (execute-macro ender))))

(defrequest "de"
  (lambda ()
    (let* ((args (read-args))
           (w (car args))
           (ender (or (cadr args) ".")))
      (setf (gethash w *macro-table*)
            (collect-macro-body w ender))
      (call-ender ender))))

(defrequest "shift"
  (lambda ()
    (let* ((args (read-args))
           (n 1))
      (when args (setq n (string-to-number (car args))))
      (setf (cdr *macro-args*)
            (nthcdr n (cdr *macro-args*))))))

(defun eval-in-lisp (ss)
  (let ((s (with-output-to-string (o)
             (dolist (x ss)
               (princ x o) (terpri o)))))
    (with-input-from-string (i s)
      (let ((*package* (find-package :troff2page)))
        (loop (let ((x (read i nil)))
                (when (not x) (return))
                (eval x)))))))

(defrequest "ig"
  (lambda ()
    (let ((ender (or (car (read-args)) ".")))
      (let* ((*turn-off-escape-char-p* t)
             (contents
               (collect-macro-body :collecting-ig ender)))
        (when (string= ender "##")
          (eval-in-lisp contents))))))

(defrequest "als"
  (lambda ()
    (let* ((args (read-args))
           (new (car args))
           (old (cadr args)))
      (cond ((setq *it* (gethash old *macro-table*))
             (setf (gethash new *macro-table*) *it*))
            ((setq *it* (gethash old *request-table*))
             (setf (gethash new *request-table*) *it*))
            (t (terror "als: unknown rhs ~a" old))))))

(defrequest "rn"
  (lambda ()
    (let* ((args (read-args))
           (old (car args))
           (new (cadr args)))
      (cond ((setq *it* (gethash old *macro-table*))
             (setf (gethash new *macro-table*) *it*
                   (gethash old *macro-table*) nil))
            ((setq *it* (gethash old *request-table*))
             (setf (gethash new *request-table*) *it*
                   (gethash old *request-table*) nil))
            (t (terror "rn: unknown lhs ~a" old))))))

(defrequest "am"
  (lambda ()
    (let* ((args (read-args))
           (w (car args))
           (ender (or (cadr args) ".")))
      ;      (format t "mactbl is ~s~%" *macro-table*)
      ;      (format t "--> ~a~%" (gethash w *macro-table*))
            ;(format t "doing .am ~s ~s~%" w ender)
      (let ((extra-macro-body (collect-macro-body w ender)))
        (cond ((not (eq (setq *it* (gethash w *macro-table* :undefined))
                        :undefined))
               (setf (gethash w *macro-table*)
                     (nconc *it* extra-macro-body)))
              ((setq *it* (gethash w *request-table*))
               (let ((tmp (gen-temp-string)))
                 (setf (gethash tmp *request-table*) *it*)
                 (setf (gethash w *macro-table*)
                       (cons
                         (concatenate 'string "." tmp " \\$*")
                         extra-macro-body))
                 (setf (gethash w *request-table*)
                       (lambda ()
                         (execute-macro w)))))
              (t (twarning "am: ignoring ~a" w)))
        (call-ender ender)))))

(defrequest "eo"
  (lambda ()
    (setq *turn-off-escape-char-p* t)
    (read-troff-line)))

(defun get-first-non-space-char-on-curr-line ()
    (ignore-spaces)
    (let ((ln (read-troff-line)))
      (if (string= ln "") nil
        (char ln 0))))

(defrequest "ec"
  (lambda ()
    (setq *escape-char*
      (or (get-first-non-space-char-on-curr-line) #\\ ))
    (setq *turn-off-escape-char-p* nil)))

(defrequest "ecs"
  (lambda ()
    (read-troff-line)
    (setq *saved-escape-char* *escape-char*)))

(defrequest "ecr"
  (lambda ()
    (read-troff-line)
    (setq *escape-char*
      (or *saved-escape-char* #\\))))

(defrequest "cc"
  (lambda ()
    (setq *control-char*
      (or (get-first-non-space-char-on-curr-line) #\.))))

(defrequest "c2"
  (lambda ()
    (setq *no-break-control-char*
      (or (get-first-non-space-char-on-curr-line) #\'))))

(defrequest "di"
  (lambda ()
    (cond ((not *current-diversion*)
           (let ((w (car (read-args))))
             (unless w
               (terror "di: name missing"))
             (setq *current-diversion* w)
             (let ((o (make-string-output-stream)))
               (setf (gethash w *diversion-table*)
                           (make-diversion* :port o
                                           :return *out*))
               (setq *out* o))))
          (t
            (let ((div (gethash *current-diversion* *diversion-table*)))
              (unless div
                (terror "di: ~a doesn't exist" *current-diversion*))
              (setq *current-diversion* nil)
              (setq *out* (diversion*-return div)))))))

(defrequest "da"
  (lambda ()
    (let ((w (car (read-args))))
      (unless w
        (terror "da: name missing"))
      (setq *current-diversion* w)
      (let ((div (gethash w *diversion-table*))
            (div-port nil))
        (cond (div (setq div-port (diversion*-port div)))
              (t (setq div-port (make-string-output-stream))
                 (setf (gethash w *diversion-table*)
                       (make-diversion* :port div-port
                                       :return *out*))))
        (setq *out* div-port)))))

(defrequest "ds"
  (lambda ()
    (let* ((w (expand-args (read-word)))
           (s (expand-args (read-troff-string-line))))
      ;(format t "setting ~s to ~s~%" w s)
      (setf (gethash w *string-table*)
            (lambda (&rest args)
              (let ((*macro-args* (cons w args)))
                (expand-args s)))))))

(defrequest "char"
  (lambda ()
    (ignore-spaces)
    (unless (char= (get-char) *escape-char*)
      (error "char"))
    (let* ((glyph-name (read-escaped-word))
           (unicode-char (unicode-escape glyph-name))
           (s (expand-args (read-troff-string-line))))
      (defglyph (or unicode-char glyph-name) s))))

(defrequest "substring"
  (lambda ()
    (let* ((args (read-args))
           (s (car args))
           (str (funcall (gethash s *string-table*)))
           (str-new nil)
           (n nil)
           (n1 (string-to-number (cadr args)))
           (n2 (let ((n2 (caddr args)))
                 (and n2 (1+ (string-to-number n2))))))
      (unless n2
        (setq n (length str))
        (setq n2 n))
      (when (< n1 0)
        (unless n (setq n (length str)))
        (setq n1 (+ n n1 1)))
      (when (< n2 0)
        (unless n (setq n (length str)))
        (setq n2 (+ n n2 1)))
      (setq str-new (subseq str n1 n2))
      (setf (gethash s *string-table*)
            (lambda () str-new)))))

(defrequest "length"
  (lambda ()
    (let ((args (read-args)))
      (setf (counter*-value (get-counter-named (car args)))
            (length (cadr args))))))

(defrequest "PSPIC"
  (lambda ()
    (let ((align nil) (ps-file nil) (width nil) (height nil)
          (args (read-args))
          (w nil))
      (setq w (car args))
      (cond ((not w) (terror "pspic"))
            ((string= w "-L") (setq align "left"))
            ((string= w "-I") (read-word) (setq align "left"))
            ((string= w "-R") (setq align "right")))
      (cond (align
             (setq ps-file (read-word)))
            (t
             (setq align "center")
             (setq ps-file w)))
      (setq width (cadr args))
      (setq height (caddr args))
      (emit-verbatim "<div align=")
      (emit-verbatim align)
      (emit-verbatim ">")
      (let ((*groff-image-options* nil))
        (call-with-image-port
         (lambda (o)
           (princ ".mso pspic.tmac" o) (terpri o)
           (princ ".PSPIC " o) (princ ps-file o)
           (when width (princ " " o) (princ width o))
           (when height (princ " " o) (princ height o))
           (terpri o))))
      (emit-verbatim "</div>"))))

(defrequest "PIMG"
  (lambda ()
    (let (align img-file width height)
      (setq align (read-word))
      (cond ((member align '("-L" "-C" "-R") :test #'string=)
             (setq img-file (read-word)))
            (t (setq img-file align)
               (setq align "-C")))
      (setq width (read-length-in-pixels))
      (setq height (read-length-in-pixels))
      (read-troff-line)
      (cond ((string= align "-L") (setq align "left"))
            ((string= align "-C") (setq align "center"))
            ((string= align "-R") (setq align "right")))
      (emit-verbatim "<div align=")
      (emit-verbatim align)
      (emit-verbatim ">")
      (emit-newline)
      (emit-verbatim "<img src=\"")
      (emit-verbatim img-file)
      (emit-verbatim "\"")
      (unless (= width 0)
        (emit-verbatim " width=")
        (emit-verbatim width))
      (unless (= height 0)
        (emit-verbatim " height=")
        (emit-verbatim height))
      (emit-verbatim ">")
      (emit-newline)
      (emit-verbatim "</div>")
      (emit-newline))))

(defrequest "IMG"
  (gethash "PIMG" *request-table*))

;(defun do-tmc (&key newlinep)
;  (ignore-spaces)
;  (let ((*outputting-to* :troff)
;        (*out* *standard-output*))
;    (emit (expand-args (read-troff-line)))
;    (when newlinep (emit-newline))))

(defun do-tmc (&key newlinep)
  (ignore-spaces)
  (princ (expand-args (read-troff-line)))
  (when newlinep (terpri)))

(defrequest "tmc"
  (lambda ()
    (do-tmc)))

(defrequest "tm"
  (lambda ()
    (do-tmc :newlinep t)))

;(defrequest "sy"
;  (lambda ()
;    (ignore-spaces)
;    (let ((systat
;            (os-execute
;              (with-output-to-string (o)
;                (let ((*outputting-to* :troff)
;                      (*out* o))
;                  (emit (expand-args (read-troff-line)))
;                  (terpri o))))))
;      (cond ((eq systat t) (setq systat 0))
;            ((not (numberp systat)) (setq systat 256)))
;      (setf (counter*-value (get-counter-named "systat"))
;            systat))))

(defrequest "sy"
  (lambda ()
    (ignore-spaces)
    (let ((systat
           (os-execute
            (with-output-to-string (o)
              (princ (expand-args (read-troff-line)) o)
              (terpri o)))))
      (cond ((eq systat t) (setq systat 0))
            ((not (numberp systat)) (setq systat 256)))
      (setf (counter*-value (get-counter-named "systat"))
            systat))))

;(defrequest "pso"
;  (lambda ()
;    (ignore-spaces)
;    (os-execute
;     (with-output-to-string (o)
;       (let ((*outputting-to* :troff)
;             (*out* o))
;         (emit (expand-args (read-troff-line)))
;         (emit (concatenate 'string " > "
;                            *pso-temp-file*))
;         (terpri o))))
;    (troff2page-file *pso-temp-file*)))

(defrequest "pso"
  (lambda ()
    (ignore-spaces)
    (os-execute
     (with-output-to-string (o)
       (let ((*turn-off-escape-char-p* t))
         (princ (expand-args (read-troff-line)) o)
         (princ " > " o)
         (princ *pso-temp-file* o)
         (terpri o))))
    (troff2page-file *pso-temp-file*)))

(defrequest "FS"
  (lambda ()
    (let ((fnmark (car (read-args)))
          (fno nil)
          (fntag nil))
      (cond (fnmark
             (setq fntag (concatenate 'string "\\&" fnmark " ")))
            (*this-footnote-is-numbered-p*
             (setq *this-footnote-is-numbered-p* nil
                   fno *footnote-count*)))
      (let ((fnote-chars '()))
        (loop
          (let ((x (read-one-line)))
            (when (zerop (or (search ".FE" x) -1)) (return))
            (setq fnote-chars
                  (nconc fnote-chars
                         (concatenate 'list x)
                         (list #\newline)))))
        (push (make-footnote* :tag fntag
                             :number fno
                             :text fnote-chars)
              *footnote-buffer*)))
    ;(emit-edit-source-doc)
    ))

(defrequest "RS"
  (lambda ()
    (read-troff-line)
    (emit-para)
    (emit-verbatim "<blockquote>")))

(defrequest "RE"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "</blockquote>")
    (emit-newline)
    (emit-para)))

(defrequest "DE"
  (lambda ()
    (read-troff-line)
    (stop-display)))

(defrequest "par@reset"
  (lambda ()
    nil))

(defrequest "LP"
  (lambda ()
    (read-troff-line)
    (emit-newline)
    (emit-para :parstartp t)))

(defrequest "RT" (gethash "LP" *request-table*))

(defrequest "lp" (gethash "LP" *request-table*))

(defrequest "PP"
  (lambda ()
    (read-troff-line)
    (emit-newline)
    (emit-para :parstartp t :indentp t)))

(defrequest "P" (gethash "PP" *request-table*))

(defrequest "HP" (gethash "PP" *request-table*)) ;?

(defrequest "sp"
  (lambda ()
    (let ((num (read-number-or-length :unit #\v)))
      (if (= num 0) (setq num (point-equivalent-of #\v)))
      (read-troff-line)
      ;for text-based browsers that don't convert the <div> to vert
      ;space
      ;(emit-verbatim "<br style=\"margin-top: 0; margin-bottom: 0\">")
      (emit-verbatim "<br style=\"margin-top: ") ;was DIV
      (emit-verbatim num)
      (emit-verbatim "px; margin-bottom: ")
      (emit-verbatim num)
      (emit-verbatim "px\">")
      ;(emit-verbatim "px\"></div>")
      (emit-newline)
      )))

(defrequest "br"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "<br>")
    ))

(defrequest "ti"
  (lambda ()
    (toss-back-string (expand-args (read-word)))
    (let ((arg (read-length-in-pixels)))
      (read-troff-line)
      (when (> arg 0)
        (emit-verbatim "<br>")
        (emit-nbsp (ceiling (/ arg 5)))))))

(defun specify-margin-left-style ()
  (unless (= *margin-left* 0)
    (emit-verbatim " style=\"margin-left: ")
    (emit-verbatim *margin-left*)
    (emit-verbatim "pt;\"")))

(defrequest "in"
  (lambda ()
    ;(gethash "ti" *request-table*)
    (let* ((sign (read-opt-sign))
           (num (read-number-or-length :unit #\m)))
      (read-troff-line)
      (when num
        (case sign
          (#\+ (incf *margin-left* num))
          (#\- (decf *margin-left* num))
          (t (setq *margin-left* num)))))
    (emit-verbatim "<p ")
    (specify-margin-left-style)
    (emit-verbatim ">")))

(defrequest "TH"
  (lambda ()
    (let* ((th-counter (get-counter-named "man_.TH_times_called"))
           (th-n (incf (counter*-value th-counter)))
           (args (read-args)))
      (when (= th-n 1)
        (!macro-package :man)
        (when (setq *it* (find-macro-file "man.local"))
          (troff2page-file *it*))
        (when (setq *it* (find-macro-file "pca-t2p-man.tmac"))
          (troff2page-file *it*)))
      (cond ((and (= th-n 1) (setq *it* (gethash "TH" *macro-table*)))
             (let* ((the-new-th *it*)
                    (*macro-args* (cons "TH" args)))
               (execute-macro-body the-new-th)))
            (t
              (let ((title (car args))
                    (sec (cadr args))
                    (date (caddr args)))
                (when title
                  (setq title (string-trim-blanks title))
                  (unless (string= title "")
                    (store-title title :emitp t))
                  (when date
                    (setq date (string-trim-blanks date))
                    (unless (string= date "")
                      (setf (gethash "DY" *string-table*)
                            (lambda () date)))))))))))

(defrequest "TL"
  (lambda ()
    (read-troff-line)
    (get-header
      (lambda (title)
        (unless (string= title "")
          (store-title title :emitp t))))))

(defrequest "HTL"
  (lambda ()
    (read-troff-line)
    (let ((title (read-one-line)))
      (store-title title :preferredp t))))

(defun author-info (&key italicp)
  (read-troff-line)
  (emit-para)
  ;(emit-verbatim "<div align=center class=abstract>")
  (emit-verbatim "<div align=center class=author>")
  (when italicp (emit (switch-font "I")))
  (unfill-mode)
  (setq *afterpar*
        (lambda ()
          (emit-verbatim "</div>")
          (emit-newline))))

(defrequest "@AU"
  (lambda ()
    (author-info :italicp t)))

(defrequest "AU"
  (lambda ()
    (funcall (gethash "@AU" *request-table*))))

(defrequest "AI"
  (lambda ()
    (author-info)))

(defrequest "AB"
  (lambda ()
    (let ((w (car (read-args))))
      (emit-para)
      (unless (and w (string= w "no"))
        (emit-verbatim "<div align=center class=abstract><i>ABSTRACT</i></div>")
        (emit-para))
      (emit-verbatim "<blockquote>"))))

(defrequest "AE"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "</blockquote>")))

(defrequest "NH"
  (lambda ()
    (funcall (gethash "@NH" *request-table*))))

(defrequest "@NH"
  (lambda ()
    (let ((lvl (car (read-args))))
      (emit-section-header (if lvl (string-to-number lvl) 1)
                  :numberedp t))))

(defrequest "SH"
  (lambda ()
    (case *macro-package*
      (:man (emit-section-header 1 :man-header-p t))
      (t ;(funcall (gethash "@SH" *request-table*))
        (execute-macro "@SH")
        ))))

(defrequest "@SH"
  (lambda ()
    (let ((lvl (car (read-args))))
      (emit-section-header (if lvl (string-to-number lvl) 1)))))

(defrequest "SS"
  (lambda ()
    (emit-section-header 2 :man-header-p t)))

(defrequest "SC"
  (lambda ()
    (unless (gethash "bell_localisms" *numreg-table*)
      (defnumreg "bell_localisms" (make-counter*)))
    (emit-section-header 1 :numberedp t)))

(defrequest "P1"
  (lambda ()
    (when (gethash "bell_localisms" *numreg-table*)
      (start-display "L")
      (emit (switch-font "C")))))

(defrequest "P2"
  (lambda ()
    (read-troff-line)
    (when (gethash "bell_localisms" *numreg-table*)
      (stop-display))))

(defrequest "EX"
  (lambda ()
    (start-display "L")
    (emit (switch-font "C"))))

(defrequest "EE"
  (lambda ()
    (read-troff-line)
    (stop-display)))

(defrequest "ND"
  (lambda ()
    (let ((w (expand-args (read-troff-line))))
      ;possible trailing space?  shd i use all-args instead?
      (setf (gethash "DY" *string-table*) (lambda () w)))
    ;(read-troff-line)
    ))

(defrequest "CSS"
  (lambda ()
    (let ((f (car (read-args))))
      (unless (member f *stylesheets* :test #'string=)
        (flag-missing-piece :stylesheet))
      (write-aux `(!stylesheet ,f)))))

(defrequest "gcolor"
  (lambda ()
    (let ((c (car (read-args))))
      (switch-glyph-color c))))

(defrequest "fcolor"
  (lambda ()
    (let ((c (car (read-args))))
      (switch-fill-color c))))

(defrequest "I"
  (lambda ()
    (font-macro "I")))

(defrequest "B"
  (lambda ()
    (font-macro "B")))

(defrequest "RI"
  (lambda ()
    (man-alternating-font-macro nil "I")))

(defrequest "IR"
  (lambda ()
    (man-alternating-font-macro "I" nil)))

(defrequest "BI"
  (lambda ()
    (man-alternating-font-macro "B" "I")))

(defrequest "IB"
  (lambda ()
    (man-alternating-font-macro "I" "B")))

(defrequest "BR"
  (lambda ()
    (man-alternating-font-macro "B" nil)))

(defrequest "RB"
  (lambda ()
    (man-alternating-font-macro nil "B")))

(defrequest "C"
  (lambda ()
    (font-macro "C")))

(defrequest "CW"
  (gethash "C" *request-table*))

(defrequest "R"
  (lambda ()
    (font-macro nil)))

(defrequest "DC"
  (lambda ()
    (let* ((args (read-args))
           (big-letter (car args))
           (extra (cadr args))
           (color (caddr args)))
      (emit (switch-glyph-color color))
      (emit-verbatim "<span class=dropcap>")
      (emit big-letter)
      (emit-verbatim "</span>")
      (emit (switch-glyph-color ""))
      (when extra (emit  extra))
      (emit-newline)
      )))

(defrequest "BX"
  (lambda ()
    (let ((txt (car (read-args))))
      (emit-verbatim "<span class=troffbox>")
      (emit (expand-args txt))
      (emit-verbatim "</span>")
      (emit-newline))))

(defrequest "B1"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "<div class=troffbox>")
    (emit-newline)))

(defrequest "B2"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "</div>")
    (emit-newline)))

(defrequest "ft"
  (lambda ()
    (let ((f (car (read-args))))
      ;(ms-font-macro f) ;CHECK
      (emit (switch-font f))
      )))

(defrequest "fam"
  (lambda ()
    (let ((f (car (read-args))))
      (emit (switch-font-family f)))))

(defrequest "LG"
  (lambda ()
    (read-troff-line)
    (emit (switch-size "+2"))))

(defrequest "SM"
  (lambda ()
    (read-troff-line)
    (emit (switch-size "-2"))))

(defrequest "NL"
  (lambda ()
    (read-troff-line)
    (emit (switch-size nil))))

(defrequest "URL"
  (lambda ()
    (let* ((args (read-args))
           (url (car args))
           (link-text  (cadr args))
           (tack-on  (caddr args)))
      (when (or (not link-text)
                (string= link-text ""))
        (setq link-text
              (cond ((char= (char url 0) #\#)
                     (let ((s (concatenate 'string "TAG_"
                                (subseq url 1))))
                       (cond ((setq *it* (gethash s *string-table*))
                              (funcall *it*))
                             (t "see below"))))
                    (t url))))
      (emit-verbatim "<a href=\"")
      (emit (link-url url))
      (emit-verbatim "\">")
      (emit link-text)
      (emit-verbatim "</a>")
      (when tack-on (emit tack-on))
      (emit-newline)
      ;(setq *keep-newline-p* t)
      )))

(defrequest "TAG"
  (lambda ()
    (let* ((args (read-args))
           (node (concatenate 'string "TAG_" (car args)))
           (pageno *current-pageno*)
           (tag-value (or (cadr args) (write-to-string pageno))))
      ;(setq *keep-newline-p* nil)
      (emit (anchor node))
      ;(emit-edit-source-doc :interval 10)
      (emit-newline)
      (!node node pageno tag-value)
      (write-aux `(!node ,node ,pageno ,tag-value)))))

(defrequest "ULS"
  (lambda ()
    (read-troff-line)
    (emit-para)
    (emit-verbatim "<ul>")))

(defrequest "ULE"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "</ul>")
    (emit-para)))

(defrequest "OLS"
  (lambda ()
    (read-troff-line)
    (emit-para)
    (emit-verbatim "<ol>")))

(defrequest "OLE"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "</ol>")
    (emit-para)))

(defrequest "LI"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "<li>")))

(defrequest "HR"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "<hr>")))

(defrequest "HTML"
  (lambda ()
    (emit-verbatim
     (expand-args (read-troff-line)))
    (emit-newline)))

(defrequest "CDS"
  (lambda ()
    (start-display "L")
    (emit (switch-font "C"))))

(defrequest "CDE"
  (lambda ()
    (stop-display)))

(defrequest "QP"
  (lambda ()
    (read-troff-line)
    (emit-para)
    (emit-verbatim "<blockquote>")
    (setq *afterpar*
      (lambda () (emit-verbatim "</blockquote>")))))

(defrequest "QS"
  (lambda ()
    (read-troff-line)
    (emit-para)
    (emit-verbatim "<blockquote>")))

(defrequest "QE"
  (lambda ()
    (read-troff-line)
    (emit-verbatim "</blockquote>")
    (emit-para)))

(defrequest "IP"
  (lambda ()
    (let ((label (car (read-args))))
      (emit-para)
      (emit-verbatim "<dl><dt>")
      (when label
        (emit (expand-args label)))
      (emit-verbatim "</dt><dd>")
      (setq *afterpar*
        (lambda ()
          (emit-verbatim "</dd></dl>")
          (emit-newline))))))

(defrequest "TP"
  (lambda ()
    (read-troff-line)
    (emit-para)
    (emit-verbatim "<dl")
    (process-line)
    (emit-verbatim "</dt><dd>")
    (setq *afterpar*
          (lambda ()
            (emit-verbatim "</dd></dl>")
            (emit-newline)))))

(defrequest "PS"
  (lambda ()
    (read-troff-line)
    (make-image ".PS" ".PE")))

(defrequest "EQ"
  (lambda ()
    (destructuring-bind (&optional (w "C") eqno) (read-args)
      (emit-verbatim "<div class=display align=")
      (emit-verbatim (cond ((string= w "C") "center")
                           (t "left")))
      (emit-verbatim ">")
      (when eqno
        (emit-verbatim "<table><tr><td width=\"80%\" align=")
        (emit-verbatim (cond ((string= w "C") "center")
                             (t "left")))
        (emit-verbatim ">")
        (emit-newline))
      (make-image ".EQ" ".EN")
      (when eqno
        (emit-newline)
        (emit-verbatim "</td><td width=\"20%\" align=right>")
        (emit-nbsp 16)
        (troff2page-string eqno)
        (emit-verbatim "</td></tr></table>"))
      (emit-verbatim "</div>")
      (emit-newline))))

(defrequest "TS"
  (lambda ()
    (read-troff-line)
    (let ((*reading-table-p* t)
          (*table-format-table* (make-hash-table))
          (*table-default-format-line* 0)
          (*table-row-number* 0)
          (*table-cell-number* 0)
          (*table-colsep-char* #\tab)
          (*table-options* " cellpadding=2") ;?
          (*table-number-of-columns* 0)
          (*table-align* nil) ;??
          )
      (table-do-global-options)
      (table-do-format-section)
      (emit-verbatim "<div")
      (when *table-align*
        (emit-verbatim " align=")
        (emit-verbatim *table-align*))
      (emit-verbatim ">")
      (emit-newline)
      (emit-verbatim "<table")
      (princ *table-options* *out*)
      (emit-verbatim ">")
      (emit-newline)
      (table-do-rows)
      (emit-verbatim "</table>")
      (emit-newline)
      (emit-verbatim "</div>")
      (clrhash *table-format-table*) ;shouldn't be necessary
      )))

(defun ignore-branch ()
  (ignore-spaces)
  (let (bracep c)
    (loop
      (setq c (snoop-char))
      (cond ((or (not c) (char= c #\newline)) (return))
            ((char= c *escape-char*)
             (get-char)
             (setq c (snoop-char))
             (cond ((or (not c) (char= c #\newline)) (return))
                   ((char= c #\{) (setq bracep t) (get-char) (return))
                   (t (get-char))))
            (t (get-char))))
    (when bracep
      (let ((nesting 1))
        (loop
          (setq c (get-char))
          (cond ((not c) (terror "ignore-branch: eof"))
                ((char= c *escape-char*)
                 (setq c (get-char))
                 (cond ((not c) (terror "ignore-branch: escape eof"))
                       ((char= c #\})
                        (decf nesting)
                        (when (= nesting 0) (return)))
                       ((char= c #\{) (incf nesting))))))))
    (read-troff-line)))

(defun read-arith-expr (&key stop)
  (let ((acc 0))
    (loop
      (let ((c (snoop-char)))
        (cond ((not c) (return acc))
              ((char= c #\+) (get-char)
                             (incf acc (read-arith-expr :stop t)))
              ((char= c #\-) (get-char)
                             (decf acc (read-arith-expr :stop t)))
              ((char= c #\*) (get-char)
			     (setq acc
				   (* acc (read-arith-expr :stop t))))
              ((char= c #\/) (get-char)
			     (setq acc
				   (/ acc (read-arith-expr :stop t))))
              ((char= c #\%) (get-char)
			     (setq acc
				   (mod acc (read-arith-expr :stop t))))
              ((char= c #\<) (get-char)
			     (setq acc
				   (let (eq-also
					  (c (snoop-char)))
				     (when (char= c #\=)
				       (get-char)
				       (setq eq-also t))
				     (if (funcall
					   (if eq-also #'<= #'<)
					   acc (read-arith-expr :stop t))
				       1 0))))
              ((char= c #\>) (get-char)
			     (setq acc
				   (let (eq-also
					  (c (snoop-char)))
				     (when (char= c #\=)
				       (get-char)
				       (setq eq-also t))
				     (if (funcall
					   (if eq-also #'>= #'>)
					   acc (read-arith-expr :stop t))
				       1 0))))
              ((char= c #\=) (get-char)
			     (when (char= (snoop-char) #\=)
			       (get-char))
                             (setq acc
                                   (if (= acc (read-arith-expr :stop t))
                                     1 0)))
	      ((char= c #\&) (get-char)
			     (setq acc
				   (let ((rhs (read-arith-expr :stop t)))
				     (if (and (> acc 0) (> rhs 0))
				       1 0))))
	      ((char= c #\:) (get-char)
			     (setq acc
				   (let ((rhs (read-arith-expr :stop t)))
				     (or (and (> acc 0) (> rhs 0))
				       1 0))))
              ((or (digit-char-p c) (char= c #\.))
               (get-char)
               (let ((r (list c))
                     (dot-read-p (char= c #\.)))
                 (loop
                   (let ((c (snoop-char)))
                     (cond ((not c) (return))
                           ((char= c #\.)
                            (when dot-read-p (return))
                            (setq dot-read-p t)
			    (get-char)
                            (push c r))
                           ((digit-char-p c)
                            (get-char)
                            (push c r))
                           (t (return)))))
                 (let ((n (read-from-string
                            (concatenate 'string
                              (nreverse r)))))
                   (if stop (return n)
                     (setq acc n)))))
              ((char= c *escape-char*)
               (get-char)
               (toss-back-string (expand-escape (snoop-char)))
               #|
               (let ((c (get-char)))
                 (case c
                   (#\n (let* ((reg (read-escaped-word))
                                 (n (raw-counter-value reg)))
                            (if stop (return n)
                              (setq acc n))))
                   (t (terror "read-arith-expr: untreated escape ~a" c))))
               |#)
              (t (return acc)))))))

(defun point-equivalent-of (indicator)
  (ecase indicator
    (#\c (* (/ 2.54) (point-equivalent-of #\i)))
    (#\i 72) ; not 72.27, see groff doc
    (#\m 10) ;kludge
    (#\v 12) ;kludge
    (#\M (* .01 (point-equivalent-of #\m)))
    (#\n (* .5 (point-equivalent-of #\m))) ;kludge?
    (#\p 1)
    (#\P 12)))

(defun read-number-or-length (&key unit)
  (ignore-spaces)
  (let* ((n (read-arith-expr))
	 (u (snoop-char)))
    (case u
      ((#\c #\i #\m #\n #\p #\P #\v)
       (get-char)
       (round (* n (point-equivalent-of u))))
      (#\f
       (get-char)
       (round (* n #.(expt 2 16))))
      (#\u (get-char) n)
      (t (cond (unit (* n (point-equivalent-of unit)))
	       (t n))))))

(defun read-length-in-pixels ()
  (ignore-spaces)
  (let* ((n (read-arith-expr))
         (u (snoop-char)))
    (case u
      ((#\c #\i #\m #\n #\p #\P)
       (get-char)
       (round (* n (point-equivalent-of u))))
      (t (round (* 4.5 n))))))  ;or 5?

(defun if-test-passed-p ()
  (let ((delim (get-char)))
    (case delim
      ((#\" #\')
       (let* ((left (expand-args (read-till-char delim :eat-delim-p t)))
              (right (expand-args (read-till-char delim :eat-delim-p t))))
         (string= left right)))
      (#\! (not (if-test-passed-p)))
      (#\n nil)
      (#\t t)
      (#\r (gethash (read-word) *numreg-table*))
      (#\c (gethash (read-word) *color-table*))
      (#\d (let ((w (expand-args (read-word))))
             (or (gethash w *request-table*) (gethash w *macro-table*)
                 (gethash w *string-table*))))
      (#\o (twarning "if: oddness of page number should not be relevant for HTML")
       (oddp *current-pageno*))
      (#\e (twarning "if: evenness of page number should not be relevant for HTML")
       (evenp *current-pageno*))
      (t (cond ((or (char= delim *escape-char*)
                    (digit-char-p delim)
                    (char= delim #\+) (char= delim #\-))
                (toss-back-char delim)
                (let ((n (read-arith-expr)))
                  ;(format t "if value = ~s~%" n)
                  (and n (> n 0))))
               (t nil
                  ;(terror 'unsupported-if-test delim)
                  ))))))

(defrequest "if"
  (lambda ()
    (ignore-spaces)
    (if (if-test-passed-p)
        (ignore-spaces)
        (ignore-branch))))

(defrequest "ie"
  (lambda ()
    (ignore-spaces)
    (cond ((if-test-passed-p) (ignore-spaces))
          (t (setq *cascaded-if-p* t)
                (ignore-branch)))))

(defrequest "el"
  (lambda ()
    (ignore-spaces)
    (cond  (*cascaded-if-p* (setq *cascaded-if-p* nil))
           (t (ignore-branch)))))

(defrequest "nx"
  (lambda ()
    (let ((args (read-args)))
      (when args
        (troff2page-file (car args)))
    (setq *exit-status* :nx))))

(defrequest "return"
  (lambda ()
    (read-troff-line)
    (setq *exit-status* :return)))

(defrequest "ex"
  (lambda ()
    (read-troff-line)
    (setq *exit-status* :ex)))

(defrequest "ab"
  (lambda ()
    (do-tmc :newlinep t)
    (setq *exit-status* :ex)))

(defrequest "nf"
  (lambda ()
    (read-troff-line)
    ;(emit-verbatim "<div>")
    (unless *previous-line-exec-p*
      ;(emit-verbatim "<div ")
      (emit-verbatim "<p ") ;  FIXME
      (specify-margin-left-style)
      (emit-verbatim ">")
      (emit-newline))
    (unfill-mode)))

#|
(defun ugly-br-hack-for-firefox ()
  (let ((curr-font (or (ev*-font (car *ev-stack*)) "")))
    (when (string= curr-font "")
      (emit-verbatim "<br class=firefoxonly>"))))
|#

(defun fill-mode ()
  (setf (ev*-fill (car *ev-stack*)) t))

(defun unfill-mode ()
  (setf (ev*-fill (car *ev-stack*)) nil))

(defrequest "fi"
  (lambda ()
    (read-troff-line)
    (fill-mode)
    ;(ugly-br-hack-for-firefox)
    ;(emit-verbatim "</div>") ;FIXME
    (emit-verbatim "<p>")
    ))

(defrequest "so"
  (lambda ()
    (let ((f  (car (read-args))))
      (when (eql *macro-package* :man)
        (let ((g (concatenate 'string "../" f)))
          (when (probe-file g)
            (setq f g))))
      (troff2page-file f))))

(defun file-extension (f)
  (let ((slash (position #\/ f :test #'char= :from-end t))
        (dot (position #\. f :test #'char= :from-end t)))
    (if (and dot (/= dot 0)
             (or (not slash)
                 (< (+ slash 1) dot)))
      (subseq f dot)
      "")))

(defun file-stem-name (f)
  (let ((slash (position #\/ f :test #'char= :from-end t))
        (dot (position #\. f :test #'char= :from-end t)))
    (cond ((and slash dot) (if (> dot slash)
                             (subseq f (+ slash 1) dot)
                             (subseq f (+ slash 1))))
          (slash (subseq f (+ slash 1)))
          (dot (subseq f 0 dot))
          (t f))))

(defun split-string-at-char (p c)
  (if (not p) '()
    (let ((r '()) (start 0))
      (loop
        (let ((i (position c p :start start :test #'char=)))
          (when (not i)
            (push (subseq p start) r)
            (return (nreverse r)))
          (push (subseq p start i) r)
          (setq start (+ i 1)))))))

(defun find-macro-file (f)
  (let ((f-stem (file-stem-name f))
        (f-ext (file-extension f)))
    (if (and (string= f-ext ".tmac")
             (member f-stem '("ms" "s" "www") :test #'string=))
      nil
      (flet ((find-in-dir (dir)
                          (let ((f (concatenate 'string dir "/" f)))
                            (and (probe-file f) f))))
        (or (some #'find-in-dir *groff-tmac-path*)
	    (find-in-dir ".")
            (find-in-dir (retrieve-env "HOME")))))))

(defrequest "mso"
  (lambda ()
    (let ((f (car (read-args))))
      (let ((f (and f (find-macro-file f))))
        (when f (troff2page-file f))))))

;

(defrequest "HX"
  (lambda ()
    (setf (counter*-value (get-counter-named "www:HX"))
          (string-to-number (car (read-args))))
    ))

(defrequest "DS"
  (lambda ()
    (start-display (read-word))
    ;(read-troff-line)
    ))

(defrequest "LD" (lambda () (start-display "L")))
(defrequest "ID" (lambda () (start-display "I")))
(defrequest "BD" (lambda () (start-display "B")))
(defrequest "CD" (lambda () (start-display "C")))
(defrequest "RD" (lambda () (start-display "R")))

(defrequest "defcolor"
  (lambda ()
    (let* ((ident (read-word))
           (rgb-color (read-rgb-color)))
      (read-troff-line)
      (setf (gethash ident *color-table*)
            rgb-color))))

(defun read-color-number (&key hashes)
  (case hashes
    (1 (format nil "~a~a" (get-char) (get-char)))
    (2 (format nil "~a~a" (get-char)
                 (prog1 (get-char) (get-char) (get-char))))
    (t (ignore-spaces)
       (let* ((n (read-arith-expr)))
         (let ((c (snoop-char)))
           (case c
             (#\f (get-char))
             (t nil)))
         (frac-to-rgb256 n)))))

(defun frac-to-rgb256 (n)
  ;or just multiply by 255?
  (setq n (round (* n 256)))
  (when (= n 256) (decf n))
  (format nil "~16,2,'0r" n))

(defun cmy-to-rgb (c m y)
  (mapcar (lambda (x)
            (frac-to-rgb256 (- 1 x)))
          (list c m y)))

(defun cmyk-to-rgb (c m y k)
  (cmy-to-rgb
    (+ (* c (- 1 k)) k)
    (+ (* m (- 1 k)) k)
    (+ (* y (- 1 k)) k)))

(defun read-rgb-color ()
  (let* ((scheme (intern (string-upcase (read-word)) :keyword))
         (number-hashes 0)
         (number-components 0)
         (components '()))
    (setq number-components
          (ecase scheme
            ((:rgb :cmy) 3)
            (:cmyk 4)
            (:gray 1)
            (:grey (setq scheme :gray) 1)))
    (ignore-spaces)
    (when (char= (snoop-char) #\#)
      (get-char) (incf number-hashes)
      (when (char= (snoop-char) #\#)
        (get-char) (incf number-hashes)))
    (push (read-color-number :hashes number-hashes) components)
    (when (>= number-components 3)
      (push (read-color-number :hashes number-hashes) components)
      (push (read-color-number :hashes number-hashes) components))
    (when (= number-components 4)
      (push (read-color-number :hashes number-hashes) components))
    (setq components (nreverse components))
    (unless (eq scheme :rgb)
      (setq components
            (mapcar (lambda (xx)
                      (/ (string-to-number xx :base 16) 256.0))
                    components)))
    (case scheme
      (:cmyk (setq components
                     (apply #'cmyk-to-rgb components)))
      (:cmy (setq components
                    (apply #'cmy-to-rgb components)))
      (:gray (setq components
                     (cmyk-to-rgb 0 0 0 (car components)))))
    (apply #'concatenate 'string
           "#" components)))

(defrequest "ce"
  (lambda ()
    (let ((n (or (string-to-number (or (car (read-args)) "1")) 1)))
      (cond ((<= n 0) (when (> *lines-to-be-centered* 0)
                        (setq *lines-to-be-centered* 0)
                        ;(ugly-br-hack-for-firefox)
                        (emit-verbatim "</div>")))
            (t
              (setq *lines-to-be-centered* n)
              (emit-verbatim "<div align=center>")))
      (emit-newline))))

(defun string-to-number (s &key (base 10))
  (if (position #\: s :test #'char=) nil
    (let* ((*read-base* base)
           (n (read-from-string s nil)))
      (if (numberp n) n nil))))

(defrequest "nr"
  (lambda ()
    ;(format t "doing .nr\n")
    (let* ((n (read-word))
           (c (get-counter-named n)))
      (when (counter*-thunk c)
        (terror "nr: cannot set readonly number register ~a" n))
      (let* ((sign (read-opt-sign))
             (num (read-number-or-length))
             ;(num (string-to-number (expand-args (read-word))))
             )
        (read-troff-line)
        ;(setq *keep-newline-p* nil)
        (when num
          (case sign
            (#\+
             (incf (counter*-value c) num))
            (#\-
             (decf (counter*-value c) num))
            (t (setf (counter*-value c) num))))))))

(defrequest "af"
  (lambda ()
    (let* ((args (read-args))
           (c (get-counter-named (car args)))
           (f (cadr args)))
      (read-troff-line)
      (setf (counter*-format c) f))))

(defrequest "ev"
  (lambda ()
    (let* ((ev-new-name (read-word)))
      (if ev-new-name
          (ev-push ev-new-name)
          (ev-pop)))))

(defrequest "evc"
  (lambda ()
    (let ((ev-rhs (let ((ev-rhs-name (car (read-args))))
                    (ev-named ev-rhs-name))))
      (ev-copy (car *ev-stack*) ev-rhs))))

(defun troff-open (stream-name f)
  (push (cons stream-name (open f :direction :output
                                :if-exists :supersede))
        *output-streams*))

(defun troff-close (stream-name)
  (close
    (cdr (assoc stream-name *output-streams* :test #'string=)))
  (setq *output-streams*
        (delete-if (lambda (c) (string= (car c) stream-name))
                   *output-streams*)))

(defrequest "open"
  (lambda ()
    (let* ((args (read-args))
           (stream-name (car args))
           (file-name (cadr args)))
      (troff-open stream-name file-name))))

(defrequest "close"
  (lambda ()
    (let ((stream-name (car (read-args))))
      (troff-close stream-name))))

;(defun do-writec (&key newline)
;  (let ((stream-name (expand-args (read-word))))
;    (let ((*outputting-to* :troff)
;          (*out* (cdr (assoc stream-name *output-streams* :test #'string=))))
;      ;(read-troff-line) ; check
;      (emit (expand-args (read-troff-string-line)))
;      ;(setq *keep-newline-p* nil)
;      (when newline (emit-newline)))))

(defun do-writec (&key newlinep)
  (let* ((stream-name (expand-args (read-word)))
         (o (cdr (assoc stream-name *output-streams* :test #'string=))))
    ;(read-troff-line) ; check
    (princ (expand-args (read-troff-string-line)) o)
    ;(setq *keep-newline-p* nil)
    (when newlinep (terpri o))))

(defrequest "writec"
  (lambda ()
    (do-writec)))

(defrequest "write"
  (lambda ()
    (do-writec :newlinep t)))

(defun write-troff-macro-to-port (macro-name o)
  (let ((*outputting-to* :troff)
        (*out* o))
    (execute-macro macro-name)))

(defrequest "writem"
  (lambda ()
    (let* ((stream-name (expand-args (read-word)))
           (macro-name (expand-args (read-word)))
           (out (cdr (assoc stream-name *output-streams* :test #'string=))))
      ;(read-troff-line)  ; ? check
      (write-troff-macro-to-port
        macro-name out))))

;* escapes

(defun all-args ()
  (let ((r "") (firstp t))
    (dolist (arg (cdr *macro-args*) r)
      (setq r (concatenate 'string r
                (if firstp (progn (setq firstp nil) "") " ")
                arg)))))

(defescape #\$
  (lambda ()
    (let ((x (read-escaped-word)) it)
      (cond ((string= x "*") (all-args))
            ((string= x "@") (all-args)) ;ok for now
            ((string= x "\\")
             (toss-back-char #\\)
             (setq it (read-arith-expr))
             (or (nth it *macro-args*) ""))
            ((numberp (setq it (read-from-string x nil)))
             (or (nth it *macro-args*) ""))
            (t "")))))

(defescape #\f
  (lambda ()
    (switch-font
      (read-escaped-word))))

(defescape #\s
  (lambda ()
    (let* ((sign (read-opt-sign))
           (sign (if sign (string sign) ""))
           (sz (concatenate 'string sign (read-escaped-word))))
      ;(switch-size (if (string= sz "0") nil sz))
      (switch-size sz)
      )))

(defescape #\m
  (lambda ()
    (switch-glyph-color (read-escaped-word))))

(defescape #\M
  (lambda ()
    (switch-fill-color (read-escaped-word))))

(defescape #\*
  (lambda ()
    (let* ((s-args (read-troff-string-args))
           (s (car s-args))
           (args (cdr s-args)))
      ;(format t "s = ~s~%" s)
      (cond ((setq *it* (gethash s *string-table*))
             (apply *it* args))
            (t "")))))

(defescape #\c
  (lambda ()
    (setq *keep-newline-p* nil)
    ""))

(defescape #\"
  (lambda ()
    (cond (*reading-quoted-phrase-p* (verbatim "\""))
          ;(t (read-troff-line) "")
          (t (read-troff-line :stop-before-newline-p t) "")
          )))

(defescape #\#
  (lambda ()
    (read-troff-line)
    (setq *previous-line-exec-p* t
          *keep-newline-p* nil)
    ""))

(defescape #\\
  (lambda ()
    (if *macro-copy-mode-p*
        (string #\\ )
        (verbatim "\\")
        )))

(defescape #\{
  (lambda ()
    ;(format t "doing \\{\n")
    (ignore-spaces)
    (setq *cascaded-if-stack* (cons *cascaded-if-p* *cascaded-if-stack*)
          *cascaded-if-p* nil)
    ;(setq *previous-line-exec-p* t)
    ;(setq *keep-newline-p* nil)
    ""))

(defescape #\}
  (lambda ()
    ;(format t "doing \\}\n")
    (read-troff-line)
    (setq *cascaded-if-p* (car *cascaded-if-stack*)
          *cascaded-if-stack* (cdr *cascaded-if-stack*))
    ""))

(defescape #\n
  (lambda ()
    (let* ((sign (read-opt-sign))
           (n (read-escaped-word))
           (c (get-counter-named n))
           it)
      (cond ((setq it (counter*-thunk c))
             (when sign
               (terror "\\n: cannot set readonly number register ~a" n))
             (write-to-string (funcall it)))
            (t
              (case sign
                (#\+
                 (incf (counter*-value c)))
                (#\-
                 (decf (counter*-value c))))
              (get-counter-value c))))))

(defescape #\V
  (lambda ()
    (retrieve-env (read-escaped-word))))

(defescape #\(
  (lambda ()
    (let* ((c1 (get-char))
           (c2 (get-char))
           (s (s-string c1 c2)))
      (or (gethash s *glyph-table*)
          (concatenate 'string "\\(" s)))))

(defescape #\[
  (lambda ()
    (let ((s (read-till-char #\] :eat-delim-p t))
          s1)
      (cond ((gethash s *glyph-table*))
            ((and (eql (search "u" s) 0)
                  (let ((*read-base* 16))
                    (setq s1 (subseq s 1))
                    (integerp (read-from-string s1))))
             (concatenate 'string "\\[htmlamp]#x" s1 ";"))
            (t (unless (eql (search "html" s) 0)
                 (twarning "warning: can't find special character `~a'" s))
               (concatenate 'string "\\[" s "]"))))))

(defescape #\h
  (lambda ()
    (let* ((delim (get-char))
           (ig (read-opt-pipe))
           (x (read-length-in-pixels))
           (delim2 (get-char)))
      (unless (char= delim delim2)
        (error "\\h bad delims ~c ~c" delim delim2))
      ;assume 1 space = 5 pixels and 1 pixel = 1 point
      (verbatim-nbsp (/ x 5)))))

(defescape #\v
  ;dummy def for now
  (lambda ()
    (let ((delim (get-char)))
      (read-till-char delim :eat-delim-p t)
      "")))

(defescape #\newline
  (lambda ()
    ""))

;the following really be glyphs, but #x200c shows up with width on
;browsers?

(defescape #\& (lambda () "\\[htmlempty]"))
(defescape #\% (lambda () "\\[htmlempty]"))
;(defescape #\, (lambda () "\\[htmlempty]"))
;(defescape #\/ (lambda () "\\[htmlempty]"))

(defescape #\e
  (lambda ()
    (verbatim (string *escape-char*))))

(defescape #\E
  (gethash #\e *escape-table*))

;

(defun troff2page (input-doc)
  (unless (troff2page-help input-doc)
    (let (

          (*afterpar* nil)
          (*aux-port* nil)
          (*blank-line-macro* nil)
          (*cascaded-if-p* nil)
          (*cascaded-if-stack* '())
          (*color-table* (make-hash-table :test #'equal))
          (*control-char* #\.)
          (*css-port* nil)
          (*current-diversion* nil)
          (*current-pageno* -1)
          (*current-source-file* input-doc)
          (*current-troff-input* nil)
          (*diversion-table* (make-hash-table :test #'equal))
          (*end-macro* nil)
          (*escape-char* #\\ )
          (*ev-stack* (list (make-ev* :name "*global*")))
          (*ev-table* (make-hash-table :test #'equal))
          (*exit-status* nil)
          (*font-alternating-style-p* nil)
          (*footnote-buffer* '())
          (*footnote-count* 0)
          (*glyph-table* (make-hash-table :test #'equal))
          (*groff-tmac-path* (split-string-at-char (retrieve-env "GROFF_TMAC_PATH") *path-separator*))
          (*html-head* '())
          (*html-page* nil)
          (*image-file-count* 0)
          (*input-line-no* 0)
          (*inside-table-text-block-p* nil)
          (*jobname* (file-stem-name input-doc))
          (*just-after-par-start-p* nil)
          (*keep-newline-p* t)
          (*last-input-milestone* 0)
          (*last-page-number* -1)
          (*leading-spaces-macro* nil)
          (*leading-spaces-number* 0)
          (*lines-to-be-centered* 0)
          (*macro-args* '(t))
          (*macro-copy-mode-p* nil)
          (*macro-package* :ms)
          (*macro-spill-over* nil)
          (*macro-table* (make-hash-table :test #'equal))
          (*main-troff-file* input-doc)
          (*margin-left* 0)
          (*missing-pieces* '())
          (*no-break-control-char* #\')
          (*node-table* (make-hash-table :test #'equal))
          (*num-of-times-th-called* 0)
          (*numreg-table* (make-hash-table :test #'equal))
          (*out* nil)
          (*output-streams* '())
          (*outputting-to* :html)
          (*previous-line-exec-p* nil)
          (*reading-quoted-phrase-p* nil)
          (*reading-string-call-p* nil)
          (*reading-table-p* nil)
          (*saved-escape-char* nil)
          (*sourcing-ascii-file-p* nil)
          (*string-table* (make-hash-table :test #'equal))
          (*stylesheets* '())
          (*table-align* nil)
          (*table-cell-number* 0)
          (*table-colsep-char* #\tab)
          (*table-default-format-line* 0)
          (*table-format-table* nil)
          (*table-number-of-columns* 0)
          (*table-options* "")
          (*table-row-number* 0)
          (*temp-string-count* 0)
          (*this-footnote-is-numbered-p* nil)
          (*title* nil)
          (*turn-off-escape-char-p* nil)
          (*verbatim-apostrophe-p* nil)

          )
      (load-aux-file)
      (emit-start)
      (when (setq *it* (find-macro-file ".troff2pagerc.tmac"))
        (troff2page-file *it*))
      (when (probe-file (setq *it* (concatenate 'string *jobname* ".t2p")))
        (troff2page-file *it*))
      (troff2page-file input-doc)
      (do-bye))))

(troff2page *troff2page-file-arg*)

;eof
