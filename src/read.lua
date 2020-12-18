-- last modified 2020-12-17

function make_bstream(opts)
  return {
    stream = opts.stream,
    buffer = opts.buffer or {}
  }
end

function toss_back_char(c)
  --io.write('toss_back_char "', c, '"\n')
  table.insert(Current_troff_input.buffer, 1, c)
end

function snoop_char()
  local c = get_char('dont_translate')
  --print('snoop_char ->', c, '<-')
  if c then toss_back_char(c) end
  return c
end

function read_till_chars(delims, eat_delim_p)
  -- read until one of the delims is found.
  -- if eat_delim_p, eat the delim.
  -- the delim will not be part of the returned string
  local newline_is_delim_p = table_member('\n', delims)
  local r = ''
  local c
  while true do
    c = snoop_char()
    if not c then
      if newline_is_delim_p then
        if r == '' then return c
        else return r
        end
      else
        error('read_till_chars: could not find closer' .. r)
      end
    elseif table_member(c, delims) then
      if eat_delim_p then get_char() end
      return r
    else get_char()
      r = r .. c
    end
  end
end

function read_till_char(delim, eat_delim_p)
  return read_till_chars({delim}, eat_delim_p)
end

function read_one_line()
  return read_till_char('\n', true)
end

function toss_back_string(s)
  --print('toss_back_string ', s)
  local buf = Current_troff_input.buffer
  for i = #s, 1, -1 do
    table.insert(buf, 1, string.sub(s, i, i))
  end
end

function toss_back_line(s)
  --print('toss_back_line ', s)
  toss_back_char '\n'
  toss_back_string(s)
end

function ignore_spaces()
  local c
  while true do
    c = snoop_char()
    if not c then return
    elseif c == ' ' or c == '\t' then get_char()
    else return
    end
  end
end

function ignore_char(c)
  if not (c == ' ' or c == '\t') then
    ignore_spaces()
  end
  local d = snoop_char()
  if not d then return
  elseif d == c then get_char()
  end
end

function escape_char_p(c)
  --if (c==Escape_char) then print('Turn_off_escape_char_p=', Turn_off_escape_char_p) end
  return not Turn_off_escape_char_p and c == Escape_char
end

function read_word()
  --print('doing read_word')
  ignore_spaces()
  local c = snoop_char()
  --io.write('read_word found ->', c , '<-\n')
  if (not c) or c == '\n' then return false
  elseif c == '"' then return read_quoted_phrase()
  elseif escape_char_p(c) then
    get_char()
    local c2 = snoop_char()
    if not c2 then return Escape_char
    elseif c2 == '\n' then get_char(); return read_word()
    else toss_back_char(c); return read_bare_word()
    end
  else return read_bare_word()
  end
end

function read_rest_of_line()
  ignore_spaces()
  local r = ''
  local c
  while true do
    c = snoop_char()
    if not c or c == '\n' then
      c = get_char(); break
    else
      c = get_char(); r = r .. c
    end
  end
  return expand_args(r)
end

function read_quoted_phrase()
  get_char() -- read the "
  return flet({
    Reading_quoted_phrase_p = true
  }, function()
    local read_escape_p = false
    local r = ''
    local c
    while true do
      c = snoop_char()
      if read_escape_p then
        read_escape_p = false
        c = get_char()
        if c == '\n' then no_op()
        else r = r .. Escape_char .. c
        end
      elseif escape_char_p(c) then
        read_escape_p = true
        get_char()
      elseif c == '"' or c == '\n' then
        if c == '"' then get_char() end
        break
      else
        c = get_char()
        r = r .. c
      end
    end
    return r
  end)
end

function read_bare_word()
  --print('doing read_bare_word')
  local read_escape_p = false
  local bracket_nesting = 0
  local r = ''
  local c
  while true do
    c = snoop_char()
    if read_escape_p then
      read_escape_p = false
      if not c then break
      elseif c == '\n' then get_char()
      else
        c = get_char()
        r = r .. Escape_char .. c
      end
    elseif not c or c == ' ' or c == '\t' or c == '\n' or
      (Reading_table_p and (c == '(' or c == ',' or c == ';' or c == '.')) or
      (Reading_string_call_p and c == ']' and bracket_nesting == 0) then
      break
    elseif escape_char_p(c) then
      read_escape_p = true
      get_char()
    else
      c = get_char()
      if Reading_string_call_p then
        if c == '[' then bracket_nesting = bracket_nesting+1
        elseif c == ']' then bracket_nesting = bracket_nesting-1
        end
      end
      r = r .. c
    end
  end
  --io.write('read_bare_word => ->', r, '<-\n')
  return r
end

