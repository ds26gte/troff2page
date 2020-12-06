# last modified 2020-12-07

src_files = $(wildcard ?.1 ??.1)

html_files = $(src_files:%.1=%.html)

all: $(html_files)

%.html : %.1
	troff2page -mpca $<

again: clean all

clean:
	rm -f *.html *.pdf *.ps *-Z-*
