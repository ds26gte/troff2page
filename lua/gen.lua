-- last modified 2017-08-17
--
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
  --print('<<< doing process_line to', Out)
  local c = snoop_char()
  --io.write('process_line starting with ->', c or '', '<-\n')
  --print('Control_char=', Control_char)
  --print('Macro_copy_mode_p=', Macro_copy_mode_p)
  --print('Sourcing_ascii_code_p=', Sourcing_ascii_code_p)
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
      not Sourcing_ascii_file_p and
      (function() it = read_macro_name(); return it end)() then
      --print('c = cc')
      --print('found control char\n')
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
    if (not fillp() or Lines_to_be_centered > 0) and
      not Macro_copy_mode_p and
      Outputting_to == 'html' and
      Keep_newline_p and
      not Previous_line_exec_p then
      --print('ctr lines 1')
      emit_verbatim '<Br>'
    end
    if Keep_newline_p and Lines_to_be_centered > 0 then
      --print('ctr lines 2')
      Lines_to_be_centered = Lines_to_be_centered - 1
      if Lines_to_be_centered == 0 then
        emit_verbatim '</div>'
      end
    end
    if Keep_newline_p then
      --print('kp nl')
      emit_newline()
    end
  end)
  --print('>>> process_line done, Out is', Out)
end

function expand_escape(c)
  --print('doing expand_escape', c)
  local it
  if not c then c = '\n'
  else get_char() end
  --
  if Turn_off_escape_char_p then return Escape_char .. c
  elseif (function() it=Escape_table[c]; return it end)''
  then return it()
  elseif (function() it=Glyph_table[c]; return it end)''
  then return it
  else return verbatim(c)
  end
end 