function read_troff_line(stop_before_newline_p)
  --print('doing read_troff_line', stop_before_newline_p)
  local read_escape_p = false
  local r = ''
  local c
  while true do
    c = snoop_char()
    if not c then break end
    if c == '\n' and not read_escape_p then
      if not stop_before_newline_p then get_char() end
      break
    end
    if read_escape_p then
      read_escape_p = false
      if c == '\n' then get_char()
      else
        c = get_char()
        r = r .. Escape_char .. c
      end
    elseif escape_char_p(c) then
      read_escape_p = true
      get_char()
    else
      c = get_char()
      r = r .. c
    end
  end
  --print('read_troff_line retng', r)
  return r
end

function read_troff_string_line()
  ignore_spaces()
  local c = snoop_char()
  if not c then return ''
  else
    if c == '"' then get_char() end
    return read_troff_line()
  end
end

function read_troff_string_and_args()
  local c = get_char()
  if c == '(' then
    local c1 = get_char(); local c2 = get_char()
    return c1..c2, {}
  elseif c == '[' then
    return flet({
      Reading_string_call_p = true
    }, function()
      local s = expand_args(read_word())
      local r = {}
      while true do
        ignore_spaces()
        local c = snoop_char()
        if not c then terror 'read_troff_string_and_args: string too long'
        elseif c == '\n' then get_char()
        elseif c == ']' then get_char(); break
        else table.insert(r, expand_args(read_word()))
        end
      end
      return s, r
    end)
  else return c, {}
  end
end

function if_test_passed_p()
  local res=false
  local c = get_char()
  if c == "'" or c == '"' then
    local left = expand_args(read_till_char(c, 'eat_delim'))
    local right = expand_args(read_till_char(c, 'eat_delim'))
    res = (left == right)
  elseif c == '!' then --print('itpp found !');
    res= not(if_test_passed_p())
  elseif c == 'n' then res= false
  elseif c == 't' then res= true
  elseif c == 'r' then res= Numreg_table[read_word()]
  elseif c == 'c' then res= Color_table[read_word()]
  elseif c == 'd' then local w = expand_args(read_word())
    res= (Request_table[w] or Macro_table[w] or String_table[w])
  elseif c == 'o' then twarning 'if: oddness of pageno shouldn\'t be relevant for HTML'
    res= ((Current_pageno%2) ~= 0)
  elseif c == 'e' then twarning 'if: oddness of pageno shouldn\'t be relevant for HTML'
    res= ((Current_pageno%2) == 0)
  elseif c == '(' then toss_back_char(c)
    res= ((read_arith_expr{stop = true}) > 0)
  elseif c == Escape_char or string.find(c, '%d') or c == '+' or c == '-' then
    --print('itpp found', c)
    toss_back_char(c)
    res= ((read_arith_expr()) > 0)
  else res= false
  end
  --print('if_test_passed_p retng', res)
  return res
end

function read_opt_pipe()
  ignore_spaces()
  local c = snoop_char()
  if not c then return false
  elseif c == '|' then return get_char()
  else return false
  end
end

function read_arith_expr(opts)
  opts=opts or {}
  local acc = 0
  local unit_already_read_p = false
  while true do
    local c = snoop_char()
    --if acc ~=0 then print('rae continuing with', c, acc) end
    if not c then break end
    if c == '+' then get_char(); ignore_spaces()
      acc = acc + read_arith_expr{stop = true}
    elseif c == '-' then get_char(); ignore_spaces()
      acc = acc - read_arith_expr{stop = true}
    elseif c == '*' then get_char(); ignore_spaces()
      acc = acc * read_arith_expr{stop = true}
    elseif c == '/' then get_char(); ignore_spaces()
      acc = acc / read_arith_expr{stop = true}
    elseif c == '%' then get_char(); ignore_spaces()
      acc = acc % read_arith_expr{stop = true}
    elseif c == '<' then get_char()
      --print('rae found lt')
      local proc; local c = snoop_char()
      if c == '=' then get_char();
        proc = function(x,y) return x <= y end
      elseif c == '?' then get_char();
        proc = math.min
      else
        proc = function(x,y) return x < y end
      end
      ignore_spaces()
      local r = proc(acc, read_arith_expr{stop = true})
      if c == '?' then acc = r
      else acc = bool_to_num(r)
      end
    elseif c == '>' then get_char()
      --print('rae encd gt')
      local proc; local c = snoop_char()
      if c == '=' then get_char();
        proc = function(x,y) return x >= y end
      elseif c == '?' then get_char();
        proc = math.max
      else
        proc = function(x,y) return x > y end
      end
      ignore_spaces()
      local r = proc(acc, read_arith_expr{stop = true})
      if c == '?' then acc = r
      else acc = bool_to_num(r)
      end
    elseif c == '=' then get_char()
      if snoop_char() == '=' then get_char() end
      ignore_spaces()
      acc = bool_to_num(acc == read_arith_expr{stop = true})
    elseif c == '(' then
      --print('rae encd lparen')
      get_char(); ignore_spaces()
      acc = read_arith_expr{inside_paren_p = true}; ignore_spaces()
      --print('paren acc=', acc)
      local c = get_char()
      if c ~= ')' then terror('bad arithmetic parenthetic expression %s', c) end
      ignore_spaces()
      if opts.stop then break end
    elseif c == '&' then get_char(); ignore_spaces()
      local rhs = read_arith_expr{stop = true}
      acc = bool_to_num(acc>0 and rhs>0)
    elseif c == ':' then get_char(); ignore_spaces()
      local rhs = read_arith_expr{stop = true}
      acc = bool_to_num(acc>0 or rhs>0)
    elseif string.find(c, '%d') or c == '.' then get_char()
      --print('rae encd num')
      local r = c
      local dot_read_p = (c == '.')
      local e_read_p = false
      local e_sign_read_p = false
      local unit = 1
      while true do
        c = snoop_char()
        if not c then break end
        if c == '.' then
          if dot_read_p then break end
          dot_read_p = true; get_char()
          r =  r..c
        elseif c == 'e' and not e_read_p then
          e_read_p = true; get_char()
          r = r..c
        elseif (c == '+' or c == '-') and e_read_p and not e_sign_read_p then get_char()
          e_sign_read_p = true
          r = r..c
        elseif string.find(c, '%d') then get_char()
          r = r..c
        elseif string.match(c, Unit_pattern) and not unit_already_read_p then get_char()
          unit_already_read_p = true
          unit = Gunit[c]
          break
        else break
        end
      end
      acc = tonumber(r) * unit
      --print('num acc=', acc)
      if opts.inside_paren_p then --print('rae continuing with acc=', acc);
        ignore_spaces() end
      if opts.stop then break end
    elseif c == Escape_char then get_char()
      --print('rae doing esc')
      toss_back_string(expand_escape(snoop_char()))
    elseif string.match(c, Unit_pattern) and not unit_already_read_p then
      --print('rae found unit', c)
      get_char(); ignore_spaces(); unit_already_read_p = true
      acc = acc * Gunit[c]
    else break
    end
  end
  --print('read_arith_expr retung', acc)
  return acc, unit_already_read_p
