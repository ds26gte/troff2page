# last modified 2020-11-15

src_files = [!i]*.css *.ms *.tmac

src_dir = /home/ds26gte/src/troff2page/docs

all: index.html

index.html: index.ms $(src_files)
	troff2page index.ms

index.info: $(src_files)
	troff2page index.ms

index.ms: $(src_dir)/index.ms
	test "${USER}" = ds26gte || exit 0; \
	cp -p $$(dirname $<)/*.css .; \
	cp -p $$(dirname $<)/*.ms .; \
	cp -p $$(dirname $<)/*.tmac .

clean:
	rm -f .troff2page_temp* *-Z-* *.html *.info
