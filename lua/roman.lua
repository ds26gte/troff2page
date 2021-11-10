-- last modified 2020-12-07

do 
  local roman_quanta = { 10000, 5000, 1000, 500, 100, 50, 10, 5, 1 }

  local roman_digits = {
    [10000] = { 'z', 1000 },
    [5000] = { 'w', 1000 },
    [1000] = { 'm', 100 },
    [500] = { 'd', 100 },
    [100] = { 'c', 10 },
    [50] = { 'l', 10 },
    [10] = { 'x', 1 },
    [5] = { 'v', 1 },
    [1] = { 'i', 0 }
  }

  function toroman(n, downcasep)
    if not (type(n) == 'number' and math.floor(n) == n and n >= 0) then
      terror 'toroman: Missing number'
    end

    local function approp_case(c) 
      if downcasep then return c
      else return string.upper(c)
      end
    end

    local n, i, s = n, 1, ''
    while true do
      if i > #roman_quanta then
        if s == '' then s = '0' end
        break
      end
      local val = roman_quanta[i]
      local d = roman_digits[val]
      local c, nextval = approp_case(d[1]), d[2]
      local q, r = math.floor(n / val), n % val
      while true do
        if q == 0 then
          if r >= (val - nextval) then 
            n = r % nextval
            s = s .. approp_case(roman_digits[nextval][1]) .. c
          else
            n = r
          end
          i = i+1; break
        else
          q = q-1; s = s .. c
        end
      end
    end
    return s
  end
end
