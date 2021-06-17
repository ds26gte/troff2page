.\" last modified 2021-06-17
.SH 1
7. Ebooks
.LP
.IX ebook
.IX r t2pebook@-r t2pbook=1, Troff2page command-line option
To have your groff source be converted into an ebook-style HTML,
set the number register \fCt2pebook\fP to non-0 using the
command-line option
.EX
    -r t2pebook=1
.EE
This causes Troff2page to generate a single HTML page with no
external CSS
or image dependencies, and which can be sent to an ereader
such as the Amazon Kindle.
