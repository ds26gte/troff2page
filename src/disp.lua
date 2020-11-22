-- last modified 2020-11-22

function troff_align_to_html(i)
  if not i then
    i = 'I'
  end
  if i == 'C' then return 'center'
  elseif i == 'B' then return 'block'
  elseif i == 'R' then return 'right'
  elseif i == 'L' then return 'left'
  else return 'indent'
  end
end

function start_display(w)
  --print('### doing start_display')
  local w = troff_align_to_html(w)
  --print('start_display calling read_troff_line')
  read_troff_line()
  emit_para()
  emit_verbatim '<div class=display align='
  if w == 'block' then
    emit_verbatim 'center'
  elseif w == 'indent' then
    emit_verbatim 'left'
  else emit_verbatim(w)
  end
  if w == 'indent' then
    emit_verbatim ' style="margin-left: '
    emit_verbatim(raw_counter_value 'DI')
    emit_verbatim 'ps;"'
  end
  emit_verbatim '>'
  emit_newline()
  ev_push 'display_environment'
  unfill_mode()
  --print('### start_display finished')
end

function stop_display()
  --print('### calling stop_display')
  read_troff_line()
  emit(switch_style())
  ev_pop()
  emit_newline()
  emit_verbatim '</div>'
  emit_newline()
  emit_para()
  --print('### stop_display finished')
end
