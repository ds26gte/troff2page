-- last modified 2017-08-22

function read_possible_troff2page_specific_escape(s, i)
  --print('rptse of ', i)
  c = string.sub(s, i, i)
  if c == '' then --print('rptse nil');
    return '', i end
  if c == '[' then
    i=i+1
    local r = c
    while true do
      c = string.sub(s, i, i)
      --print('rptse of ', c, string.match(c, '%a'), i)
      if c ~= '' then i=i+1 end
      if string.match(c, '%a') then r = r .. c
      elseif c == ']' then r = r .. c; break
      else break
      end
    end
    --print('rptse -> ', r, i)
    return r, i
  else --print('rptse nil');
    return '', i
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
      -- COMBAK glyph-table lookup of unicode char?
      if c == '\\' then
        --print('emit found \\')
        e, i = read_possible_troff2page_specific_escape(s, i)
        --print('rptse gave ', e)
        if e == '[htmllt]' then
          if Outputting_to == 'title' then
            inside_html_angle_brackets_p = true
          else Out:write('<') end
        elseif e == '[htmlgt]' then
          if Outputting_to == 'title' then
            inside_html_angle_brackets_p = false
          else Out:write('>') end
        elseif e == '[htmlamp]' then Out:write('&')
        elseif e == '[htmlquot]' then Out:write('"')
        elseif e == '[htmlbackslash]' then Out:write('\\')
        elseif e == '[htmlspace]' then Out:write(' ')
        elseif e == '[htmlnbsp]' then Out:write('&#xa0;')
        elseif e == '[htmleightnbsp]' then
          for j=1,8 do Out:write('&#xa0;') end
        elseif e == '[htmlempty]' then do end
        else Out:write(c, e) end
      elseif Outputting_to == 'title' and inside_html_angle_brackets_p then do end
      elseif c == '<' then Out:write('&#x3c;')
      elseif c == '>' then Out:write('&#x3e;')
      elseif c == '&' then Out:write('&#x26;')
      elseif c == '"' then Out:write('&#x22;')
      elseif c == '`' or c == "'" then Out:write(c)
      elseif fillp() then Out:write(c)
      elseif c == ' ' then emit_nbsp(1)
      elseif c == '\t' then emit_nbsp(8)
      else Out:write(c) end
    elseif Outputting_to == 'troff' then Out:write(c) end
  end
end

function emit_verbatim(s)
  emit(verbatim(s))
end

function emit_newline()
  Out:write('\n')
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
    not Macro_copy_mode_p and Output_streams ~= 'troff'
  local insert_line_break_p = not Macro_copy_mode_p and Outputting_to == 'html' and
    not Just_after_par_start_p
  local c
  if Just_after_par_start_p then Just_after_par_start_p = false end
  while true do
    c = get_char(); --io.write('picked up ->', c or '', '<-\n')
    if not c then
      Keep_newline_p = false --?
      c = '\n'
    end
    if c == '\n' then break
    elseif count_leading_spaces_p and c == ' ' then
      num_leading_spaces = num_leading_spaces + 1
    elseif count_leading_spaces_p and c == '\t' then
      num_leading_spaces = num_leading_spaces + 8
    elseif escape_char_p(c) then
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
          emit_leading_spaces(num_leading_spaces, insert_line_break_p)
        end
        r = r .. expand_escape(c)
        if c == '{' or c == '\n' then break end
      end
    else
      if blank_line_p then blank_line_p = false end
      if count_leading_spaces_p then
        count_leading_spaces_p = false
        emit_leading_spaces(num_leading_spaces, insert_line_break_p)
      end
      if c == '"' then check_verbatim_apostrophe_status() end
      r = r .. c
    end
  end
  if blank_line_p then
    --print('emitting blank line')
    emit_blank_line()
  else
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
  emit_verbatim(Troff2page_version); emit_newline()
  emit_verbatim(Troff2page_copyright_notice); emit_newline()
  emit_verbatim '(running on '
  emit_verbatim(_VERSION); emit_verbatim ')\n'
  emit_verbatim(Troff2page_website); emit_newline()
  emit_verbatim '-->\n'
  emit_verbatim '<head>\n'
  emit_verbatim '<meta charset="utf-8">\n'
  emit_external_title()
  link_stylesheets()
  link_scripts()
  emit_verbatim '<meta name=robots content="index,follow">\n'
  for _,h in pairs(Html_head) do emit_verbatim(h) end
  emit_verbatim '</head>\n'
  emit_verbatim '<body>\n'
  emit_verbatim '<div'
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
  --print('doing emit_blank_line with Outputting_to=', Outputting_to)
  if Outputting_to == 'troff' then Keep_newline_p=false; emit_newline()
  elseif Blank_line_macro then
    --print('emit_blank_line found Blank_line_macro')
    Keep_newline_p = false
    Previous_line_exec_p = true
    local it
    it = Macro_table[Blank_line_macro]
    if it then --print('BLM mac found');
      execute_macro_body(it); return end
    it = Request_table[Blank_line_macro]
    if it then --print('BLM req found');
      toss_back_char('\n'); it(); return end
  else emit_verbatim '<br>&#xa0;<br>'
  end
end

function emit_leading_spaces(num_leading_spaces, insert_line_break_p)
  if num_leading_spaces > 0 then
    Leading_spaces_number = num_leading_spaces
    if Leading_spaces_macro then
      local it
      if (function() it= Macro_table.Leading_spaces_macro; return it; end)()
      then execute_macro_body(it)
      elseif (function() it= Request_table.Leading_spaces_macro; return it; end)()
      then it()
      end
    else
      if insert_line_break_p then
        emit_verbatim '<!---***---><br>'
      end
      for j=1,Leading_spaces_number do
        emit '\\[htmlnbsp]'
      end
    end
  end
end

function emit_end_para()
  --print('In_para_p =', In_para_p)
  if In_para_p then
    --print('doing eep')
    In_para_p=false
    --print('doing emit_end_para')
    emit_verbatim '</p>\n'
    Margin_left = 0
    local it = Request_table['par@reset']
    if it then it() end
    --print('eep switch style to default')
    emit(switch_style())
    fill_mode()
    do_afterpar()
    --print('eep/ipp should be true', In_para_p)
    --print('eep setting ipp=false')
  end
end

function emit_para(opts)
  --print('doing emit_para')
  opts = opts or {}
  --print('emit_para calling eep')
  emit_end_para()
  emit_verbatim '<p'
  if opts.indent_p then emit_verbatim ' class=indent' end
  if opts.incremental_p then emit_verbatim ' class=incremental' end
  emit_verbatim '>'
  In_para_p=true
  Just_after_par_start_p = opts.par_start_p
  emit_newline()
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
