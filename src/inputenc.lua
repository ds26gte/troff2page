-- last modified 2020-12-07

B_1000_0000 = 0x80
B_1100_0000 = 0xc0
B_1110_0000 = 0xe0
B_1111_0000 = 0xf0
B_1111_1000 = 0xf8
B_0001_1111 = 0x1f
B_0000_1111 = 0x0f
B_0000_0111 = 0x07
B_0011_1111 = 0x3f

function get_char()
  local buf = Current_troff_input.buffer
  if #buf > 0 then
    return table.remove(buf, 1)
  end
  local strm = Current_troff_input.stream
  if not strm then return false end
  local c = strm:read(1)
  if not c then return false end
  if c == '\r' then
    -- if \r return \n. If a real \n follows, discard it
    c = '\n'
    local c2 = strm:read(1)
    if c2 and c2 ~= '\n' then
      table.insert(buf, 1, c2)
    end
    return c
  end
  --
  --
  local c1byte = string.byte(c)
  if c1byte < B_1000_0000 then
    -- c1byte = 0xxx_xxxx
    return c
  end
  --
  local ucode
  if c1byte < B_1110_0000 then
    -- c1byte = 110x_xxxx
    local c2byte = string.byte(strm:read(1))
    --print('c1=', c1byte, 'c2=', c2byte)
    ucode = ((c1byte & B_0001_1111) << 6) +
    (         c2byte & B_0011_1111)
    --
  elseif c1byte < B_1111_0000 then
    --     c1byte = 1110_xxxx
    local c2byte = string.byte(strm:read(1))
    local c3byte = string.byte(strm:read(1))
    --print('c1=', c1byte, 'c2=', c2byte, 'c3=', c3byte)
    ucode = ((c1byte & B_0000_1111) << 12) +
    (        (c2byte & B_0011_1111) <<  6) +
    (         c3byte & B_0011_1111)
    --
  elseif c1byte < B_1111_1000 then
    --     c1byte = 1111_0xxx
    local c2byte = string.byte(strm:read(1))
    local c3byte = string.byte(strm:read(1))
    local c4byte = string.byte(strm:read(1))
    --print('c1=', c1byte, 'c2=', c2byte, 'c3=', c3byte, 'c4=', c4byte)
    ucode = ((c1byte & B_0000_0111) << 18) +
    (        (c2byte & B_0011_1111) << 12) +
    (        (c3byte & B_0011_1111) <<  6) +
    (         c4byte & B_0011_1111)
    --
  else
    terror 'get_char'
    return false
  end
  --
  --print(string.format('get_char returned unicode %X\n', ucode))
  toss_back_string(string.format('[u%X]', ucode))
  return Escape_char
end
