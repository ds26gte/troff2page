.\" last change 2011-11-25
.\" vi:ft=nroff
.
.ie \n[.X] \{\
.mso s  \" heirloom troff
.nr .U 1
.\}
.el .mso ms.tmac   \" groff
.
.\"mso www.tmac \" ??
.mso p.tmac
.mso ex.tmac
.mso url.tmac
.mso defhsl.tmac
.mso dc.tmac
.
.nr HM .75i
.nr FM 1.25i
.ds CH "
.ds CF \\n[PN]
.
.\" doesn't seem to have any effect
.nr PSINCR 3p
.
.\"nr FPS \n[PS]
.\"nr FVS \n[VS]
.
.am @AU
.  ft R
..
.
.\"nr HTML1 1
.
.\" noad
.
.\"nr bell_localisms 1
.\"nr SS-first-call 1
.
.if !d LK \{\
.de LK
.TOC
..
.\}
.
.if \n[.X] \{\
.de DC
\\$1\\$2
..
.\}
.
.de HBP
..
.
.if \n[.troff2page] \{\
.if !\n[HTML1] \{\
.de HBP
.bp
..
.\}
.nr PI 0
.nr PD 1v
.nr LL 8i
.
.rn SH SH_orig
.de SH
.HBP
.SH_orig \\$*
..
.\}
.
.HX 1
.
.\" follg only used by troff2page
.CSS default.css
.
.nr troff2page_version_last_digit \n[.troff2page]%10
.
.ds troff2page_version_suffix th
.if \n[troff2page_version_last_digit]=1 .ds troff2page_version_suffix st
.if \n[troff2page_version_last_digit]=2 .ds troff2page_version_suffix nd
.if \n[troff2page_version_last_digit]=3 .ds troff2page_version_suffix rd
.
.ds troff2page_version_th \n[.troff2page]\*{\*[troff2page_version_suffix]\*}