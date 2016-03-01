tmac-files = defhsl.tmac style.tmac
ms-files = commands.ms error.ms eval.ms genindex.ms index.ms infodoc.ms intro.ms layout.ms slideshow.ms xrefs.ms
troff-files = $(tmac-files) $(ms-files)

all: index.html index.info

index.html: $(troff-files)
	troff2page index.ms

index.info: $(troff-files)
	troff2page index.ms

clean:
	rm -f *-Z-* *.html *.info

.PHONY: all clean
