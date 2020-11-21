# last modified 2020-11-21

all: ../lua/troff2page.lua

0shebang.lua: [^0]*.lua
	test "${USER}" = ds26gte || exit 0; \
	sed -i -e "s/[0-9]\{8\}/$$(date +%Y%m%d)/" 0shebang.lua

../lua/troff2page.lua: *.lua
	rm -f $@;
	for f in *.lua; do \
	  if echo $$f | grep -vq '\-Z-'; then \
	    cat $$f | grep -v '^-- last modified' >> $@; \
	    echo >> $@; \
	  fi; \
	done;
	echo "troff2page(...)" >> $@;
	chmod +x $@

again: clean all

clean:
	rm -f ../lua/troff2page.lua
