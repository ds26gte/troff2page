-- last modified 2021-06-18

if not table.unpack then
  table.unpack = unpack
end

function no_op()
  do end
end

function flet(opts, thunk) 
  --print('flet starts...')
  local alcove = {}
  for k,v in pairs(opts) do
    --print('flet setting', k)
    --if k == 'Exit_status' then print('saving Exit_status=', _G[k], 'setting=', v) end
    alcove[k], _G[k] = _G[k], v
  end
  local res = {thunk()}
  for k,v in pairs(opts) do
    --if k == 'Exit_status' then print('restoring Exit_status=', v) end
    _G[k] = alcove[k]
  end
  return table.unpack(res)
end

function with_input_from_string(s, fn)
  local f = os.tmpname()
  local o = io.open(f, 'w')
  o:write(s)
  o:close()
  local i = io.open(f)
  local res = fn(i)
  i:close()
  os.remove(f)
  return res
end

function with_output_to_string(fn)
  local f = os.tmpname()
  local o = io.open(f, 'w')
  fn(o)
  o:close()
  local i = io.open(f)
  local res = i:read('*a')
  i:close()
  os.remove(f)
  --print('wots retng', res)
  return res
end

function make_broadcast_stream(...)
  local oo = {...}
  local b = {}
  function b:write(...) 
    for _,o in pairs(oo) do
      o:write(...)
    end
  end
  function b:close()
    for _,o in pairs(oo) do
      o:close()
    end
  end
  return b
end

function make_string_output_stream()
  local f = os.tmpname()
  local o = io.open(f, 'w')
  local s = {}
  function s:write(...)
    o:write(...)
  end
  function s:get_output_stream_string()
    o:close()
    local i = io.open(f)
    local res = i:read('*a')
    i:close()
    os.remove(f)
    return res
  end
  return s
end

function probe_file(f)
  local h = io.open(f)
  if h then io.close(h); return f
  else return false
  end
end

function ensure_file_deleted(f)
  local h = io.open(f)
  if h then io.close(h); --os.remove(f); 
  end
end

function with_open_output_file(f, fn)
  ensure_file_deleted(f)
  local o = io.open(f, 'w')
  local res = fn(o)
  io.close(o)
  return res
end

function with_open_input_file(f, fn)
  local i = io.open(f, 'r')
  local res = fn(i)
  io.close(i)
  return res
end

function split_string(s, c)
  local r = {}
  if s then
    local start = 1
    local i
    while true do
      i = string.find(s, c, start, true)
      if not i then
        table.insert(r, string.sub(s, start, -1))
        break
      end
      table.insert(r, string.sub(s, start, i-1))
      start = i+1
    end
  end
  return r
end

function file_stem_name(f)
  local slash = string.find(f, '/[^/]*$')
  local dot = string.find(f, '%.[^.]*$')
  if slash and dot and dot > slash then 
    return string.sub(f, slash+1, dot-1)
  elseif slash then 
    return string.sub(f, slash+1)
  elseif dot then
    return string.sub(f, 1, dot-1)
  else return f
  end
end

function file_extension(f)
  local slash = string.find(f, '/[^/]*$')
  local dot = string.find(f, '%.[^.]*$')
  if dot and dot ~= 0 and 
    (not slash or ((slash+1) < dot)) then
    return string.sub(f, dot)
  else return ''
  end
end

function file_write_date(f)
  local s = io.popen('stat -c %Y '..f)
  local t = tonumber(s:read())
  s:close()
  return t
end

function some(f, tbl)
  for _,x in ipairs(tbl) do
    local try = f(x)
    if try then return try end
  end
  return false
end

function table_member(elt, tbl) 
  for _,val in pairs(tbl) do
    if elt == val then return true end
  end
  return false
end

function table_nconc(t, t_extra)
  for i=1,#t_extra do
    table.insert(t, t_extra[i])
  end
end

function string_to_table(s)
  local t = {}
  for i=1,#s do
    t[i] = string.sub(s, i, i)
  end
  return t
end

function table_to_string(t)
  local s = '{'
  for i=1,#t do
    if i ~= 1 then s = s .. ', ' end
    s = s .. t[i]
  end
  return s .. '}'
end

function gen_temp_string()
  Temp_string_count = Temp_string_count + 1
  return 'Temp_' .. Temp_string_count
end

function bool_to_num(b)
  return b and 1 or 0
end

function string_trim_blanks(s)
  return string.gsub(s, '^%s*(.-)%s*$', '%1')
end

function math_round(n)
  return math.floor(n+.5)
end

function copy_file_to_stream(fi, o)
  --print('doing copy_file_to_stream', fi, o)
  with_open_input_file(fi, function(i)
    local it
    while true do
      it = i:read '*line'
      --print('read <-', it)
      if not it then break end
      o:write(it, '\n')
    end
  end)
end

function copy_file_bytes_to_stream(fi, o)
  local blk_size = 256
  local blk
  with_open_input_file(fi, function(i)
    while true do
      blk = i:read(blk_size)
      if blk then
        o:write(blk)
      else
        break
      end
    end
  end)
end


function copy_file_to_file(fi, fo)
  --print('doing copy_file_to_file', fi, fo)
  with_open_output_file(fo, function(o)
    copy_file_to_stream(fi, o)
  end)
end
