-- last modified 2017-08-15

function eval_in_lua(tbl)
--  print('doing eval_in_lua')
  local tmpf = os.tmpname()
  local o = io.open(tmpf, 'w')
  for i=1,#tbl do
    o:write(tbl[i], '\n')
  end
  o:close()
  dofile(tmpf)
  --os.remove(tmpf)
end
