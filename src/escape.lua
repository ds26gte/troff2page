-- last modified 2020-11-30

Escape_table = {}

function defescape(c, th)
  Escape_table[c] = th
end

defescape('$', function()
  local x = read_escaped_word()
  local it
  if x == '*' then return all_args()
  elseif x == '@' then return all_args() --ok for now
  elseif x == '\\' then toss_back_char('\\')
    it = read_arith_expr()
    return Macro_args[it+1] or ''
  elseif (function() it = tonumber(x); return it end)()
  then return Macro_args[it+1] or ''
  else return ''
  end
end)

defescape('f', function()
  return switch_font(read_escaped_word())
end)

defescape('s', function()
  local sign = read_opt_sign() or ''
  local sz = sign .. read_escaped_word()
  return switch_size(sz)
end)

defescape('m', function()
  return switch_glyph_color(read_escaped_word())
end)

defescape('M', function()
  return switch_fill_color(read_escaped_word())
end)

defescape('*', function()
  --print('doing star')
  local s, args = read_troff_string_and_args()
  --print('s=', s, 'args=', table_to_string(args))
  local it
  it = String_table[s]
  if it then --print('s it', it);
    return it(table.unpack(args))
  end
  it = Macro_table[s]
  if it then
    execute_macro_body(it)
    return ''
  end
  it = Diversion_table[s]
  if it then
    return retrieve_diversion(it)
  end
  return ''
end)

defescape('c', function()
  Keep_newline_p = false
  return ''
end)

defescape('"', function()
  if Reading_quoted_phrase_p then return verbatim '"'
  else read_troff_line('stop_before_newline_p'); return ''
  end
end)

defescape('#', function()
  read_troff_line()
  Previous_line_exec_p = true
  Keep_newline_p = false
  return ''
end)

defescape('\\', function()
  if Macro_copy_mode_p then return '\\'
  else return verbatim '\\'
  end
end)

defescape('{', function()
  --dprint('doing \\{')
  table.insert(Cascaded_if_stack, 1, Cascaded_if_p)
  Cascaded_if_p = false
  Keep_newline_p=false
  return ''
end)

defescape('}', function()
  --dprint('doing \\}')
  read_troff_line()
  Cascaded_if_p = table.remove(Cascaded_if_stack, 1)
  return ''
end)

defescape('n', function()
  --print('doing \\n')
  local sign = read_opt_sign()
  local n = read_escaped_word()
  --print('numreg named', n)
  local c = get_counter_named(n)
  local it
  it = c.thunk
  if it then
    if sign then
      terror('\\n: cannot set readonly number register %s', n)
    end
    return tostring(it())
  else
    if sign == '+' then
      c.value = c.value + 1
    elseif sign == '-' then
      c.vlaue = c.value - 1
    end
    return get_counter_value(c)
  end
end)

defescape('B', function()
  local delim = get_char()
  if delim == "'" or delim == '"' then
    local arg = expand_args(read_till_char(read_till_char(delim, 'eat_delim')))
    local n = tonumber(arg)
    return (n and '1' or '0')
  else terror('\\B: bad delim %s', delim)
  end
end)

defescape('V', function()
  return os.getenv(read_escaped_word())
end)

defescape('(', function()
  local c1 = get_char(); local c2 = get_char()
  local s = c1..c2
  return Glyph_table[s] or ('\\(' .. s)
end)

defescape('[', function()
  local s = read_till_char(']', 'eat_delim')
  local s1
  local it = Glyph_table[s]
  if it then return it end
  if string.find(s, 'u') == 1 then
    s1 = string.sub(s, 2, -1)
    if tonumber('0x' .. s1) then
      return '\\[htmlamp]#x' .. s1 .. ';'
    end
  end
  if string.find(s, 'html') ~= 1 then
    twarning("warning: can't find special character '%s'", s)
  end
  return '\\[' .. s .. ']'
end)

defescape('h', function()
  local delim = get_char()
  read_opt_pipe()
  local x = read_length_in_pixels()
  local delim2 = get_char()
  if delim ~= delim2 then
    terror('\\h bad delims %s %s', delim, delim2)
  end
  return verbatim_nbsp(x / 5)
end)

defescape('l', function()
  local delim = get_char()
  read_opt_pipe()
  local x = read_length_in_pixels()
  local delim2 = get_char()
  if delim ~= delim2 then
    terror('\\l bad delims %s %s', delim, delim2)
  end
  return verbatim('<hr style="width: ' .. x .. 'px">')
end)

defescape('v', function()
  local delim = get_char()
  read_till_char(delim, 'eat_delim')
  return ''
end)

defescape('\n', function()
  --dprint('doing \\n')
  Keep_newline_p=false
  return ''
end)

defescape('&', function()
  return '\\[htmlempty]'
end)

defescape('%', Escape_table['&'])

defescape('p', Escape_table['&'])

defescape('e', function()
  return verbatim(Escape_char)
end)

defescape('E', Escape_table.e)
