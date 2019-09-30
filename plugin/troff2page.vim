" last modified 2019-09-30
" Dorai Sitaram

func! Troff2page(...)
  if a:0 == 0
    let l:args = [expand('%')]
  else
    let l:args = copy(a:000)
    let l:i = 0
    while l:i < a:0
      let l:x = l:args[l:i]
      if l:x == '%'
        let l:args[l:i] = expand('%')
      endif
      let l:i += 1
    endwhile
  endif
  call luaeval('require("troff2page").troff2page(table.unpack(_A))', l:args)
endfunc

com! -nargs=* Troff2page call Troff2page(<f-args>)
