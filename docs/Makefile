# last modified 2021-02-09

src_files = [!i]*.css *.ms *.tmac

src_dir = /home/ds26gte/src/troff2page/docs

all: index.html

index.html: index.ms $(src_files)
	troff2page index.ms

index.info: index.html

index.ms: $(src_dir)/index.ms
	test "$$USER" = ds26gte || exit 0; \
	test $$(basename $$(dirname $$(pwd))) = ds26gte.github.io || exit 0; \
	cp -p $$(dirname $<)/*.css .; \
	cp -p $$(dirname $<)/*.jpg .; \
	cp -p $$(dirname $<)/*.png .; \
	cp -p $$(dirname $<)/*.ms .; \
	cp -p $$(dirname $<)/*.t2p .; \
	cp -p $$(dirname $<)/*.tmac .

index.ps: index.ms $(src_files) .trofftemp.ind
	mpca -t index.ms

.trofftemp.ind: index.ms $(src_files)
	mpca -t index.ms

ps: index.ps

again: clean all

clean:
	rm -f .troff2page_temp* index*-Z-* *.html *.info .trofftemp.ind; \
	test "$$USER" = ds26gte || exit 0; \
	test $$(basename $$(dirname $$(pwd))) = ds26gte.github.io || exit 0; \
	rm -f index.ms
