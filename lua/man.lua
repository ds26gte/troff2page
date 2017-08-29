-- last modified 2017-08-29

function TH_request()
  defrequest('TH', nil)
  nb_macro_package('man')
  local it
  it = find_macro_file('man.local')
  if it then troff2page_file(it) end
  troff2page_string[[
.de TH
.de TH disabled
.tm Calling .TH twice in man page
.disabled
.TL
\\$1
.RT
.ds DY \\$3
.ig ##
if Last_page_number>0 and not Node_table['TAG:__troff2page_toc']
then flag_missing_piece('toc')
end
.##
.TAG __troff2page_toc
.so \\*[AUXF].toc
.nr pca:next-graf-without-indent 1
.nr pca-t2p-man:enable-toc-entries 1
..
.
.de TOCLINE-PLAIN
.nr pca-t2p-man:sec-count \\$1
.shift
.nr pca-t2p-man:toc-item-indent \\$1
.shift
\h'\\n[pca-t2p-man:toc-item-indent]m'
\\*[url #TAG:__pca_sec_\\n[pca-t2p-man:sec-count] "\\$*"]
.br
..
.
.de pca-t2p-man:write-toc-line
.if !\\n[pca-t2p-man:enable-toc-entries] .return
.if !\\n[pca-t2p-man:toc-opened-p] \{\
.nr pca-t2p-man:toc-opened-p 1
.open pca:toc-stream \\*[AUXF].toc
.\}
.nr pca-toc:count +1
.TAG __pca_sec_\\n[pca-toc:count]
.write pca:toc-stream .TOCLINE-PLAIN \\n[pca-toc:count] \\$*
..
.
.ig ##
defrequest('pca-t2p-man:orig-SH', function()
  emit_section_header(1, {man_header_p=true})
end)

defrequest('pca-t2p-man:orig-SS', function()
  emit_section_header(2, {man_header_p=true})
end)
.##
.
.de SH
.pca-t2p-man:write-toc-line 0 \\$*
.pca-t2p-man:orig-SH \\$*
..
.
.de SS
.pca-t2p-man:write-toc-line 1 \\$*
.pca-t2p-man:orig-SS \\$*
..
  ]]
  it = Macro_table.TH
  local args = {read_args()}
  table.insert(args, 1, 'TH')
  flet({Macro_args = args},
  function() execute_macro_body(it) end)
end
