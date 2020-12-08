-- last modified 2020-12-07

function read_possible_troff2page_specific_escape(s, i)
  --print('rptse of ', i)
  c = string.sub(s, i, i)
  if c == '' then
    return '', i
  end
  i=i+1
  if c == '(' then
    local c1,c2
    c1 = string.sub(s, i, i)
    if c1 ~= '' then i=i+1; c2 = s:sub(i,i) end
    if c2 ~= '' then i=i+1 end
    return c1..c2, i, '('
  end
  if c == '[' then
    local r = ''
    while true do
      c = string.sub(s, i, i)
      --print('rptse of ', c, string.match(c, '%a'), i)
      if c ~= '' then i=i+1 end
      if c == '' then return r, i, '[', 'unclosed' end --TODO better
      if c == ']' then break
      else r = r .. c
      end
    end
    return r, i, '['
  else
    return c, i
  end
end

--emitCalled = 0

function emit(s)
  --print('emit of', s, 'to', Out)
  --print('outputtingto=', Outputting_to)
  --emitCalled = emitCalled+1
  --if emitCalled > 50 then
   -- terror('lkjadflkjadf')
  --end
  if type(s) ~= 'string' then
    s = tostring(s)
  end
  local inside_html_angle_brackets_p = false
  local it
  local c
  local e
  local i = 1
  local r = ''
  while true do
    c = string.sub(s, i, i)
    if c == '' then break end
    i = i + 1
    if Outputting_to == 'html' or Outputting_to == 'title' then
      if c == Escape_char then
        --print('emit found \\')
        e, i, bkt, unclosed_p = read_possible_troff2page_specific_escape(s, i)
        --print('rptse found escaped ', e)
        if e == 'htmllt' then
          if Outputting_to == 'title' then
            inside_html_angle_brackets_p = true
          else Out:write '<' end
        elseif e == 'htmlgt' then
          if Outputting_to == 'title' then
            inside_html_angle_brackets_p = false
          else Out:write '>' end
        elseif e == 'htmlamp' then Out:write '&'
        elseif e == 'htmlquot' then Out:write '"'
        elseif e == 'htmlbackslash' then Out:write '\\'
        elseif e == 'htmlspace' then Out:write ' '
        elseif e == 'htmlnbsp' then Out:write '&#xa0;'
        elseif e == 'htmleightnbsp' then
          for j=1,8 do Out:write '&#xa0;' end
        elseif e == 'htmlempty' then no_op()
        else
          --print('checking glyphname', e)
          local g = Glyph_table[e]
          if g then Out:write(g)
          elseif bkt == '[' then
            Out:write(c, '[', e)
            if not unclosed_p then Out:write(']') end
          elseif bkt == '(' then
            Out:write(c, '(', e)
          else
            Out:write(c, e)
          end
        end
      elseif Outputting_to == 'title' and inside_html_angle_brackets_p then no_op()
      elseif c == '<' then Out:write '&#x3c;'
      elseif c == '>' then Out:write '&#x3e;'
      elseif c == '&' then Out:write '&#x26;'
      elseif c == '"' then Out:write '&#x22;'
      elseif c == '`' or c == "'" then Out:write(c)
      elseif fillp() then Out:write(c)
      elseif c == ' ' then emit_nbsp(1)
      elseif c == '\t' then emit_nbsp(8)
      else
        local g = Unescaped_glyph_table[c]
        if g then Out:write(g)
        else Out:write(c)
        end
      end
    elseif Outputting_to == 'troff' then Out:write(c)
    else terror(0xdeadc0de)
    end
  end
end

function emit_verbatim(s)
  emit(verbatim(s))
end

function emit_newline()
  Out:write '\n'
end

function emit_nbsp(n)
  for i = 1,n do
    emit '\\[htmlnbsp]'
  end
end

function verbatim_nbsp(n)
  --print('doing verbatim_nbsp', n)
  local r = ''
  for i = 1,math.ceil(n) do
    r = r .. '\\[htmlnbsp]'
  end
  return r
end

function verbatim(s)
  local r
  if type(s) == 'number' then
    r = tostring(s)
  else
    local c
    r = ''
    for i = 1,#s do
      c = string.sub(s, i, i)
      if c == '<' then
        r = r .. '\\[htmllt]'
      elseif c == '>' then
        r = r .. '\\[htmlgt]'
      elseif c == '"' then
        r = r .. '\\[htmlquot]'
      elseif c == '&' then
        r = r .. '\\[htmlamp]'
      elseif c == '\\' then
        r = r .. '\\[htmlbackslash]'
      elseif c == ' ' then
        r = r .. '\\[htmlspace]'
      else
        r = r .. c
      end
    end
  end
  return r
end

function check_verbatim_apostrophe_status()
  if Outputting_to == 'html' then
    if not Verbatim_apostrophe_p then
      local fixed_width_p
      local f = Ev_stack[1].font
      if f and string.find(f, 'monospace') then
        fixed_width_p=true
      end
      if not fixed_width_p then
        nb_verbatim_apostrophe()
      end
    end
  end
end