end

function author_info()
  --print('doing author_info')
  read_troff_line()
  --print('authorinfo calling eep')
  emit_end_para()
  emit_verbatim '<div align=center class=author>'
  --print('authorinfo calling par')
  emit_para()
  --dprint('calling unfill')
  unfill_mode()
  Afterpar = function()
    --print('doing authorinfo afterpar')
    emit_verbatim '</div>\n'
  end
end

function read_opt_sign()
  ignore_spaces()
  local c = snoop_char()
  if not c then return false
  elseif c == '+' or c == '-' then get_char(); return c
  else return false
  end
end

function read_escaped_word()
  local c = get_char()
  if c == '[' then return read_till_char(']', 'eat_delim')
  elseif c == '(' then local c1 = get_char(); local c2 = get_char()
    return c1..c2
  else return c
  end
end

function ignore_branch()
  ignore_spaces()
  local brace_p; local c
  while true do
    c = snoop_char()
    if not c then break
    elseif c=='\n' then --get_char();
      --if not fillp() then get_char() end
      break
    elseif c == Escape_char then get_char()
      c = snoop_char()
      if not c or c == '\n' then break
      elseif c == '{' then brace_p = true; get_char(); break
      else get_char()
      end
    else get_char()
    end
  end
  if brace_p then
    --print('brace_p set; esc=', Escape_char)
    local nesting=1
    while true do
      c = get_char()
      --print('igb read', c)
      if not c then terror 'ignore_branch: eof'
      elseif c == Escape_char then c = get_char()
        --print('igb read escaped', c)
        if not c then terror 'ignore_branch: escape eof'
        elseif c == '}' then nesting=nesting-1;
          if nesting==0 then break end
        elseif c == '{' then nesting=nesting+1
        end
      end
    end
  end
  read_troff_line()
end

function get_first_non_space_char_on_curr_line()
  ignore_spaces()
  local ln = read_troff_line()
  if ln == '' then return false else return string.sub(ln,1,1) end
end

function unicode_escape(s)
  if #s == 5 and string.sub(s,1,1) == 'u' then
    local s = string.sub(s,2,-1)
    local n = tonumber('0x' .. s)
    if not n then
      return '??'
    elseif n<128 then
      return string.char(n)
    elseif n==0x29f9 then
      return string.char(0xe2,0xa7,0xb9)
    end
  end
  return false
end

function read_macro_name()
  --print('doing read_macro_name')
  get_char()
  local res= expand_args(read_word())
  --print('read_macro_name -> ', res)
  return res
end

function read_args()
  --print('doing read_args, calling read_troff_line, then expand_args')
  local ln = expand_args(read_troff_line())
  local r = {}
  local c, w
  --print('line read=', ln)
  toss_back_line(ln)
  while true do
    ignore_spaces()
    c = snoop_char()
    if not c or c == '\n' then
      get_char()
      break
    end
    w = read_word()
    --print('read_args found word a', w, 'a')
    table.insert(r, w)
  end
  --print('read_args returning' , table_to_string(r))
  return table.unpack(r)
end
