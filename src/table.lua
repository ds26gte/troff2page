-- last modified 2020-11-18

function table_do_global_options()
  --print('doing table_do_global_options')
  local x
  while true do
    x = string.match(read_one_line(), '^ *(.-) *$')
    table_do_global_option_1(x)
    if string.sub(x, -1) == ';' then
      break
    end
  end
end

function table_do_global_option_1(x)
  --print('doing table_do_global_option_1')
  flet({
       Current_troff_input = { buffer = string_to_table(x) }
     }, function()
     while true do
       ignore_char ','
       local w = read_word()
       --print('w=', w)
       if w == '' then break end
       if w == 'tab' then
         ignore_char '('
         ignore_spaces()
         Table_colsep_char = get_char()
         ignore_char ')'
       elseif w == 'box' or w == 'frame' or w == 'doublebox' or w == 'doubleframe' then
         Table_style.border = true
       elseif w == 'allbox' then
         Table_style.border = true; Table_cell_style.border = true
       elseif w == 'expand' then
         Table_options = Table_options .. ' width="100%"'
       elseif w == 'center' then
         Table_align = 'center'
       end
     end
   end)
end

function table_do_format_section()
  --print('doing table_do_format_section')
  Table_default_format_line = 0
  local x; local xn
  while true do
    x = string_trim_blanks(read_one_line())
    --print('x=', x)
    xn = #x
    Table_default_format_line = Table_default_format_line + 1
    table_do_format_1(x)
    if xn>0 and string.sub(x,xn,xn) == '.' then break end
  end
end

function table_do_format_1(x)
  --print('doing table_do_format_1', x)
  flet({
    Current_troff_input = make_bstream{buffer = string_to_table(x)}
  }, function()
    local row_hash_table = {}
    local cell_number = 0
    local w; local align; local font
    while true do
      w = read_word()
      if w then w=string_to_table(w) else w={} end
      align=false; font=false
      if #w == 0 then break end
      cell_number = cell_number+1
      if table_member('b', w) then font='B' end
      if table_member('i', w) then font='I' end
      if table_member('c', w) then align='center' end
      if table_member('l', w) then align='left' end
      if table_member('r', w) then align='right' end
      row_hash_table[cell_number] = {align = align, font = font}
    end
    if cell_number > Table_number_of_columns then
      Table_number_of_columns = cell_number
    end
    Table_format_table[Table_default_format_line] = row_hash_table
  end)
end

function table_do_rows()
  --print('doing table_do_rows')
  flet({
    Inside_table_text_block_p = false,
    Table_row_number = 1,
    Table_cell_number = 0
  }, function()
    local c
    while true do
      c = snoop_char()
      if not c then break end
      --print('while loop saw', c)
      if Table_cell_number==0 then
        if c == Control_char then
          get_char()
          local w = read_word()
          --print('found cmd inside table', w)
          if not w then no_op()
          elseif w=='TE' then
            read_troff_line(); break
          elseif w=='TH' then
            Reading_table_header_p=false
          else
            toss_back_string(w)
            toss_back_char(Control_char)
            process_line()
          end
        elseif c=='_' or c=='-' or c=='=' then read_troff_line()
          emit_verbatim '<tr><td valign=top colspan='
          emit_verbatim(Table_number_of_columns)
          emit_verbatim '><hr></td></tr>\n'
        else
          emit_verbatim '<tr'
          if Reading_table_header_p then emit_verbatim ' class=tableheader' end
          emit_verbatim '>'
          table_do_cell()
        end
      elseif c=='\n' then get_char()
        emit_verbatim '\n</tr>\n'
        Table_row_number=Table_row_number+1
        Table_cell_number=0
      else table_do_cell()
      end
    end
  end)
end

function table_do_cell()
  --print('doing table_do_cell')
  Table_cell_number=Table_cell_number+1
  local cell_format_info =
  Table_format_table[math.min(Table_row_number, Table_default_format_line)][Table_cell_number]
  local align, font = cell_format_info.align, cell_format_info.font
  local c; local it
  emit_verbatim '\n<td valign=top'
  if align then emit_verbatim ' align='; emit_verbatim(align) end
  if Table_cell_style.border then emit_verbatim ' style="border: 1px solid black"' end
  emit_verbatim '>'
  if font then emit(switch_font(font)) end
  local cell_contents = ''
  local more
  while true do
    c=snoop_char()
    if Inside_table_text_block_p then
      if c=='T' then
        get_char()
        c=snoop_char()
        if c=='}' then
          get_char()
          Inside_table_text_block_p=false
        else
          toss_back_char('T')
          more = read_one_line()
          cell_contents = cell_contents .. more .. '\n'
        end
      else
        more = read_one_line()
        cell_contents = cell_contents .. more .. '\n'
      end
    else
      more = read_till_chars({Table_colsep_char, 'T', '\n'})
      cell_contents = cell_contents .. more
      if c==Table_colsep_char then get_char(); break end
      if c=='\n' then break end
      if c=='T' then
        get_char()
        c=snoop_char()
        if c=='{' then
          read_troff_line()
          Inside_table_text_block_p=true
        else
          cell_contents = cell_contents .. 'T'
        end
      end
    end
  end
  troff2page_string(cell_contents)
  if font then emit(switch_font()) end
  emit_verbatim '</td>'
end
