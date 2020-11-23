-- last modified 2020-11-23

function do_afterpar()
  local it = Afterpar
  if it then
    Afterpar = false
    it()
  end
end

function do_eject()
  if Slides_p then
    --print('eject for slides')
    --print('eject/slides calling eep')
    emit_end_para()
    emit_verbatim '</div>\n'
    emit_verbatim '<div class=slide>\n'
    emit_para()
    --print('done ejecting for slides')
  elseif Single_output_page_p then
    emit_end_para()
    emit_verbatim '<div class=pagebreak></div>'
    emit_para()
  else
    emit_end_page(); emit_start()
  end
end

function do_tmc(newlinep)
  --print('doing do_tmc')
  ignore_spaces()
  io.write(expand_args(read_troff_line()))
  if newlinep then io.write '\n' end
end

function do_writec(newlinep)
  local stream_name = expand_args(read_word())
  local o = Output_streams[stream_name]
  o:write(expand_args(read_troff_string_line()))
  if newlinep then o:write '\n' end
end
