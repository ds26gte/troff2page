tmac-files = *.tmac
ms-files = *.ms
troff-files = $(tmac-files) $(ms-files)

all: index.html

index.html: $(troff-files)
	troff2page index.ms

index.info: $(troff-files)
	troff2page index.ms

clean:
	rm -f .troff2page_temp* *-Z-* *.html *.info

.PHONY: all clean