function emit_expanded_line()
  --print('doing emit_expanded_line')
  local r = ''
  local num_leading_spaces = 0
  local blank_line_p = true
  local count_leading_spaces_p = fillp() and not Reading_table_p and
    not Macro_copy_mode_p and Outputting_to ~= 'troff'
  local insert_leading_line_break_p = not Macro_copy_mode_p and
                                      Outputting_to == 'html' and
                                      not Just_after_par_start_p
  local c
  while true do
    c = get_char(); --io.write('picked up ->', c or '', '<-\n')
    if not c then
      Keep_newline_p = false --QSTN
      c = '\n'
    end
    --
    if c == '\n' then
      if blank_line_p then
        Keep_newline_p=false
      end
      --print('EEL found NL')
      break
    elseif count_leading_spaces_p and c == ' ' then
      num_leading_spaces = num_leading_spaces + 1
    elseif count_leading_spaces_p and c == '\t' then
      num_leading_spaces = num_leading_spaces + 8
    elseif escape_char_p(c) then
      --print('EEE found esc', c)
      if blank_line_p then blank_line_p = false end
      c = snoop_char();       --print('Macro_copy_mode_p =', Macro_copy_mode_p)
      if not c then c = '\n' end
      --io.write('snooped escaped c ->', c, '<-\n')
      if count_leading_spaces_p and not Reading_quoted_phrase_p and
          (c == '"' or c == '#') then
          --print('eel 1')
        expand_escape(c)
        r = ''
        break
      elseif Macro_copy_mode_p and (c == '\n' or c == '{' or c == '}' or c == 'h') then
        --print('eel 2, Macro_copy_mode_p and c=', c)
        r = r .. Escape_char
      else
        --print('eel 3')
        if count_leading_spaces_p then
          count_leading_spaces_p = false
          --print('calling ELS I')
          if num_leading_spaces>0 then
            emit_leading_spaces(num_leading_spaces, insert_leading_line_break_p)
            insert_leading_line_break_p=true
          end
        end
        r = r .. expand_escape(c)
        if c == '{' or c == '\n' then break end
      end
    else
      -- read a non-space
      if blank_line_p then blank_line_p = false end
      if count_leading_spaces_p then
        count_leading_spaces_p = false
        --print('calling ELS II')
        if num_leading_spaces>0 then
          emit_leading_spaces(num_leading_spaces, insert_leading_line_break_p)
          insert_leading_line_break_p=true
        end
      end
      if c == '"' then check_verbatim_apostrophe_status() end
      r = r .. c
    end
  end
  if blank_line_p then
    --print('calling blank line')
    emit_blank_line()
  else
    if Just_after_par_start_p then
      --print('resetting I Just_after_par_start_p')
      Just_after_par_start_p=false
    end
    --io.write('writing out->', r, '<-\n')
    emit(r)
  end
end

function emit_html_preamble()
  emit_verbatim '<!DOCTYPE html>\n'
  emit_verbatim '<html>\n'
  emit_verbatim '<!--\n'
  emit_verbatim 'Generated from '
  emit_verbatim(Main_troff_file)
  emit_verbatim ' by troff2page, '
  emit_verbatim 'v. '
  emit_verbatim(troff2page_version); emit_newline()
  emit_verbatim(troff2page_copyright_notice); emit_newline()
  emit_verbatim '(running on '
  emit_verbatim(_VERSION); emit_verbatim ')\n'
  emit_verbatim(troff2page_website); emit_newline()
  emit_verbatim '-->\n'
  emit_verbatim '<head>\n'
  emit_verbatim '<meta charset="utf-8">\n'
  emit_verbatim '<meta name="viewport" content="width=device-width">\n'
  emit_external_title()
  link_stylesheets()
  link_scripts()
  emit_verbatim '<meta name=robots content="index,follow">\n'
  for _,h in pairs(Html_head) do emit_verbatim(h) end
  emit_verbatim '</head>\n'
  emit_verbatim '<body>\n'
  emit_verbatim '<div'
  if Macro_package=='man' then emit_verbatim ' class=manpage' end
  if Slides_p then emit_verbatim ' class=slide' end
  emit_verbatim '>\n'
end

function emit_html_postamble()
  --print('emit_html_postamble calling eep')
  emit_end_para()
  emit_verbatim '</div>\n'
  emit_verbatim '</body>\n'
  emit_verbatim '</html>\n'
end

function emit_blank_line()
  --print('doing emit_blank_line')
  if Blank_line_macro then
    --print('doing EBL II')
    --print('emit_blank_line found Blank_line_macro')
    Keep_newline_p = false
    Previous_line_exec_p = true
    local it
    it = Macro_table[Blank_line_macro]
    if it then --print('BLM mac found');
      execute_macro_body(it); return end
    it = Request_table[Blank_line_macro]
    if it then --print('BLM req found');
      toss_back_char('\n'); it(); return
    end
  elseif Outputting_to == 'troff' then
    --print('doing EBL I')
    Keep_newline_p=false; emit_newline()
  else
    --print('doing EBL III')
    if not Just_after_par_start_p then
      emit_verbatim '<br>'
    end
    emit_verbatim '<span class=blankline></span>'; emit_newline()
    --print('setting II Just_after_par_start_p')
    Just_after_par_start_p = true
    --emit_verbatim '<br class=blankline>&#xa0;<br class=blankline>'; emit_newline()
  end
