-- last modified 2021-02-09

Gunit = {}

function defunit(w, num)
  Gunit[w] = num
end

defunit('u', 1)
defunit('i', 72000)
defunit('f', 2^16)

defunit('p', Gunit.i / 72)

defunit('m', Gunit.p * 10)

defunit('M', Gunit.m * .01)
defunit('P', Gunit.p * 12)
defunit('c', Gunit.i / 2.54)
defunit('n', Gunit.m / 2)
defunit('v', Gunit.p * 16)

defunit('px', Gunit.i / 96)

Unit_pattern = '[cfiMmnPpuv]'

function point_equivalent_of(u)
  return Gunit[u]/Gunit.p
end

function read_length_in_pixels(unit)
  ignore_spaces()
  local n, unit_already_read_p = read_arith_expr()
  --print('\tread_arith_expr retd', n, unit_already_read_p)
  if unit_already_read_p then
    return n / Gunit.px
  end
  --
  if unit then
    if string.match(unit, Unit_pattern) then
      return n*Gunit[unit] / Gunit.px
    end
    terror('Unknown length indicator %s', unit)
  end
  --
  --XXX: deadc0de?
  local u = snoop_char()
  if u and string.match(u, Unit_pattern) then get_char()
    return n*Gunit[u] / Gunit.px
  end
  --
  return  math_round(4.5*n) -- XXX
end 
