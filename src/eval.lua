-- last modified 2020-12-03

function eval_in_lua(tbl)
  --print('doing eval_in_lua', table_to_string(tbl))
  local tmpf = os.tmpname()
  local o = io.open(tmpf, 'w')
  for i=1,#tbl do
    o:write(tbl[i], '\n')
  end
  o:close()
  dofile(tmpf)
  os.remove(tmpf)
end