end

function emit_leading_spaces(num_leading_spaces, insert_leading_line_break_p)
  --print('doing emit_leading_spaces', num_leading_spaces, insert_leading_line_break_p)
  Leading_spaces_number = num_leading_spaces
  assert(num_leading_spaces > 0)
  if Leading_spaces_macro then
    local it = Macro_table[Leading_spaces_macro]
    if it then
      execute_macro_body(it)
    else
      it = Request_table[Leading_spaces_macro]
      if it then it() end
    end
  else
    -- true or insert_leading_line_break_p
    -- Just_after_par_start_p
    if insert_leading_line_break_p then
      emit_verbatim '<!---***---><br>'
    end
    for j=1,Leading_spaces_number do
      emit '\\[htmlnbsp]'
    end
  end
end

function emit_end_para()
  --print('doing emit_end_para')
  --print('In_para_p =', In_para_p)
  if not In_para_p then return end
  --print('doing eep')
  In_para_p=false
  --print('doing emit_end_para')
  emit(switch_style())
  emit_verbatim '</p>\n'
  Margin_left = 0
  if Current_troff_input then
    execute_macro_with_args('par@reset', {})
  end
  fill_mode()
  do_afterpar()
  --print('eep/ipp should be true', In_para_p)
  --print('eep setting ipp=false')
end

function emit_interleaved_para()
  local continue_current_para = In_para_p
  if continue_current_para_p then
    emit_verbatim '</p>'
  end
  emit_verbatim '<p class=interleaved></p>\n'
  if continue_current_para_p then
    emit_verbatim '<p>'
  end
end

function emit_para(opts)
  opts = opts or {}
  --print('doing emit_para', opts.style, opts.no_margins_p, opts.continue_top_ev_p)
  local para_style = opts.style
  if opts.no_margins_p then
    local zero_margins = 'margin-top: 0; margin-bottom: 0'
    if para_style then
      para_style = para_style .. '; ' .. zero_margins
    else
      para_style = zero_margins
    end
  end
  local saved_ev
  if opts.continue_top_ev_p then
    --print('saving current ev')
    saved_ev = ev_top()
    --print('curr ev=', saved_ev)
  end
  --print('emit_para calling emit_end_para')
  emit_end_para()
  if opts.interleaved_p then emit_interleaved_para() end
  emit_verbatim '<p'
  if opts.indent_p then emit_verbatim ' class=indent' end
  if opts.hanging_p then emit_verbatim ' class=hanging' end
  if opts.break_p then emit_verbatim ' class=breakinpar' end
  if opts.incremental_p then emit_verbatim ' class=incremental' end
  if para_style then emit_verbatim(string.format(' style="%s"', para_style)) end
  emit_verbatim '>'
  if saved_ev then
    --print('restoring saved_ev')
    if saved_ev.hardlines then unfill_mode() end
    local new_style = {}
    --print('sf=', saved_ev.font)
    if saved_ev.font then new_style.font = saved_ev.font end
    if saved_ev.color then new_style.color = saved_ev.color end
    if saved_ev.bgcolor then new_style.bgcolor = saved_ev.bgcolor end
    --print('calling switch_style with new_style')
    emit(switch_style(new_style))
  end
  In_para_p=true
  --Just_after_par_start_p = opts.par_start_p
  --print('setting III Just_after_par_start_p')
  Just_after_par_start_p=true
  --emit_newline()
  --print('emit_para winding down')
end

function emit_start()
  --print('emit_start stdout=', io.stdout)
  Current_pageno = Current_pageno + 1
  local html_page_count = Current_pageno
  if html_page_count == 1 and Last_page_number == -1 then
    flag_missing_piece 'last_page_number'
  end
  if Macro_package == 'ms' then
    get_counter_named('PN').value = html_page_count
  end
  Html_page = Jobname .. ((html_page_count ~= 0) and (Html_page_suffix .. html_page_count) or '') ..
  Output_extension
  ensure_file_deleted(Html_page)
  Out = io.open(Html_page, 'w')
  --print('emit_start set Out to', Out)
  emit_html_preamble()
  emit_navigation_bar('header')
end

function emit_end_page()
  emit_footnotes()
  emit_navigation_bar()
  if Current_pageno == 0 then
    emit_colophon(); collect_css_info_from_preamble()
  end
  emit_html_postamble()
  Out:close()
end

function emit_img(img_file, align, width, height)
  --print('doing emit_img', img_file, align, width, height)
  emit_verbatim '<div align='
  emit_verbatim(align)
  emit_verbatim '>\n'
  emit_verbatim '<img src="'
  emit_verbatim(img_file)
  emit_verbatim '"'
  if width and width ~= 0 then
    emit_verbatim ' width="'; emit_verbatim(width); emit_verbatim '" '
  end
  if height and height ~= 0 then
    emit_verbatim ' height="'; emit_verbatim(height); emit_verbatim '"'
  end
  emit_verbatim '>\n'
  emit_verbatim '</div>\n'
end
