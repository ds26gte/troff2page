# last modified 2020-11-18
#
src_files = $(wildcard ?.1 ??.1)

html_files = $(src_files:%.1=%.html)

all: $(html_files)

%.html : %.1
	troff2page -mpca $<

clean:
	rm -f $(html_files)
