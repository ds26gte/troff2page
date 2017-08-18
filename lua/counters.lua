function left_zero_pad(n, reqd_length)
  local n = tostring(n)
  local length_so_far = #n
  if length_so_far >= reqd_length then return n
  else
    for i = 1, reqd_length - length_so_far do
      n = 0 .. n
    end
  end
end

function get_counter_named(name)
  local r = Numreg_table[name]
  if not r then
    r = { value = 0, format = '1' }
    Numreg_table[name] = r
  end
  return r
end

function increment_section_counter(lvl)
  if lvl then
    local h_lvl = 'H' .. lvl
    local c_lvl = get_counter_named(h_lvl)
    c_lvl.value = c_lvl.value + 1
    while true do
      lvl = lvl + 1
      c_lvl = Numreg_table['H' .. lvl]
      if not c_lvl then break end
      c_lvl.value = 0
    end
  end
end

function section_counter_value()
  local lvl = raw_counter_value('nh*hl')
  return lvl>0 and
  (function()
    local r = formatted_counter_value('H1')
    local i = 2
    while true do
      if i > lvl then break end
      r = r .. '.' .. formatted_counter_value('H' .. i)
      i = i + 1
    end
    return r
  end)()
end

function get_counter_value(c)
  local v, f, thk = c.value, c.format, c.thunk
  if thk then
    return tostring(thk()) -- but what if f = 's'
  elseif f == 's' then
    return v
  elseif f == 'A' then
    if v == 0 then return '0'
    else return string.char(v + string.byte('A') - 1)
    end
  elseif f == 'a' then
    if v == 0 then return '0'
    else return string.char(v + string.byte('a') - 1)
    end
  elseif f == 'I' then
    return number_to_roman(v)
  elseif f == 'i' then
    return number_to_roman(v, true)
  elseif tonumber(f) and #f > 1 then
    return left_zero_pad(v, #f)
  else
    return tostring(v)
  end
end

function raw_counter_value(str)
  return get_counter_named(str).value
end

function formatted_counter_value(str)
  return get_counter_value(get_counter_named(str))
end
