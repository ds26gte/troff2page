-- last modified 2020-12-15

function collect_macro_body(w, ender)
  --print('doing collect_macro_body', w, ender)
  --print('Turn_off_escape_char_p =', Turn_off_escape_char_p)
  if not ender then ender = '.' end
  local m = {}
  while true do
    if not snoop_char() then
      Exit_status = 'done'
      Macro_spill_over = Control_char .. 'am ' .. w .. ' ' .. ender
      break
    end
    local ln = expand_args(read_troff_line())
    local breakloop
    --print('inside collect_macro_body with', ln)
    flet({
      Current_troff_input = make_bstream {}
    }, function()
      toss_back_line(ln)
      local c = snoop_char()
      if c == Control_char then
        get_char()
        ignore_spaces()
        local w = read_bare_word()
        --print('checking ->', w, '<-')
        if w == ender then breakloop=true; return end
      end
      table.insert(m, ln)
    end)
    if breakloop then break end
  end
  --print('collect_macro_body returning', table_to_string(m))
  return m
end

function expand_args(s, not_copy_mode_p)
  --print('doing expand_args', s)
  if not s then return '' end
  local res = with_output_to_string(function (o)
    flet({
      Current_troff_input = make_bstream{buffer = string_to_table(s)},
      Macro_copy_mode_p = not not_copy_mode_p,
      Expanding_args_p = true,
      Outputting_to = 'troff',
      Out = o
    }, function()
      --print('calling generate_html from expand_args')
      --print('cti.b =', #(Current_troff_input.buffer))
      generate_html{'break', 'continue', 'ex', 'nx', 'return'}
    end)
  end)
  --print('expand_args retng', res)
  return res
end

function execute_macro(w, noarg)
  --print('doing execute_macro', w)
  local it
  if not w then
    return
  end
  --
  it = Diversion_table[w]
  if it then
    --print('execing divn')
    if not noarg then read_troff_line() end
    local divvalue = retrieve_diversion(it)
    --print('divvalue =', divvalue)
    emit_verbatim(divvalue)
    return
  end
  --
  it = Macro_table[w]
  if it then
    local args = noarg and {} or {read_args()}
    flet({
      Macro_args = args
    }, function()
      table.insert(Macro_args, 1, w)
      execute_macro_body(it)
    end)
    return
  end
  --
  it = String_table[w]
  if it then
    if not noarg then read_troff_line() end
    emit_verbatim(it())
    return
  end
  --
  it = Request_table[w]
  if it then
    --print('calling request', w)
    it()
    return
  end
  --
  if not noarg then read_troff_line() end
end

function execute_macro_body(ss)
  --print('doing execute_macro_body', table_to_string(ss))
  flet({
    Macro_spill_over = false
  }, function()
    flet({
      Current_troff_input = make_bstream {}
    }, function()
      local i = #ss
      while true do
        if i<1 then break end
        toss_back_line(ss[i])
        i = i-1
      end
      --print('calling generate_html from execute_macro_body with Out=', Out)
      generate_html {'nx', 'ex'}
    end)
    if Macro_spill_over then
      toss_back_line(Macro_spill_over)
    end
  end)
end

function execute_macro_with_args(w, args)
  local it
  it = Macro_table[w]
  if not t then return end
  flet({Macro_args = args}, function()
    table.insert(Macro_args, 1, w)
    execute_macro_body(it)
  end)
  return
end

function retrieve_diversion(div)
  local value = div.value
  if not value then
    value = (div.stream):get_output_stream_string()
    div.value = value
  end
  return value
end
