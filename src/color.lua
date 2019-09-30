-- last modified 2017-08-17

function frac_to_rgb256(n)
  n = math_round(n*256)
  if n==256 then n=n-1 end
  return string.format('%2x', n)
end

function read_color_number(hashes)
  if hashes==1 then return string.format('%s%s', get_char(), get_char())
  elseif hashes==2 then return string.format('%s%s', get_char(),
    (function() get_char(); get_char(); return get_char() end)'')
  else ignore_spaces()
    local n = read_arith_expr(); local c = snoop_char()
    if c=='f' then get_char() end
    return frac_to_rgb256(n)
  end
end

function cmy_to_rgb(c,m,y)
  return {
    frac_to_rgb256(1-c),
    frac_to_rgb256(1-m),
    frac_to_rgb256(1-y)
  }
end

function cmyk_to_rgb(c,m,y,k)
  return cmy_to_rgb(
  c*(1-k) + k,
  m*(1-k) + k,
  y*(1-k) + k)
end

function read_rgb_color()
  local scheme = read_word()
  local number_hashes = 0
  local number_components = 0
  local components = {}
  if scheme=='rgb' or scheme=='cmy' then number_components=3
  elseif scheme=='cmyk' then number_components=4
  elseif scheme=='gray' then number_components=1
  elseif scheme=='grey' then scheme='gray'; number_components=1
  end
  ignore_spaces()
  if snoop_char() == '#' then get_char()
    number_hashes=number_hashes+1
    if snoop_char() == '#' then get_char()
      number_hashes=number_hashes+1
    end
  end
  table.insert(components, read_color_number(number_hashes))
  if number_components>=3 then
    table.insert(components, read_color_number(number_hashes))
    table.insert(components, read_color_number(number_hashes))
  end
  if number_components==4 then
    table.insert(components, read_color_number(number_hashes))
  end
  if scheme~='rgb' then
    for i=1,#components do
      local n=components[i]
      components[i] = tonumber('0x'..n)/256
    end
  end
  if scheme=='cmyk' then components = cmyk_to_rgb(table.unpack(components))
  elseif scheme=='cmy' then components = cmy_to_rgb(table.unpack(components))
  elseif scheme=='gray' then components = cmyk_to_rgb(0,0,0, components[1])
  end
  return '#'..table.concat(components)
end
