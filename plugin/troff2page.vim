" last modified 2019-09-30
" Dorai Sitaram

func! Troff2page(...)
  if a:0 == 0
    let l:args = [expand('%')]
  else
    let l:args = a:000
  endif
  call luaeval('require("troff2page").troff2page(_A)', l:args)
endfunc

com! -complete=file -nargs=? Troff2page call Troff2page(<f-args>)
