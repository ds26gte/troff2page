-- last modified 2020-12-05

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
defunit('v', Gunit.p * 12)

Unit_pattern = '[cfiMmnPpuv]'

function point_equivalent_of(u)
  return Gunit[u]/Gunit.p
end

function read_number_or_length(unit)
  ignore_spaces()
  local n = read_arith_expr()
  local u = snoop_char()
  local res
  if u and string.match(u, Unit_pattern) then
    get_char(); res = math.floor(n*Gunit[u])
  elseif unit then
    if string.match(unit, Unit_pattern) then
      res = math.floor(n*Gunit[unit])
    else terror('Unknown length indicator %s', unit)
    end
  else
    res = n -- XXX should be floored, I think. Hope not relying on precise value in codebase
  end
  return res
end

function read_length_in_pixels(unit)
  ignore_spaces()
  local n = read_arith_expr()
  local u = snoop_char()
  local res
  if u and string.match(u, Unit_pattern) then
    get_char(); res = n*Gunit[u] / Gunit.p
  elseif unit then
    if string.match(unit, Unit_pattern) then
      res = n*Gunit[unit] / Gunit.p
    else terror('Unknown lenght indicator %s', unit)
    end
  else
    res = math_round(4.5*n) -- XXX
  end
  --print('read_length_in_pixels ->', res)
  return res
end 
