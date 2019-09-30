.\" last modified 2019-09-29
.SH 1
5. Making an index
.LP
.IX index
.IX pca-ix.tmac, macro file
.IX makeindex
The supplied macro file \fCpca-ix.tmac\fP
creates a sorted
index, with the aid of the external program makeindex.
makeindex is included with TeX distributions, but you can
also obtain \*[url \
http://stuff.mit.edu/afs/sipb/project/tex-dev/src/tar/makeindex.tar.gz]just
the makeindex distribution\&.
.PP
Note that the indexes created by groff and troff2page are
necessarily different, because the respective paginations
are different.  In addition, the index generated for
troff2page has the additional feature of hyperlinking to the
appropriate locations in the body text.
.PP
.IX IX@.IX, macro
The call
.PP
.EX
    .IX item
.EE
.PP
marks the text “item” as an indexable item.  The metacharacters \fC@\fP,
\fC!\fP, \fC"\fP, and \fC|\fP can be used to respectively specify (a)
alternate alphabetization, (b) subitems, (c) literal metacharacters, and
(d) encapsulation of the page number.  Please see the
makeindex
documentation for all the details.  Essentially, the syntax for entering
index entries is the same \*[url \
http://tex.loria.fr/bibdex/makeindex.pdf]as for LaTeX\&, except that in troff we use
“\fC.IX item\fP” where in LaTeX one would use
\%“\fC\eindex{item}\fP”.
.PP
\fCpca-ix.tmac\fP will call makeindex to create a
sorted index in the auxiliary file \fC\e*[AUXF].ind\fP, which can be
slurped back into the input document:
.PP
.EX
    .so \*[AUXF].ind
.EE
.PP
Adding a section header on top is up to you.
