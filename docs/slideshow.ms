.SH 1
6. Slideshows

.IX slideshow
.IX Slidy
To have your troff source to be converted into slideshow-ready HTML, insert 
into it (somewhere) the macro call

.EX
  .SLIDES
.EE

This causes troff2page to use the style sheet \fCslide.css\fP and JavaScript file
\fCslidy.js\fP from \*[url http://www.w3.org/Talks/Tools/#slidy]Slidy\& to convert
your document into a single
HTML page that can be browsed as a slideshow. troff2page looks for these files in
the working directory, and if they’re not found there, it links
them from the W3C website. It may be prudent to get these files
beforehand and place them in your working directory, so the
presentation doesn’t rely on WiFi.

A new slide is started for each
level-1 section, i.e., \fC.SH 1\fP and \fC.NH 1\fP.
(Note of course
that it doesn’t make sense to convert generic troff documents
into presentations. The sections have got to be pretty short!)

An HTML page meant for presentation uses larger, bolder fonts by
default (but you can add your own CSS). There are no navigation
bars between slides.

.IX pause@.pause, macro
Use the \fC.pause\fP macro to
interrupt display of the rest of the current slide.

Consult the \*[url https://www.w3.org/Talks/Tools/Slidy2/Overview.html]Slidy documentation\& for the keypresses and clicks you can use
to progress through or dynamically alter the look of your
presentation. 
