.SH 1
6. Slideshows

.IX slideshow
To cause your troff source to be converted into slideshow-ready HTML, have
it source the provided macro file \fCt2pslides.tmac\fP.
This macro file uses a version of the \*[url \
http://mozpoint.mozdev.org]MozPoint\& library to
produce the appropriate JavaScript and style sheets to
convert your sequence of HTML pages into a Web presentation.

HTML pages meant for presentation use larger, bolder fonts, and do not have
navigation bars.

The following table describes the keys used to control the
presentation:

.TS
tab(#), center, allbox;
cb cb
l l.
Action # Effect
n, space, mouse-click # Next slide
p, backspace # Previous Slide
t, 0 # Title, or 0pening, slide
\fIn\fP (integer \(>= 0) # \fIn\fPth slide
b # toggle current slide with Black screen
w # toggle current slide with White screen
.TE

Note that the slides are numbered from 0 onward (rather than
1).  Also, when
typing a number \fIn\fP that’s two or more digits long to
get the \fIn\fPth slide, the digits should be pressed
fairly rapidly so they are interpreted together.
