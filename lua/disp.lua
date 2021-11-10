-- last modified 2021-06-17

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
  w = troff_align_to_html(w)
  local extra_arg = read_args()
  emit_para()
  emit_verbatim '<div class="display'
  if extra_arg and w ~= 'indent' then
    emit_verbatim ' '
    emit_verbatim 'verbatim'
  end
  emit_verbatim '"'
  if raw_counter_value 't2pebook' ==0 then
    -- TODO: avoid align= as it's not HTML5
    emit_verbatim ' align='
    if w == 'block' then
      emit_verbatim 'center'
    elseif w == 'indent' then
      emit_verbatim 'left'
    else emit_verbatim(w)
    end
  end
  if w == 'indent' then
    emit_verbatim ' style="margin-left: '
    emit_verbatim(counter_value_in_pixels 'DI')
    emit_verbatim 'px;"'
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
