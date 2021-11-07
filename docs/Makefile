# last modified 2021-11-07

src_files = *.ms *.tmac

define set-up-mpca
  @if ! echo $$GROFF_TMAC_PATH | grep -q '\bmpca\b'; then \
    if test ! -f pca.tmac; then \
      echo getting mpca from github; \
      git clone https://github.com/ds26gte/mpca; \
      cp -p mpca/tmac/*.tmac .; \
      rm -fr mpca; \
    fi; \
  fi
endef

define groff
  $(call set-up-mpca)
  soelim index.ms | preconv | groff -U -mpca -t > index.ps
endef

all: index.html

index.html: index.ms $(src_files)
	$(call set-up-mpca)
	troff2page.lua index.ms

index.info: index.html

index.ps: index.ms $(src_files) .trofftemp.ind
	$(call groff)

.trofftemp.ind: index.ms $(src_files)
	$(call groff)

ps: index.ps

again: clean all

clean:
	rm -f .troff2page_temp* index*-Z-* index.ps *.html *.info .trofftemp* pca*.tmac
