# last modified 2020-11-11

all: ../lua/troff2page.lua

0shebang.lua: [^0]*.lua
	test "${USER}" = ds26gte || exit 0; \
	sed -i -e "s/[0-9]\{8\}/$$(date +%Y%m%d)/" 0shebang.lua

../lua/troff2page.lua: *.lua
	kahlua
