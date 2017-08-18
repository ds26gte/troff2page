function point_equivalent_of(indicator)
  if indicator == 'c' then return point_equivalent_of('i')/2.54
  elseif indicator == 'i' then return 72
  elseif indicator == 'm' then return 10
  elseif indicator == 'v' then return 12
  elseif indicator == 'M' then return point_equivalent_of('m') * .01
  elseif indicator == 'n' then return point_equivalent_of('m') * .5
  elseif indicator == 'p' then return 1
  elseif indicator == 'P' then return 12
  else terror('point_equivalent_of: unknown indicator %s', indicator)
  end
end

function read_number_or_length(unit)
  ignore_spaces()
  local n = read_arith_expr()
  local u = snoop_char()
  if u == 'c' or u == 'i' or u == 'm' or u == 'n' or u == 'p' or u == 'P' or u == 'v' then
    get_char(); return math_round(n*point_equivalent_of(u))
  elseif u == 'f' then
    get_char(); return math_round((2^16)*n)
  elseif u == 'u' then
    get_char(); return n
  elseif unit then
    return n*point_equivalent_of(unit)
  else return n
  end
end

function read_length_in_pixels()
  ignore_spaces()
  local n = read_arith_expr()
  local u = snoop_char()
  local res
  if u == 'c' or u == 'i' or u == 'm' or u == 'n' or u == 'p' or u == 'P' then
    get_char(); res= math_round(n*point_equivalent_of(u))
  else
    res= math_round(4.5*n)
  end
  --print('read_length_in_pixels retng', res)
  return res
end 
