-- last modified 2017-08-26

function defrequest(w, th)
  if Macro_table[w] then
    Macro_table[w] = nil
  end
  Request_table[w] = th
end

function deftmacro(w, ss)
  --print('doing deftmacro', w)
  Macro_table[w] = ss
end

function call_ender(ender)
  if not Exit_status and ender ~= '.' then
    toss_back_char('\n')
    execute_macro(ender)
  end
end

function all_args()
  local r = ''
  local first_p = true
  for i=2,#Macro_args do
    if first_p then first_p=false
    else r = r .. ' '
    end
    r = r .. Macro_args[i]
  end
  return r
end

function initialize_macros()
  defrequest('bp', function()
    read_troff_line()
    if not Current_diversion then do_eject() end
  end)

  defrequest('rm', function()
    local w = read_args()[1]
    Request_table[w] = nil
    Macro_table[w] = nil
    String_table[w] = nil
  end)

  defrequest('blm', function()
    local w = read_args()[1]
    --print('doing blm', w)
    --print('its a mac=', Macro_table[w])
    Blank_line_macro = w or false
  end)

  defrequest('lsm', function()
    Leading_spaces_macro = read_args()[1]
  end)

  defrequest('em', function()
    End_macro = read_args()[1]
  end)

  defrequest('de', function()
    local args = read_args()
    local w = args[1]
    --print('doing de', w)
    local ender = args[2] or '.'
    deftmacro(w, collect_macro_body(w, ender))
    call_ender(ender)
  end)

  defrequest('shift', function()
    local args = read_args()
    local n = 1
    if #args > 0 then
      n = tonumber(args[1])
    end
    for i = 1,n do
      table.remove(Macro_args, 2)
    end
  end)

  defrequest('ig', function()
    local ender = read_args()[1] or '.'
    flet({
      Turn_off_escape_char_p = true
    }, function()
      local contents = collect_macro_body('collecting_ig', ender)
      if ender == '##' then
        eval_in_lua(contents)
      end
    end)
  end)

  defrequest('als', function()
    local args = read_args()
    local new, old = args[1], args[2]
    --print('doing als', old, new)
    local it
    it = Macro_table[old]
    if it then deftmacro(new, it)
    else
      it = Request_table[old]
      if it then defrequest(new, it)
      else
        terror('als: unknown rhs %s', old)
      end
    end
  end)

  defrequest('rn', function()
    local args = read_args()
    local old, new = args[1], args[2]
    --print('doing rn', old, new)
    local it
    it = Macro_table[old]
    if it then
      deftmacro(new, it); deftmacro(old, nil)
    else
      it = Request_table[old]
      if it then
        defrequest(new, it); defrequest(old, nil)
      else
        terror('rn: unknown lhs %s', old)
      end
    end
  end)

  defrequest('am', function()
    local args = read_args()
    local w = args[1]
    local ender = args[2] or '.'
    local extra_macro_body = collect_macro_body(w, ender)
    local it
    it = Macro_table[w]
    if it then
      table_nconc(it, extra_macro_body)
      --deftmacro(w, it .. extra_macro_body)
    else
      it = Request_table[w]
      if it then
        local tmp_old_req, tmp_new_mac = gen_temp_string(), gen_temp_string()
        defrequest(tmp_old_req, it)
        table.insert(extra_macro_body, 1, '.' .. tmp_old_req .. ' \\$*')
        deftmacro(tmp_new_mac, extra_macro_body)
        defrequest(w, function()
          execute_macro(tmp_new_mac)
        end)
      else
        deftmacro(w, extra_macro_body)
      end
    end
    call_ender(ender)
  end)

  defrequest('eo', function()
    Turn_off_escape_char_p = true
    read_troff_line()
  end)

  defrequest('ec', function()
    Escape_char = get_first_non_space_char_on_curr_line() or '\\'
    Turn_off_escape_char_p = false
  end)

  defrequest('ecs', function()
    read_troff_line()
    Saved_escape_char = Escape_char
  end)

  defrequest('ecr', function()
    read_troff_line()
    Escape_char = Saved_escape_char or '\\'
  end)

  defrequest('cc', function()
    Control_char = get_first_non_space_char_on_curr_line() or '.'
  end)

  defrequest('c2', function()
    No_break_control_char = get_first_non_space_char_on_curr_line() or "'"
  end)

  defrequest('asciify', function()
    local arg1 = read_args()[1]
    local div = Diversion_table[arg1]
    --print('doing asciify of', div)
    local value = div.value
    --print('value(1) =', value)
    if not value then
      value = (div.stream):get_output_stream_string()
    end
    --print('value(2) =', value)
    value = string.gsub(value, '^(%s*)<br>', '%1\n')
    value = string.gsub(value, '<br>(%s*)$', '\n%1')
    div.value = value
  end)

  defrequest('di', function()
    local w = read_args()[1]
    if w then
      local o = make_string_output_stream()
      Diversion_table[w] = {stream = o, oldstream = Out, olddiversion = Current_diversion}
      Out = o
      Current_diversion = w
    else
      local curr_div = Diversion_table[Current_diversion]
      if curr_div then
        Out = curr_div.oldstream
        Current_diversion = curr_div.olddiversion
      end
    end
  end)

  defrequest('da', function()
    local w = read_args()[1]
    if not w then terror('da: name missing') end
    local div = Diversion_table[w]
    local div_stream
    if div then div_stream = div.stream
      -- what if existing divn has already been retrieved and its stream closed?
    else div_stream = make_string_output_stream()
      Diversion_table[w] = {stream = div_stream, oldstream = Out, olddiversion = Current_diversion}
    end
    Out = div_stream
    Current_diversion = w
      --print('.da set Out to', Out)
  end)

  defrequest('ds', function()
    local w = expand_args(read_word())
    local s = expand_args(read_troff_string_line())
    defstring(w, function(...)
      local args = {...}
      table.insert(args, 1, w)
      return flet({
        Macro_args = args
      }, function()
        return expand_args(s)
      end)
    end)
  end)

  defrequest('char', function()
    ignore_spaces()
    if get_char() ~= Escape_char then terror('char') end
    local glyph_name = read_escaped_word()
    local unicode_char = unicode_escape(glyph_name)
    local s = expand_args(read_troff_string_line())
    defglyph(unicode_char or glyph_name)
  end)

  defrequest('substring', function()
    local args = read_args()
    local s = args[1]
    local str = String_table[s]()
    local str_new
    local n = #str
    local n1 = tonumber(args[2])
    local n2 = args[3]
    if n2 then n2 = tonumber(n2) end
    ;
    if not n2 then n2 = n-1 end
    ;
    if n1 < 0 then n1 = n + n1 end
    if n2 < 0 then n2 = n + n2 end
    str_new = string.sub(str, n1, n2 + 1)
  end)

  defrequest('length', function()
    local args = read_args()
    get_counter_named(args[1]).value = #(args[2])
  end)

  defrequest('PSPIC', function()
    local align
    local ps_file
    local width
    local height
    local args = read_args()
    local w = args[1]
    if not w then terror('pspic')
    elseif w == '-L' then align = 'left'
    elseif w == '-I' then read_word(); align='left'
    elseif w == '-R' then align='right'
    end
    if align then ps_file = read_word()
    else align='center'; ps_file = w
    end
    width=args[2]; height=args[3]
    emit_verbatim '<div align='
    emit_verbatim(align)
    emit_verbatim '>'
    flet({
      Groff_image_options=false
    }, function()
      call_with_image_stream(function(o)
        o:write('.mso pspic.tmac\n')
        o:write('.PSPIC ', ps_file)
        if width then o:write(' ', width) end
        if height then o:write(' ', height) end
        o:write('\n')
      end)
    end)
    emit_verbatim '</div>'
  end)

  defrequest('PIMG', function()
    local align = read_word()
    local img_file
    local width
    local height
    if align=='-L' or align=='-C' or align=='-R' then img_file=read_word()
    else img_file=align; align='-C'
    end
    width=read_length_in_pixels()
    height=read_length_in_pixels()
    read_troff_line()
    if align=='-L' then align='left'
    elseif align=='-C' then align='center'
    elseif align=='-R' then align='right'
    end
    emit_verbatim '<div align='
    emit_verbatim(align)
    emit_verbatim '>\n'
    emit_verbatim '<img src="'
    emit_verbatim(img_file)
    emit_verbatim '"'
    if width ~= 0 then emit_verbatim ' width='; emit_verbatim(width) end
    if height ~= 0 then emit_verbatim ' height='; emit_verbatim(height) end
    emit_verbatim '>\n'
    emit_verbatim '</div>\n'
  end)

  defrequest('IMG', Request_table.PIMG)

  defrequest('tmc', do_tmc)

  defrequest('tm', function()
    --print('doing tm')
    do_tmc(true)
  end)

  defrequest('sy', function()
    ignore_spaces()
    local cmd = with_output_to_string(function(o)
      o:write(expand_args(read_troff_line()), '\n')
    end)
    --print('doing unix of', cmd)
    local systat = os.execute(cmd)
    if systat==true then systat=0
    elseif not(tonumber(systat)) then systat=1
    end
    (get_counter_named 'systat').value = systat
  end)

  defrequest('pso', function()
    ignore_spaces()
    os.execute(with_output_to_string(function(o)
      flet({
        Turn_off_escape_char_p=true
      }, function()
        o:write(expand_args(read_troff_line()), ' > ', Pso_temp_file, '\n')
      end)
    end))
    troff2page_file(Pso_temp_file)
  end)

  defrequest('FS', function()
    local fnmark = read_args()[1]
    local fno
    local fntag
    if fnmark then
      fntag = '\\&' .. fnmark .. ' '
    elseif This_footnote_is_numbered_p then
      This_footnote_is_numbered_p = false
      fno = Footnote_count
    end
    local fnote_chars = {}
    local x
    while true do
      x = read_one_line()
      if string.find(x, '%.FE') == 1 then break end
      table_nconc(fnote_chars, string_to_table(x))
      table_nconc(fnote_chars, {'\n'})
    end
    table.insert(Footnote_buffer, {tag=fntag, number=fno, text=fnote_chars})
  end)

  defrequest('RS', function()
    read_troff_line()
    --print('RS calling eep')
    emit_end_para()
    emit_verbatim '<blockquote>'
    emit_para()
  end)

  defrequest('RE', function()
    read_troff_line()
    emit_end_para()
    emit_verbatim '</blockquote>\n'
    emit_para()
  end)

  defrequest('DE', function()
    read_troff_line()
    stop_display()
  end)

  defrequest('par@reset', function()
    no_op()
  end)

  defrequest('LP', function()
    read_troff_line()
    emit_newline()
    --print('LP calling emit_para')
    emit_para{par_start_p = true}
  end)

  defrequest('RT', function()
    --print('RT calling LP')
    Request_table.LP()
  end)

  defrequest('lp', Request_table.LP)

  defrequest('PP', function()
    read_troff_line()
    emit_newline()
    emit_para{par_start_p = true, indent_p = true}
  end)

  defrequest('P', Request_table.PP)

  defrequest('HP', Request_table.PP)

  defrequest('pause', function()
    read_troff_line()
    emit_newline()
    emit_para{par_start_p = true, incremental_p = true}
  end)

  defrequest('sp', function()
    local num = read_number_or_length('v')
    if num == 0 then
      num = point_equivalent_of('v')
    end
    read_troff_line()
    emit_verbatim '<br style="margin-top: '
    emit_verbatim(num)
    emit_verbatim 'px; margin-bottom: '
    emit_verbatim(num)
    emit_verbatim 'px">\n'
  end)

  defrequest('br', function()
    read_troff_line()
    emit_verbatim '<br>'
  end)

  defrequest('ti', function()
    toss_back_string(expand_args(read_word()))
    local arg = read_length_in_pixels()
    read_troff_line()
    if arg>0 then
      emit_verbatim '<br>'
      emit_nbsp(math.ceil(arg/5))
    end
  end)

  defrequest('in', function()
    local sign = read_opt_sign()
    local num = read_number_or_length('m')
    read_troff_line()
    if num then
      if sign=='+' then Margin_left=Margin_left+num
      elseif sign=='-' then Margin_left=Margin_left-num
      else Margin_left=num
      end
    end
    emit_verbatim '<p '
    specify_margin_left_style()
    emit_verbatim '>'
  end)

  defrequest('TL', function()
    read_troff_line()
    --print('TL calling eep')
    emit_end_para()
    get_header(function(title)
      if title ~= '' then
        store_title(title, {emit_p = true})
      end
    end)
  end)

  defrequest('HTL', function()
    read_troff_line()
    local title = read_one_line()
    store_title(title, {preferred_p=true})
  end)

  defrequest('@AU', function()
    author_info('italic')
  end)

  defrequest('AU', function()
    Request_table['@AU']()
  end)

  defrequest('AI', author_info)

  defrequest('AB', function()
    local w = read_args()[1]
    --print('AB calling eep')
    emit_end_para()
    if w ~= 'no' then
      emit_verbatim '<div align=center class=abstract><i>ABSTRACT</i></div>'
      emit_para()
    end
    emit_verbatim '<blockquote>'
  end)

  defrequest('AE', function()
    read_troff_line()
    emit_verbatim '</blockquote>'
  end)

  defrequest('NH', function()
    Request_table['@NH']()
  end)

  defrequest('SH', function()
    execute_macro('@SH')
  end)

  defrequest('@NH', function()
    local lvl = read_args()[1]
    local num = tonumber(lvl) or 1
    emit_section_header(num, {numbered_p = true})
  end)

  defrequest('@SH', function()
    --print('doing @SH')
    local lvl = read_args()[1]
    local num = tonumber(lvl) or 1
    emit_section_header(num)
    --print('@SH done')
  end)

  defrequest('TH', function()
    defrequest('TH', nil)
    nb_macro_package('man')
    local function disabled_TH()
      read_troff_line()
      twarning('Calling .TH twice in man page')
    end
    local it; local args
    it = find_macro_file('man.local')
    if it then troff2page_file(it) end
    it = find_macro_file('pca-t2p-man.tmac')
    if it then troff2page_file(it) end
    if (function() it = Macro_table.TH; return it end)''
    then defrequest('TH', disabled_TH)
      args = read_args()
      flet({
        Macro_args = table.insert(args, 1, 'TH')
      }, function() execute_macro_body(it) end)
    elseif (function() it = Request_table.TH; return it end)''
    then it()
    else twarning("Couldn't find pca-t2p-man.tmac is any macro directory")
      defrequest('TH', disabled_TH)
      defrequest('SH', function() emit_section_header(1, {man_header_p = true}) end)
      defrequest('SS', function() emit_section_header(2, {man_header_p = true}) end)
      args = read_args()
      it = args[1]
      if it then
        it = string_trim_blanks(it)
        if it ~= '' then store_title(it, {emit_p = true}) end
        it = args[3]
        if it then
          it = string_trim_blanks(it)
          if it ~= '' then defstring('DY', function() return it end) end
        end
      end
    end
  end)

  defrequest('SC', function()
    if not Numreg_table.bell_localisms then
      Numreg_table.bell_localisms = {value = 0}
    end
    emit_section_header(1, {numbered_p = true})
  end)

  defrequest('P1', function()
    if Numreg_table.bell_localisms then
      start_display 'L'
      emit(switch_font 'C')
    end
  end)

  defrequest('P2', function()
    if Numreg_table.bell_localisms then
      stop_display()
    end
  end)

  defrequest('EX', function()
--    print('doing EX')
    start_display('L')
    emit(switch_font 'C')
  end)

  defrequest('EE', function()
--    print('doing EE')
    read_troff_line()
    stop_display()
  end)

  defrequest('ND', function()
    local w = expand_args(read_troff_line())
    defstring('DY', function() return w end)
  end)

  defrequest('CSS', function()
    local f = read_args()[1]
    if not table_member(f, Stylesheets) then
      flag_missing_piece 'stylesheet'
    end
    write_aux('nb_stylesheet("', f, '")')
  end)

  defrequest('REDIRECT', function()
    if not Redirected_p then flag_missing_piece 'redirect' end
    local f = read_args()[1]
    write_aux('nb_redirect("', f, '")')
  end)

  defrequest('SLIDES', function()
    if not Slides_p then flag_missing_piece 'slides' end
    write_aux('nb_slides()')
  end)

  defrequest('gcolor', function()
    local c = read_args()[1]
    switch_glyph_color(c)
  end)

  defrequest('fcolor', function()
    local c = read_args()[1]
    switch_fill_color(c)
  end)

  defrequest('I', function()
    font_macro 'I'
  end)

  defrequest('B', function()
    font_macro 'B'
  end)

  defrequest('C', function()
    font_macro 'C'
  end)

  defrequest('CW', Request_table.C)

  defrequest('R', function()
    font_macro()
  end)

  defrequest('RI', function()
    man_alternating_font_macro(false, 'I')
  end)

  defrequest('IR', function()
    man_alternating_font_macro('I', false)
  end)

  defrequest('BI', function()
    man_alternating_font_macro('B', 'I')
  end)

  defrequest('IB', function()
    man_alternating_font_macro('I', 'B')
  end)

  defrequest('RB', function()
    man_alternating_font_macro(false, 'B')
  end)

  defrequest('BR', function()
    man_alternating_font_macro('B', false)
  end)

  defrequest('DC', function()
    local args = read_args()
    local big_letter = args[1]
    local extra = args[2]
    local color = args[3]
    emit(switch_glyph_color(color))
    emit_verbatim '<span class=dropcap>'
    emit(big_letter)
    emit_verbatim '</span>'
    emit(switch_glyph_color '')
    if extra then emit(extra) end
    emit_newline()
  end)
  --BX
  --B1
  --B2

  defrequest('ft', function()
    local f = read_args()[1]
    emit(switch_font(f))
  end)

  defrequest('fam', function()
    local f = read_args()[1]
    emit(switch_font_family(f))
  end)

  defrequest('LG', function()
    read_troff_line()
    emit(switch_size('+2'))
  end)

  defrequest('SM', function()
    read_troff_line()
    emit(switch_size('-2'))
  end)

  defrequest('NL', function()
    read_troff_line()
    emit(switch_size(false))
  end)

  --URL

  defrequest('TAG', function()
--    print('doing TAG')
    local args = read_args()
--    print('args=', table_to_string(args))
    local node = 'TAG:' .. args[1]
    local pageno = Current_pageno
--    print('pageno=', pageno)
    local tag_value = args[2] or pageno
--    print('tag_value=', tag_value)
    emit(anchor(node))
    emit_newline()
    nb_node(node, pageno, tag_value)
    write_aux('nb_node("', node, '",', pageno, ',', tag_value, ')')
--    print('TAG done')
  end)

  --ULS
  --ULE
  --OLS
  --OLE
  --LI
  --HR
  --HTML
  --CDS
  --CDE
  --QP
  --QS
  --QE
  --IP
  --TP
  --PS
  --EQ
  --TS

  defrequest('TS', function()
    local args = read_args()
    flet({
      Reading_table_header_p = (args[1] == 'H'),
      Reading_table_p = true,
      Table_format_table = {},
      Table_default_format_line = 0,
      Table_row_number = 0,
      Table_cell_number = 0,
      Table_colsep_char = '\t',
      Table_options = ' cellpadding=2',
      Table_number_of_columns = 0,
      Table_align = false
    }, function()
      table_do_global_options()
      table_do_format_section()
      emit_verbatim '<div'
      if Table_align then emit_verbatim ' align='; emit_verbatim(Table_align) end
      emit_verbatim '>\n'
      emit_verbatim '<table'
      Out:write(Table_options)
      emit_verbatim '>\n'
      table_do_rows()
      emit_verbatim '</table>\n'
      emit_verbatim '</div>'
      Table_format_table={}
    end)
  end)

  defrequest('if', function()
    --print('doing IF')
    ignore_spaces()
    if if_test_passed_p() then
      --print('if then')
      ignore_spaces()
    else
      --print('if else')
      ignore_branch()
    end
    --print('done IF')
  end)

  defrequest('ie', function()
    --print('doing IE')
    ignore_spaces()
    if if_test_passed_p() then --print('ie then');
      ignore_spaces()
    else Cascaded_if_p = true; --print('ie else');
      ignore_branch()
    end
  end)

  defrequest('el', function()
    --print('doing EL')
    ignore_spaces()
    if Cascaded_if_p then Cascaded_if_p = false
    else ignore_branch()
    end
  end)

  defrequest('nop', function()
    ignore_spaces()
  end)

  defrequest('while', function()
    ignore_spaces()
    local test = read_test(); local body = read_block()
    while true do
      toss_back_string(test)
      if if_test_passed_p() then
        troff2page_string(body)
        if Exit_status then
          if Exit_status == 'break' then Exit_status = false; break
          elseif Exit_status == 'continue' then Exit_status = false
          else break
          end
        end
      else break
      end
    end
  end)

  defrequest('do', function()
    ignore_spaces()
    toss_back_char('.')
  end)

  defrequest('nx', function()
    local args = read_args()
    if #args > 0 then troff2page_file(args[1]) end
    Exit_status = 'nx'
  end)

  defrequest('return', function()
    read_troff_line()
    Exit_status = 'return'
  end)

  defrequest('ex', function()
    read_troff_line()
    Exit_status = 'ex'
  end)

  defrequest('ab', function()
    do_tmc('newline')
    Exit_status = 'ex'
  end)

  defrequest('break', function()
    read_troff_line()
    Exit_status='break'
  end)

  defrequest('continue', function()
    read_troff_line()
    Exit_status='continue'
  end)

  defrequest('nf', function()
    read_troff_line()
    if not Previous_line_exec_p then
      emit_verbatim '<p '
      specify_margin_left_style()
      emit_verbatim '>\n'
    end
    unfill_mode()
  end)

  defrequest('fi', function()
    read_troff_line()
    fill_mode()
    emit_verbatim '<p>'
  end)

  defrequest('so', function()
    local f = read_args()[1]
    if Macro_package == 'man' then
      local g = '../' .. f
      if probe_file(g) then f = g end
    end
    troff2page_file(f)
  end)

  defrequest('mso', function()
    local f = read_args()[1]
    --print('MSO ', f)
    if f then f = find_macro_file(f) end
    --print('MSO2 ', f)
    if f then troff2page_file(f) end
  end)

  --HX
  --DS
  --LD
  --ID
  --BD
  --CD
  --RD

  defrequest('defcolor', function()
    local ident = read_word()
    local rgb_color = read_rgb_color()
    read_troff_line()
    Color_table[ident] = rgb_color
  end)

  defrequest('ce', function()
    local arg1 = read_args()[1]
    local n = (arg1 and tonumber(arg1) or 1)
    if n<=0 then
      if Lines_to_be_centered>0 then Lines_to_be_centered=0; emit_verbatim '</div>' end
    else Lines_to_be_centered=n; emit_verbatim '<div align=center>'
    end
    emit '\n'
  end)

  defrequest('nr', function()
    local n = read_word()
    --print('doing nr', n)
    local c = get_counter_named(n)
    if c.thunk then terror("nr: can't set readonly number register %s", n) end
    local sign = read_opt_sign()
    local num = read_number_or_length()
    read_troff_line()
    if not num then return
    elseif sign == '+' then c.value = c.value + num
    elseif sign == '-' then c.value = c.value - num
    else c.value = num
    end
  end)

  defrequest('af', function()
    local args = read_args()
    local c = get_counter_named(args[1])
    local f = args[2]
    read_troff_line()
    c.format = f
  end)

  defrequest('ev', function()
    local ev_new_name = read_word()
    if ev_new_name then ev_push(ev_new_name)
    else ev_pop()
    end
  end)

  defrequest('evc', function()
    local ev_rhs_name = read_args()[1]
    local ev_rhs = ev_named(ev_rhs_name)
    ev_copy(Ev_stack[1], ev_rhs)
  end)

  defrequest('open', function()
    local args = read_args()
    local stream_name = args[1]
    local file_name = args[2]
    troff_open(stream_name, file_name)
  end)

  defrequest('close', function()
    local stream_name = read_args()[1]
    troff_close(stream_name)
  end)

  defrequest('writec', function()
    do_writec()
  end)

  defrequest('write', function()
    do_writec 'newline'
  end)

  defrequest('writem', function()
    local stream_name = expand_args(read_word())
    local macro_name = expand_args(read_word())
    local out = Output_streams[stream_name]
    --print('doing writem', macro_name)
    write_troff_macro_to_stream(macro_name, out)
  end)

  defrequest('troff2info', function()
    read_troff_line()
    Convert_to_info_p = true
  end)

  defrequest('AM', function()
    accent_marks()
  end)

  defrequest('DEBUG', function()
    local w = read_args()[1] or ''
    local it = tonumber(w)
    if it then Debug_p = (it>0)
    else it = string.lower(w)
      Debug_p = (it=='on') or (it=='t') or (it=='true') or (it=='y') or (it=='yes')
    end
  end)

end
