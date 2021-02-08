-- last modified 2021-02-08

function generate_html(percolatable_status_values)
  --print('doing generate_html to', Out)
  local returned_status_value
  flet({
    Exit_status = false
  }, function()
    --print('doing generate_html2', Exit_status)
    while true do
      if Exit_status then break end
      --print('calling process_line with', Out)
      process_line()
    end
    returned_status_value = Exit_status
  end)
  if table_member(returned_status_value, percolatable_status_values) then
    Exit_status = returned_status_value
  end
end

function process_line()
  --print('doing process_line')
  local c = snoop_char()
  --io.write('process_line starting with ->', c or 'NULL', '<-\n')
  --io.write('\tControl_char=', Control_char, '\n')
  --io.write('\tMacro_copy_mode_p=', tostring(Macro_copy_mode_p), '\n')
  --io.write('\tSourcing_ascii_code_p=', tostring(Sourcing_ascii_code_p), '\n')
  --io.write('\n')
  flet({
    Keep_newline_p = true
  }, function()
    local it
    if not c then
      --print('not c')
      Keep_newline_p = false
      --print('process_line setting Exit_status = Done')
      Exit_status = 'Done'
    elseif (c == Control_char or c == No_break_control_char) and
           not Macro_copy_mode_p and
           not Expanding_args_p and
           not Sourcing_ascii_file_p and
           (function() it = read_macro_name(); return it end)() then
      --print('found control char', c, it)
      Keep_newline_p = false
      -- if it ~= true ??
      execute_macro(it)
      Previous_line_exec_p = true
    else
      --print('emit exp line')
      emit_expanded_line()
      Previous_line_exec_p = false
    end
    --
    if (not fillp() or Lines_to_be_justified > 0) and
      not Macro_copy_mode_p and
      Outputting_to == 'html' and
      Keep_newline_p and
      not Previous_line_exec_p then
      --print('ctr lines 1')
      emit_verbatim '<br>'
    end
    if Keep_newline_p and Lines_to_be_justified > 0 then
      --print('ctr lines 2')
      Lines_to_be_justified = Lines_to_be_justified - 1
      if Lines_to_be_justified == 0 then
        emit_verbatim '</div>'
      end
    end
    if Keep_newline_p then
      --print('kp nl')
      emit_newline()
    end
  end)
  --print('process_line done')
end

function expand_escape(c)
  --print('doing expand_escape', c)
  local it
  if not c then c = '\n'
  else c=get_char()
  end
  --
  --if Turn_off_escape_char_p then
   -- return Superescape_char .. c
  --end
  --
  local it = Escape_table[c]
  --print('it=', it)
  --print('copymode=', Macro_copy_mode_p)
  if it and
    (not Macro_copy_mode_p or
    c=='n' or c=='*' or c=='$' or c=='\\' or
    c=='"' or c=='#') then
    --print('escape action')
    return it()
  end
  --
  if Macro_copy_mode_p then
    return Superescape_char..c
  end
  --
  if it then
    return it()
  end
  --
  it = Glyph_table[c]
  if it then
    return it
  end
  return verbatim(c)
end
