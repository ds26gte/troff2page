-- last modified 2017-08-20

function emit_footnotes()
  if #Footnote_buffer == 0 then return end
  --print('emitfootnotes FS calling eep')
  emit_end_para()
  emit_verbatim '<div class=footnote><hr align=left width="40%">'
  for i = 1, #Footnote_buffer do
    emit_para()
    local fn = Footnote_buffer[i]
    local fntag, fno, fnc = fn.tag, fn.number, fn.text
    if fntag then troff2page_line(fntag)
    elseif fno then
      local node_name = 'TAG:__troff2page_footnote_' .. fno
      emit(anchor(node_name))
      emit(link_start(page_node_link(false, 'TAG:__troff2page_call_footnote_' .. fno), true))
      emit_verbatim '<sup><small>'
      emit_verbatim(fno)
      emit_verbatim '</small></sup>'
      emit(link_stop())
      emit_newline()
    end
    troff2page_chars(fnc)
  end
  --print('emitfootnotes FE calling eep')
  emit_end_para()
  emit_verbatim '</div>\n'
  Footnote_buffer = {}
end
